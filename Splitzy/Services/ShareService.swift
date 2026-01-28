//
//  ShareService.swift
//  Splitzy
//
//  Created by Demirhan Celik on 01/28/26.
//

import Foundation
import Combine
import FirebaseFunctions

/// Service for creating and managing shareable bill links
@MainActor
class ShareService: ObservableObject {
    static let shared = ShareService()
    
    private let functions = Functions.functions()
    
    @Published var isLoading = false
    @Published var lastShareLink: String?
    @Published var errorMessage: String?
    
    private init() {}
    
    /// Creates a shareable link for a bill by calling the Cloud Function
    func createShareLink(for bill: Bill) async throws -> String {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Build bill data for the Cloud Function
        let billData: [String: Any] = [
            "title": bill.title.isEmpty ? "Untitled Bill" : bill.title,
            "currency": bill.currency,
            "taxCents": bill.taxCents,
            "tipCents": bill.tipCents,
            "items": bill.items.map { item -> [String: Any] in
                [
                    "name": item.name,
                    "unitPriceCents": item.unitPriceCents,
                    "quantity": item.quantity,
                    "assignedTo": item.allocations.compactMap { $0.participant?.displayName }
                ]
            },
            "participants": bill.participants.map { participant -> [String: Any] in
                ["name": participant.displayName]
            }
        ]
        
        do {
            let result = try await functions.httpsCallable("createShareLink").call(billData)
            
            if let data = result.data as? [String: Any],
               let link = data["link"] as? String {
                lastShareLink = link
                return link
            } else {
                throw ShareError.invalidResponse
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Generates a local shareable text summary (fallback if Cloud Functions not deployed)
    func generateLocalShareText(for bill: Bill) -> String {
        let result = bill.calculateSplit()
        
        var text = "💰 \(bill.title.isEmpty ? "Bill Split" : bill.title)\n\n"
        
        for pResult in result.participantResults {
            if let participant = bill.participants.first(where: { $0.id == pResult.participantId }) {
                let amount = Double(pResult.totalCents) / 100.0
                text += "• \(participant.displayName): \(amount.formatted(.currency(code: bill.currency)))\n"
            }
        }
        
        let total = Double(result.grandTotalCents) / 100.0
        text += "\n📊 Total: \(total.formatted(.currency(code: bill.currency)))"
        text += "\n\nSplit with Splitzy 🧾"
        
        return text
    }
}

enum ShareError: LocalizedError {
    case invalidResponse
    case functionNotDeployed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .functionNotDeployed:
            return "Share function not deployed. Using local sharing."
        }
    }
}
