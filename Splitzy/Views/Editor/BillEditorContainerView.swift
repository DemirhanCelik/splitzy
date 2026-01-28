//
//  BillEditorContainerView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct BillEditorContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var bill: Bill
    @State private var smartInputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    // For SwiftUI Native Alert
    @State private var showingAddPersonAlert = false
    @State private var newPersonName = ""
    
    // For Item Editing
    @State private var editingItem: Item?
    
    // For Receipt Scanning
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var scannedReceipt: ParsedReceipt?
    
    // Initializer
    init(bill: Bill? = nil) {
        if let existingBill = bill {
            _bill = State(initialValue: existingBill)
        } else {
            _bill = State(initialValue: Bill(title: ""))
        }
    }

    

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Splitzy.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                            .padding(10)
                            .background(Color.Splitzy.surface)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    TextField("Bill Title", text: $bill.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .submitLabel(.done)
                    
                    Spacer()
                    
                    // Review/Done Button
                    NavigationLink(destination: ReviewView(bill: bill)) {
                        Text("Review")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(LinearGradient.vibrantMain)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color.Splitzy.background.opacity(0.95))
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Participants (Stories Style)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Split with")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    // Add Button
                                    Button(action: addParticipant) {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 50, height: 50)
                                                Image(systemName: "plus")
                                                    .foregroundColor(.secondary)
                                            }
                                            Text("Add")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    ForEach(bill.participants) { participant in
                                        ContactBubble(
                                            name: participant.displayName,
                                            allNames: bill.participants.map { $0.displayName }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4) // Prevent clipping
                            }
                        }
                        .padding(.top, 10)
                        
                        Divider().padding(.horizontal)
                        
                        // MARK: - Feed (Items)
                        if bill.items.isEmpty {
                            EmptyFeedPlaceholder()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(bill.items.reversed()) { item in
                                    FeedItemCard(
                                        item: item,
                                        participants: bill.participants,
                                        allNames: bill.participants.map { $0.displayName }
                                    )
                                    .onTapGesture {
                                        editingItem = item
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                if let idx = bill.items.firstIndex(where: { $0.id == item.id }) {
                                                    bill.items.remove(at: idx)
                                                }
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal)
                            
                            // MARK: - Tax & Tip Section (Inline)
                            TaxTipQuickEntry(bill: bill)
                                .padding(.horizontal)
                                .padding(.top, 16)
                            
                            Spacer().frame(height: 100) // Space for input bar
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // MARK: - Sticky Smart Input Bar
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.Splitzy.vibrantPurple)
                        
                        TextField("e.g. Burger 12...", text: $smartInputText)
                            .submitLabel(.send)
                            .focused($isInputFocused)
                            .onSubmit {
                                parseAndAddItem()
                            }
                    }
                    .padding()
                    .background(Color.Splitzy.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Button(action: parseAndAddItem) {
                        Image(systemName: "arrow.up")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(smartInputText.isEmpty ? Color.gray : Color.Splitzy.electricTeal)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                    .disabled(smartInputText.isEmpty)
                    
                    // Camera/Scan Button
                    Button(action: { showingPhotoPicker = true }) {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 50, height: 50)
                                .background(Color.Splitzy.vibrantPurple)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(LinearGradient.vibrantMain)
                                .clipShape(Circle())
                                .shadow(color: Color.Splitzy.vibrantPurple.opacity(0.4), radius: 5, x: 0, y: 5)
                        }
                    }
                    .disabled(isScanning)
                }
                .padding()
                .background(
                    LinearGradient(colors: [Color.Splitzy.background.opacity(0), Color.Splitzy.background], startPoint: .top, endPoint: .bottom)
                )
            }
        }
        .onAppear {
            if bill.modelContext == nil {
                modelContext.insert(bill)
            }
        }
        .alert("Add Person", isPresented: $showingAddPersonAlert) {
            TextField("Name", text: $newPersonName)
            Button("Cancel", role: .cancel) {
                newPersonName = ""
            }
            Button("Add") {
                let trimmed = newPersonName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    withAnimation {
                        let p = Participant(displayName: trimmed, bill: bill)
                        bill.participants.append(p)
                    }
                }
                newPersonName = ""
            }
        } message: {
            Text("Enter the person's name")
        }
        .navigationBarHidden(true)
        .sheet(item: $editingItem) { item in
            ItemEditSheet(item: item)
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await processSelectedPhoto(newItem)
            }
        }
        .alert("Scan Error", isPresented: Binding(
            get: { scanError != nil },
            set: { if !$0 { scanError = nil } }
        )) {
            Button("OK") { scanError = nil }
        } message: {
            Text(scanError ?? "Unknown error")
        }
        .sheet(item: $scannedReceipt) { receipt in
            ScanReviewView(receipt: receipt) { items, tax, tip in
                addScannedItems(items: items, taxCents: tax, tipCents: tip)
            }
        }
        }
    }
    
    // MARK: - Logic
    
    private func addParticipant() {
        showingAddPersonAlert = true
    }
    
    func parseAndAddItem() {
        let trimmed = smartInputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Simple Parser: Look for the last number as price
        // "Burger 12.50" -> Name: Burger, Price: 12.50
        // "Fries 5" -> Name: Fries, Price: 5.00
        
        let components = trimmed.components(separatedBy: " ")
        if let last = components.last, let price = Double(last) {
            let name = components.dropLast().joined(separator: " ")
            let priceCents = Int(round(price * 100))
            
            addItem(name: name.isEmpty ? "Item" : name, priceCents: priceCents)
        } else {
            // No number found? Just add as 0 price or entire string as name
            addItem(name: trimmed, priceCents: 0)
        }
        
        smartInputText = ""
        // Keep focus? Maybe.
    }
    
    func addItem(name: String, priceCents: Int) {
        let item = Item(name: name, unitPriceCents: priceCents, quantity: 1)
        // Auto-assign to everyone? Or no one?
        // Frictionless: Assign to everyone usually safer, or no one.
        // Let's do NO ONE so they tap the bubbles to assign (fun factor).
        withAnimation(.spring()) {
            bill.items.append(item)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Process a selected photo through the receipt scanner
    func processSelectedPhoto(_ item: PhotosPickerItem) async {
        isScanning = true
        selectedPhotoItem = nil
        
        do {
            // Load the image data
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                scanError = "Could not load image"
                isScanning = false
                return
            }
            
            // Scan with Vision OCR + Gemini parsing
            let receipt = try await ReceiptScannerService.shared.scanReceipt(image: uiImage)
            
            // Show review screen
            await MainActor.run {
                scannedReceipt = receipt
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            
        } catch {
            scanError = error.localizedDescription
        }
        
        isScanning = false
    }
    
    /// Add confirmed items from scan review to the bill
    private func addScannedItems(items: [ParsedReceiptItem], taxCents: Int, tipCents: Int) {
        withAnimation(.spring()) {
            for parsed in items {
                let priceCents = Int(round(parsed.price * 100))
                let newItem = Item(name: parsed.name, unitPriceCents: priceCents, quantity: 1)
                bill.items.append(newItem)
            }
            
            // Update tax and tip
            bill.taxCents = taxCents
            bill.tipCents = tipCents
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// MARK: - Subviews

struct ContactBubble: View {
    let name: String
    let allNames: [String]
    
    private var initials: String {
        let firstChar = String(name.prefix(1)).uppercased()
        // Check if there's another name with the same first letter
        let sameFirstLetter = allNames.filter { $0.prefix(1).uppercased() == firstChar }
        if sameFirstLetter.count > 1 && name.count >= 2 {
            return String(name.prefix(2)).uppercased()
        }
        return firstChar
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle().stroke(LinearGradient(colors: [.orange, .pink], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: 2)
                    )
                
                Text(initials)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: 60)
        }
    }
}

struct EmptyFeedPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.3))
                .padding(.top, 50)
            
            Text("Type below to add items")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try \"Burger 12\" or \"Beer 8.50\"")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
    }
}

struct FeedItemCard: View {
    let item: Item
    let participants: [Participant]
    let allNames: [String]
    @State private var justTappedParticipant: UUID?
    
    private func getInitials(for name: String) -> String {
        let firstChar = String(name.prefix(1)).uppercased()
        let sameFirstLetter = allNames.filter { $0.prefix(1).uppercased() == firstChar }
        if sameFirstLetter.count > 1 && name.count >= 2 {
            return String(name.prefix(2)).uppercased()
        }
        return firstChar
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tap to edit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(formatMoney(item.unitPriceCents))
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.primary)
            }
            
            // Bottom: Quick Assign Bubbles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(participants) { participant in
                        let isAssigned = item.allocations.contains { $0.participant?.id == participant.id }
                        
                        Button(action: { toggleAssign(participant) }) {
                            Text(getInitials(for: participant.displayName))
                                .font(.caption.bold())
                                .foregroundColor(isAssigned ? .white : .secondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    isAssigned ? Color.Splitzy.electricTeal : Color.gray.opacity(0.1)
                                )
                                .clipShape(Circle())
                                .scaleEffect(justTappedParticipant == participant.id ? 1.2 : 1.0)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.Splitzy.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func toggleAssign(_ p: Participant) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            justTappedParticipant = p.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { justTappedParticipant = nil }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if let idx = item.allocations.firstIndex(where: { $0.participant?.id == p.id }) {
            item.allocations.remove(at: idx)
        } else {
            let alloc = ItemAllocation(item: item, participant: p)
            item.allocations.append(alloc)
        }
    }
    
    func formatMoney(_ cents: Int) -> String {
        let amount = Double(cents) / 100.0
        return amount.formatted(.currency(code: "USD"))
    }
}

// MARK: - Item Edit Sheet
struct ItemEditSheet: View {
    @Bindable var item: Item
    @Environment(\.dismiss) var dismiss
    @State private var nameText: String = ""
    @State private var priceText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $nameText)
                    HStack {
                        Text("$")
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.name = nameText
                        item.unitPriceCents = Int((Double(priceText) ?? 0) * 100)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .onAppear {
            nameText = item.name
            priceText = String(format: "%.2f", Double(item.unitPriceCents) / 100)
        }
    }
}

// MARK: - Tax & Tip Quick Entry
struct TaxTipQuickEntry: View {
    @Bindable var bill: Bill
    @State private var taxString: String = ""
    @State private var tipString: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Tax & Tip")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                // Tax
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tax")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $taxString)
                            .keyboardType(.decimalPad)
                            .onChange(of: taxString) { _, newValue in
                                bill.taxCents = Int((Double(newValue) ?? 0) * 100)
                            }
                    }
                    .padding(12)
                    .background(Color.Splitzy.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Tip
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $tipString)
                            .keyboardType(.decimalPad)
                            .onChange(of: tipString) { _, newValue in
                                bill.tipCents = Int((Double(newValue) ?? 0) * 100)
                            }
                    }
                    .padding(12)
                    .background(Color.Splitzy.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color.Splitzy.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            if bill.taxCents > 0 { taxString = String(format: "%.2f", Double(bill.taxCents) / 100) }
            if bill.tipCents > 0 { tipString = String(format: "%.2f", Double(bill.tipCents) / 100) }
        }
    }
}
