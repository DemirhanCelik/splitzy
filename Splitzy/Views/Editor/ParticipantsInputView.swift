//
//  ParticipantsInputView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI
import SwiftData

struct ParticipantsInputView: View {
    @Bindable var bill: Bill
    @Environment(\.dismiss) var dismiss
    
    @State private var newName: String = ""
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
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
                    Text("Participants")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    // Balance space
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Input Area
                        HStack {
                            TextField("Name (e.g. Alice)", text: $newName)
                                .font(.body)
                                .padding()
                                .background(Color.Splitzy.surface)
                                .cornerRadius(15)
                                .focused($isNameFocused)
                                .submitLabel(.done)
                                .onSubmit { addParticipant() }
                            
                            Button(action: addParticipant) {
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        newName.isEmpty ? Color.gray : Color.Splitzy.electricTeal
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                            .disabled(newName.isEmpty)
                        }
                        .padding(.horizontal)
                        
                        // List
                        if bill.participants.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "person.3.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text("Add friends to start splitting!")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(bill.participants) { participant in
                                    ParticipantRow(participant: participant) {
                                        if let idx = bill.participants.firstIndex(of: participant) {
                                            withAnimation {
                                                bill.participants.remove(at: idx)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func addParticipant() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let participant = Participant(displayName: trimmed, bill: bill)
        withAnimation {
            bill.participants.append(participant)
        }
        
        newName = ""
        isNameFocused = true
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Avatar Placeholder
            Text(String(participant.displayName.prefix(1)).uppercased())
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.Splitzy.vibrantPurple.gradient)
                .clipShape(Circle())
            
            Text(participant.displayName)
                .font(.body.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.Splitzy.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
