//
//  ReceiptScannerService.swift
//  Splitzy
//
//  Created by Demirhan Celik on 01/28/26.
//

import Foundation
import UIKit
import Vision
import Combine

/// Parsed item from receipt
struct ParsedReceiptItem: Codable, Identifiable {
    var id = UUID()
    var name: String
    var price: Double
    
    enum CodingKeys: String, CodingKey {
        case name, price
    }
}

/// Full parsed receipt
struct ParsedReceipt: Codable, Identifiable {
    var id = UUID()
    var items: [ParsedReceiptItem]
    var tax: Double?
    var tip: Double?
    var total: Double?
    
    enum CodingKeys: String, CodingKey {
        case items, tax, tip, total
    }
}

/// Service for scanning receipts using local OCR + Gemini AI
@MainActor
class ReceiptScannerService: ObservableObject {
    static let shared = ReceiptScannerService()
    
    /// API key loaded from Secrets.plist
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String,
              key != "YOUR_API_KEY_HERE" else {
            return ""
        }
        return key
    }
    
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var rawOCRText: String = ""
    
    private init() {}
    
    // MARK: - Step 1: Local OCR with Vision
    
    /// Extract text from image using on-device Vision OCR (fast, free, private)
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ScanError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Combine all recognized text
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Step 2: Gemini Parses Text
    
    /// Send OCR text to Gemini to extract structured data
    func parseReceiptText(_ text: String) async throws -> ParsedReceipt {
        // Check API key
        if apiKey.isEmpty {
            #if DEBUG
            print("⚠️ Secrets.plist not found or API key not set!")
            #endif
            throw ScanError.apiError("API key not configured. Please add your Gemini API key to Secrets.plist")
        }
        
        #if DEBUG
        print("✅ API key found, making request...")
        #endif
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let prompt = """
        Parse this receipt text and extract the items. Return ONLY valid JSON:
        
        {
          "items": [{"name": "Item Name", "price": 12.99}],
          "tax": 2.50,
          "tip": null,
          "total": 45.99
        }
        
        Rules:
        - Include ONLY food/product items in the items array
        - Do NOT include tax, tip, subtotal, or total as items
        - Extract tax, tip, and total as separate fields (null if not found)
        - Clean up item names (remove quantities like "1x" or "2 @")
        - Prices should be numbers, not strings
        
        Receipt text:
        \(text)
        """
        
        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.1, "maxOutputTokens": 2048]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ScanError.networkError
            }
            
            if httpResponse.statusCode != 200 {
                // Try to get error message from API
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    #if DEBUG
                    print("❌ Gemini API error: \(message)")
                    #endif
                    throw ScanError.apiError("Gemini: \(message)")
                }
                throw ScanError.apiError("API returned status \(httpResponse.statusCode)")
            }
            
            // Parse Gemini response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let responseText = firstPart["text"] as? String else {
                throw ScanError.parseError
            }
            
            // Clean JSON from markdown
            let cleanedText = responseText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let jsonData = cleanedText.data(using: .utf8) else {
                throw ScanError.parseError
            }
            
            let decoder = JSONDecoder()
            let receipt = try decoder.decode(ParsedReceipt.self, from: jsonData)
            return receipt
            
        } catch let error as ScanError {
            throw error
        } catch {
            #if DEBUG
            print("❌ Network error: \(error.localizedDescription)")
            #endif
            throw ScanError.networkError
        }
    }
    
    // MARK: - Full Pipeline
    
    /// Complete scan: OCR → Gemini Parse → Return structured data
    func scanReceipt(image: UIImage) async throws -> ParsedReceipt {
        isScanning = true
        errorMessage = nil
        
        defer { isScanning = false }
        
        // Step 1: Local OCR
        let ocrText = try await extractText(from: image)
        rawOCRText = ocrText
        
        guard !ocrText.isEmpty else {
            throw ScanError.parseError
        }
        
        // Step 2: Gemini parsing
        let receipt = try await parseReceiptText(ocrText)
        return receipt
    }
}

enum ScanError: LocalizedError {
    case invalidImage
    case networkError
    case apiError(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process image"
        case .networkError: return "Network error occurred"
        case .apiError(let msg): return msg
        case .parseError: return "Could not read receipt items"
        }
    }
}
