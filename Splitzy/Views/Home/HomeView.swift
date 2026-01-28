//
//  HomeView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bill.createdAt, order: .reverse) private var bills: [Bill]
    
    @State private var showingNewBillSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.Splitzy.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Text("My Bills")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(Color.Splitzy.surface)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if bills.isEmpty {
                        EmptyStateView()
                    } else {
                        List {
                            ForEach(bills) { bill in
                                NavigationLink(destination: BillEditorContainerView(bill: bill)) {
                                    BillCard(bill: bill)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteBills)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingNewBillSheet = true }) {
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
            .fullScreenCover(isPresented: $showingNewBillSheet) {
                BillEditorContainerView()
            }
        }
    }
    
    private func deleteBills(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(bills[index])
        }
    }
}


// MARK: - Subviews

struct BillCard: View {
    let bill: Bill
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(bill.title.isEmpty ? "Untitled Bill" : bill.title)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(bill.participants.count)")
                        .font(.caption)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "list.bullet")
                        .font(.caption)
                    Text("\(bill.items.count) items")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Total Amount
            VStack(alignment: .trailing) {
                Text(formatTotal())
                    .font(.title2.bold())
                    .foregroundStyle(LinearGradient.vibrantMain)
            }
        }
        .padding()
        .background(Color.Splitzy.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func formatTotal() -> String {
        let total = bill.items.reduce(0) { $0 + $1.unitPriceCents * $1.quantity } + bill.taxCents + bill.tipCents
        return (Double(total) / 100.0).formatted(.currency(code: bill.currency))
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "receipt")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient.vibrantMain)
            
            Text("No bills yet")
                .font(.title2.bold())
            
            Text("Tap + to create your first bill")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
