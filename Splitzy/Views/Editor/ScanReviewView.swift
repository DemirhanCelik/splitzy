//
//  ScanReviewView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 01/28/26.
//

import SwiftUI

/// Review screen for scanned receipt items - allows editing before adding to bill
struct ScanReviewView: View {
    @Environment(\.dismiss) var dismiss
    
    let onConfirm: ([ParsedReceiptItem], Int, Int) -> Void
    
    @State private var items: [ParsedReceiptItem]
    @State private var taxCents: Int
    @State private var tipCents: Int
    @State private var editingItemId: UUID?
    
    init(receipt: ParsedReceipt, onConfirm: @escaping ([ParsedReceiptItem], Int, Int) -> Void) {
        self._items = State(initialValue: receipt.items)
        self._taxCents = State(initialValue: Int((receipt.tax ?? 0) * 100))
        self._tipCents = State(initialValue: Int((receipt.tip ?? 0) * 100))
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Splitzy.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header info
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(items.count) items found")
                                .font(.headline)
                            Text("Tap to edit, swipe to delete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // Total preview
                        VStack(alignment: .trailing) {
                            Text("Subtotal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatMoney(itemsTotal))
                                .font(.headline)
                        }
                    }
                    .padding()
                    .background(Color.Splitzy.surface)
                    
                    // Items list
                    List {
                        ForEach($items) { $item in
                            ScanReviewItemRow(item: $item)
                        }
                        .onDelete(perform: deleteItems)
                        
                        // Tax & Tip Section
                        Section("Tax & Tip") {
                            HStack {
                                Label("Tax", systemImage: "building.columns")
                                Spacer()
                                TextField("$0.00", value: Binding(
                                    get: { Double(taxCents) / 100 },
                                    set: { taxCents = Int($0 * 100) }
                                ), format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Label("Tip", systemImage: "heart.fill")
                                    .foregroundColor(.pink)
                                Spacer()
                                TextField("$0.00", value: Binding(
                                    get: { Double(tipCents) / 100 },
                                    set: { tipCents = Int($0 * 100) }
                                ), format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        // Add item manually
                        Section {
                            Button(action: addNewItem) {
                                Label("Add Item Manually", systemImage: "plus.circle.fill")
                                    .foregroundColor(Color.Splitzy.electricTeal)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    
                    // Confirm button
                    Button(action: confirmItems) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Add \(items.count) Items to Bill")
                        }
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.vibrantMain)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .padding()
                }
            }
            .navigationTitle("Review Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var itemsTotal: Int {
        items.reduce(0) { $0 + Int($1.price * 100) }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    private func addNewItem() {
        let newItem = ParsedReceiptItem(name: "New Item", price: 0)
        items.append(newItem)
    }
    
    private func confirmItems() {
        onConfirm(items, taxCents, tipCents)
        dismiss()
    }
    
    private func formatMoney(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(.currency(code: "USD"))
    }
}

// MARK: - Item Row

struct ScanReviewItemRow: View {
    @Binding var item: ParsedReceiptItem
    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editPrice: String = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.body)
                Text("Tap to edit")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(item.price.formatted(.currency(code: "USD")))
                .font(.body.monospacedDigit())
                .foregroundColor(.primary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editName = item.name
            editPrice = String(format: "%.2f", item.price)
            isEditing = true
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                Form {
                    TextField("Item Name", text: $editName)
                    HStack {
                        Text("$")
                        TextField("Price", text: $editPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                .navigationTitle("Edit Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isEditing = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            item.name = editName
                            item.price = Double(editPrice) ?? item.price
                            isEditing = false
                        }
                        .bold()
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
