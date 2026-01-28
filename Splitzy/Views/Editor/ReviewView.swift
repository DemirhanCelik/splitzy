//
//  ReviewView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI
import SwiftData

struct ReviewView: View {
    @Bindable var bill: Bill
    @Environment(\.dismiss) var dismiss
    
    @State private var calculationResult: BillCalculationResult?
    @State private var taxString: String = ""
    @State private var tipString: String = ""
    @FocusState private var focusedField: Field?
    
    // Share state
    @State private var isSharing = false
    @State private var shareItems: [Any] = []
    
    enum Field {
        case tax, tip
    }
    
    var body: some View {
        ZStack {
            Color.Splitzy.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.Splitzy.surface)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Review & Finalize")
                        .font(.headline)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Tax & Tip Inputs
                        HStack(spacing: 15) {
                            // Tax Input
                            VStack(alignment: .leading) {
                                Label("Tax", systemImage: "building.columns.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text("$").foregroundColor(.secondary)
                                    TextField("0.00", text: $taxString)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .tax)
                                }
                                .font(.headline)
                            }
                            .padding()
                            .background(Color.Splitzy.surface)
                            .cornerRadius(15)
                            
                            // Tip Input
                            VStack(alignment: .leading) {
                                Label("Tip", systemImage: "heart.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.pink)
                                HStack {
                                    Text("$").foregroundColor(.secondary)
                                    TextField("0.00", text: $tipString)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .tip)
                                }
                                .font(.headline)
                            }
                            .padding()
                            .background(Color.Splitzy.surface)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Total Display
                        if let result = calculationResult {
                            VStack(spacing: 8) {
                                Text("Grand Total")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(formatMoney(result.grandTotalCents))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .padding(.top, 10)
                            
                            // MARK: - Receipt Card
                            VStack(spacing: 0) {
                                // Receipt Header
                                HStack {
                                    Text("Breakdown")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "receipt.fill")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding()
                                .background(LinearGradient.vibrantMain)
                                
                                // Items
                                VStack(spacing: 0) {
                                    ForEach(Array(result.participantResults.enumerated()), id: \.element.participantId) { index, pResult in
                                        let name = bill.participants.first(where: { $0.id == pResult.participantId })?.displayName ?? "Unknown"
                                        
                                        VStack(spacing: 12) {
                                            HStack {
                                                HStack {
                                                    Text(String(name.prefix(1)).uppercased())
                                                        .font(.caption.bold())
                                                        .foregroundColor(.white)
                                                        .frame(width: 24, height: 24)
                                                        .background(Color.Splitzy.electricTeal)
                                                        .clipShape(Circle())
                                                    Text(name)
                                                        .font(.headline)
                                                }
                                                Spacer()
                                                Text(formatMoney(pResult.totalCents))
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            HStack {
                                                Text("Order: \(formatMoney(pResult.subtotalCents))")
                                                Spacer()
                                                Text("Tax: \(formatMoney(pResult.taxShareCents))")
                                                Text("Tip: \(formatMoney(pResult.tipShareCents))")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        
                                        if index < result.participantResults.count - 1 {
                                            Divider()
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                                .background(Color.Splitzy.surface)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                        } else {
                            ProgressView()
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Share floating button
            VStack {
                Spacer()
                Button(action: shareBill) {
                    if isSharing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(LinearGradient.vibrantMain)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    } else {
                        Label("Share Receipt", systemImage: "square.and.arrow.up")
                            .primaryButtonStyle()
                    }
                }
                .disabled(isSharing)
                .padding()
            }
        }
        .sheet(isPresented: Binding(
            get: { !shareItems.isEmpty },
            set: { if !$0 { shareItems = [] } }
        )) {
            ShareSheet(items: shareItems)
        }
        .navigationBarHidden(true)
        .onAppear {
            if bill.taxCents > 0 { taxString = String(format: "%.2f", Double(bill.taxCents) / 100.0) }
            if bill.tipCents > 0 { tipString = String(format: "%.2f", Double(bill.tipCents) / 100.0) }
            recalculate()
        }
        .onChange(of: taxString) { _, newValue in
            let doubleVal = Double(newValue) ?? 0.0
            bill.taxCents = Int(round(doubleVal * 100))
            recalculate()
        }
        .onChange(of: tipString) { _, newValue in
            let doubleVal = Double(newValue) ?? 0.0
            bill.tipCents = Int(round(doubleVal * 100))
            recalculate()
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func recalculate() {
        withAnimation {
            calculationResult = bill.calculateSplit()
        }
    }
    
    private func shareBill() {
        isSharing = true
        
        // Generate shareable text using ShareService
        let shareText = ShareService.shared.generateLocalShareText(for: bill)
        
        // Try to generate an image of the receipt
        let renderer = ImageRenderer(content: ShareableReceiptView(bill: bill, result: calculationResult))
        renderer.scale = 3.0 // High quality
        
        if let image = renderer.uiImage {
            shareItems = [shareText, image]
        } else {
            shareItems = [shareText]
        }
        
        isSharing = false
    }
    
    func formatMoney(_ cents: Int) -> String {
        let amount = Double(cents) / 100.0
        return amount.formatted(.currency(code: bill.currency))
    }
}

// MARK: - Shareable Receipt Image View
struct ShareableReceiptView: View {
    let bill: Bill
    let result: BillCalculationResult?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("🧾 " + (bill.title.isEmpty ? "Bill Split" : bill.title))
                .font(.title.bold())
                .foregroundColor(.black)
            
            Divider()
            
            // Breakdown
            if let result = result {
                ForEach(result.participantResults, id: \.participantId) { pResult in
                    if let participant = bill.participants.first(where: { $0.id == pResult.participantId }) {
                        HStack {
                            Text(participant.displayName)
                                .font(.headline)
                            Spacer()
                            Text((Double(pResult.totalCents) / 100).formatted(.currency(code: bill.currency)))
                                .font(.headline.monospacedDigit())
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.title2.bold())
                    Spacer()
                    Text((Double(result.grandTotalCents) / 100).formatted(.currency(code: bill.currency)))
                        .font(.title2.bold())
                }
            }
            
            Text("Split with Splitzy")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(30)
        .frame(width: 350)
        .background(Color.white)
        .cornerRadius(20)
    }
}

// MARK: - Share Sheet (UIKit Wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
