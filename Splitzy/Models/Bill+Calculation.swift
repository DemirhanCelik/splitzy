//
//  Bill+Calculation.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/27/25.
//

import Foundation

extension Bill {
    func calculateSplit() -> BillCalculationResult {
        // Map Participants
        let calcParticipants = participants.map {
            CalcParticipant(id: $0.id, name: $0.displayName)
        }
        
        // Map Items
        let calcItems = items.map { item -> CalcItem in
            let assignedIds = item.allocations.compactMap { allocation -> UUID? in
                // Allocation points to participant
                // If allocation exists, it means assigned.
                // We trust the allocation.participant is consistent with bill.participants
                return allocation.participant?.id
            }
            
            return CalcItem(
                id: item.id,
                name: item.name,
                priceCents: item.unitPriceCents,
                quantity: item.quantity,
                assignedParticipantIds: assignedIds
            )
        }
        
        return SplitCalculator.calculate(
            items: calcItems,
            taxCents: taxCents,
            tipCents: tipCents,
            participants: calcParticipants
        )
    }
    
    // Helper to get total amount
    var totalAmountCents: Int {
        let result = calculateSplit()
        return result.grandTotalCents
    }
}
