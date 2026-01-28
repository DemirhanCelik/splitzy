//
//  ItemsInputView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI
import SwiftData

struct ItemsInputView: View {
    @Bindable var bill: Bill
    @Environment(\.dismiss) var dismiss
    
    @State private var isAddingItem = false
    @State private var editingItem: Item?
    
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
                    Text("Items")
                        .font(.headline)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if bill.participants.isEmpty {
                            Text("⚠️ Add participants first!")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                                .padding()
                        }
                        
                        ForEach(bill.items) { item in
                            ItemRowCard(item: item, participants: bill.participants)
                                .onTapGesture {
                                    editingItem = item
                                }
                        }
                        
                        if bill.items.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "cart.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text("Add items from the receipt")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { isAddingItem = true }) {
                        Image(systemName: "plus")
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(LinearGradient.vibrantMain)
                            .clipShape(Circle())
                            .shadow(color: Color.Splitzy.vibrantPurple.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isAddingItem) {
            ItemEditView(item: nil, participants: bill.participants) { newItem in
                bill.items.append(newItem)
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditView(item: item, participants: bill.participants) { _ in
                // Edited in place, SwiftData handles update
            }
        }
    }
}

// MARK: - Subviews

struct ItemRowCard: View {
    let item: Item
    let participants: [Participant]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(item.quantity)x \(formatMoney(item.unitPriceCents))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Assignments
            HStack(spacing: -8) {
                if item.allocations.isEmpty {
                    Image(systemName: "person.slash")
                        .foregroundColor(.red)
                } else {
                    ForEach(item.allocations.prefix(4)) { alloc in
                        if let name = alloc.participant?.displayName {
                            Text(String(name.prefix(1)).uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.Splitzy.electricTeal)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.Splitzy.surface, lineWidth: 2))
                        }
                    }
                    if item.allocations.count > 4 {
                        Text("+\(item.allocations.count - 4)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 10)
                    }
                }
            }
            .padding(.trailing, 8)
            
            Text(formatMoney(item.unitPriceCents * item.quantity))
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.Splitzy.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func formatMoney(_ cents: Int) -> String {
        let amount = Double(cents) / 100.0
        return amount.formatted(.currency(code: "USD")) // Should use bill currency
    }
}

// MARK: - Edit View

struct ItemEditView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var item: Item?
    var participants: [Participant]
    var onSave: ((Item) -> Void)? = nil
    
    @State private var name: String = ""
    @State private var priceString: String = ""
    @State private var quantity: Int = 1
    @State private var selectedParticipantIds: Set<UUID> = []
    
    var isNew: Bool { item == nil }
    
    var body: some View {
        ZStack {
            Color.Splitzy.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Handle
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                // Title
                Text(isNew ? "New Item" : "Edit Item")
                    .font(.title3.bold())
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Inputs
                        VStack(spacing: 15) {
                            TextField("Item Name (e.g. Pizza)", text: $name)
                                .font(.title2.bold())
                                .padding()
                                .background(Color.Splitzy.surface)
                                .cornerRadius(15)
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Text("$")
                                    .font(.title2.bold())
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", text: $priceString)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(Color.Splitzy.surface)
                            .cornerRadius(15)
                            
                            HStack {
                                Text("Quantity")
                                    .font(.headline)
                                Spacer()
                                Stepper("", value: $quantity, in: 1...100)
                                    .labelsHidden()
                                Text("\(quantity)")
                                    .font(.title3.bold())
                                    .frame(width: 40)
                            }
                            .padding()
                            .background(Color.Splitzy.surface)
                            .cornerRadius(15)
                        }
                        
                        // Assignment
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Split with")
                                    .font(.headline)
                                Spacer()
                                Button(selectedParticipantIds.isEmpty ? "All" : "Clear") {
                                    if selectedParticipantIds.isEmpty {
                                        selectedParticipantIds = Set(participants.map(\.id))
                                    } else {
                                        selectedParticipantIds.removeAll()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                                ForEach(participants) { participant in
                                    ParticipantSelectBubble(
                                        name: participant.displayName,
                                        isSelected: selectedParticipantIds.contains(participant.id)
                                    )
                                    .onTapGesture {
                                        if selectedParticipantIds.contains(participant.id) {
                                            selectedParticipantIds.remove(participant.id)
                                        } else {
                                            selectedParticipantIds.insert(participant.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.Splitzy.surface)
                        .cornerRadius(15)
                    }
                    .padding()
                }
                
                // Save Button
                Button(action: save) {
                    Text("Save Item")
                        .primaryButtonStyle()
                }
                .padding()
                .disabled(name.isEmpty || priceString.isEmpty)
                .opacity((name.isEmpty || priceString.isEmpty) ? 0.6 : 1)
            }
        }
        .onAppear {
            if let item = item {
                name = item.name
                priceString = String(format: "%.2f", Double(item.unitPriceCents) / 100.0)
                quantity = item.quantity
                selectedParticipantIds = Set(item.allocations.compactMap(\.participant?.id))
            } else {
                selectedParticipantIds = Set(participants.map(\.id))
            }
        }
    }
    
    private func save() {
        let priceDouble = Double(priceString) ?? 0.0
        let priceCents = Int(round(priceDouble * 100))
        
        if let existingItem = item {
            existingItem.name = name
            existingItem.unitPriceCents = priceCents
            existingItem.quantity = quantity
            
            // Sync Allocations
            // Remove
            let toRemove = existingItem.allocations.filter { allocation in
                guard let pid = allocation.participant?.id else { return true }
                return !selectedParticipantIds.contains(pid)
            }
            toRemove.forEach {
                if let idx = existingItem.allocations.firstIndex(of: $0) {
                    existingItem.allocations.remove(at: idx)
                }
            }
            
            // Add
            for pid in selectedParticipantIds {
                if !existingItem.allocations.contains(where: { $0.participant?.id == pid }) {
                    if let p = participants.first(where: { $0.id == pid }) {
                        let alloc = ItemAllocation(item: existingItem, participant: p)
                        existingItem.allocations.append(alloc)
                    }
                }
            }
        } else {
            let newItem = Item(name: name, unitPriceCents: priceCents, quantity: quantity)
            for pid in selectedParticipantIds {
                if let p = participants.first(where: { $0.id == pid }) {
                    let alloc = ItemAllocation(item: newItem, participant: p)
                    newItem.allocations.append(alloc)
                }
            }
            onSave?(newItem)
        }
        dismiss()
    }
}

struct ParticipantSelectBubble: View {
    let name: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.Splitzy.electricTeal : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                } else {
                    Text(String(name.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
    }
}
