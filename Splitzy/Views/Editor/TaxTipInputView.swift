//
//  TaxTipInputView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI
import SwiftData

struct TaxTipInputView: View {
    @Bindable var bill: Bill
    @Environment(\.dismiss) var dismiss
    
    @State private var taxString: String = ""
    @State private var tipString: String = ""
    
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
                    Text("Tax & Tip")
                        .font(.headline)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tax Card
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Tax", systemImage: "building.columns.fill")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("$")
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", text: $taxString)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(Color.Splitzy.background)
                            .cornerRadius(15)
                        }
                        .padding()
                        .background(Color.Splitzy.surface)
                        .cornerRadius(20)
                        
                        // Tip Card
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Tip", systemImage: "heart.fill")
                                .font(.headline)
                                .foregroundColor(.pink)
                            
                            HStack {
                                Text("$")
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", text: $tipString)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(Color.Splitzy.background)
                            .cornerRadius(15)
                            
                            // Quick Percentages (Future feature, placeholder visual)
                             HStack {
                                 Text("Common tips: 15%, 18%, 20%")
                                     .font(.caption)
                                     .foregroundColor(.secondary)
                             }
                        }
                        .padding()
                        .background(Color.Splitzy.surface)
                        .cornerRadius(20)
                        
                        // Summary Card
                        VStack(spacing: 16) {
                            Text("Summary")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            VStack(spacing: 8) {
                                let subtotal = bill.items.reduce(0) { $0 + ($1.unitPriceCents * $1.quantity) }
                                SummaryRow(title: "Subtotal", amount: subtotal)
                                SummaryRow(title: "Tax", amount: bill.taxCents)
                                SummaryRow(title: "Tip", amount: bill.tipCents)
                                Divider()
                                SummaryRow(title: "Total", amount: subtotal + bill.taxCents + bill.tipCents, isTotal: true)
                            }
                        }
                        .padding()
                        .glassCard() // Using our custom modifier
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if bill.taxCents > 0 {
                taxString = String(format: "%.2f", Double(bill.taxCents) / 100.0)
            }
            if bill.tipCents > 0 {
                tipString = String(format: "%.2f", Double(bill.tipCents) / 100.0)
            }
        }
        .onChange(of: taxString) { _, newValue in
            let doubleVal = Double(newValue) ?? 0.0
            bill.taxCents = Int(round(doubleVal * 100))
        }
        .onChange(of: tipString) { _, newValue in
            let doubleVal = Double(newValue) ?? 0.0
            bill.tipCents = Int(round(doubleVal * 100))
        }
        .onTapGesture {
            // Dismiss keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct SummaryRow: View {
    let title: String
    let amount: Int
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline : .body)
                .foregroundColor(isTotal ? .primary : .secondary)
            Spacer()
            Text(Double(amount) / 100.0, format: .currency(code: "USD"))
                .font(isTotal ? .headline : .body)
                .fontWeight(isTotal ? .bold : .regular)
                .foregroundColor(isTotal ? .primary : .secondary)
        }
    }
}
