//
//  SplitCalculator.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/27/25.
//

import Foundation

/// Pure logic models for calculation input
struct CalcParticipant: Identifiable, Hashable {
    let id: UUID
    let name: String
}

struct CalcItem {
    let id: UUID
    let name: String
    let priceCents: Int
    let quantity: Int
    let assignedParticipantIds: [UUID]
}

struct ParticipantResult: Equatable {
    let participantId: UUID
    let subtotalCents: Int
    let taxShareCents: Int
    let tipShareCents: Int
    
    var totalCents: Int {
        subtotalCents + taxShareCents + tipShareCents
    }
}

struct BillCalculationResult {
    let participantResults: [ParticipantResult]
    let totalSubtotalCents: Int
    let totalTaxCents: Int
    let totalTipCents: Int
    let grandTotalCents: Int
}

class SplitCalculator {
    
    static func calculate(
        items: [CalcItem],
        taxCents: Int,
        tipCents: Int,
        participants: [CalcParticipant]
    ) -> BillCalculationResult {
        
        // 1. Calculate Subtotals per participant
        var participantSubtotals: [UUID: Int] = [:]
        var totalSubtotal = 0
        
        for participant in participants {
            participantSubtotals[participant.id] = 0
        }
        
        for item in items {
            let totalItemPrice = item.priceCents * item.quantity
            let assignedCount = item.assignedParticipantIds.count
            
            if assignedCount > 0 {
                // Split item price among assigned participants
                let baseShare = totalItemPrice / assignedCount
                let remainder = totalItemPrice % assignedCount
                
                for (index, participantId) in item.assignedParticipantIds.enumerated() {
                    var share = baseShare
                    // Distribute remainder cents to the first n participants
                    if index < remainder {
                        share += 1
                    }
                    participantSubtotals[participantId, default: 0] += share
                }
            } else {
                // Item not assigned to anyone? (Ideally shouldn't happen in valid state, but handle gracefull or ignore)
                // For MVP, we effectively "lose" this amount from specific people, but it adds to bill total.
                // Or we can treat it as shared by everyone. Let's assume validation prevents this or it's unassigned.
                // For now, simple implementation: ignore unassigned items for individual subtotals, but they exist in universe.
                // Actually, if unassigned, nobody pays for it.
            }
            if assignedCount > 0 {
                totalSubtotal += totalItemPrice
            }
        }
        
        // 2. Allocate Tax and Tip proportionally to subtotal
        // Formula: Share = (ParticipantSubtotal / TotalSubtotal) * TotalTax
        // But need to handle rounding carefully so sum(shares) == TotalTax
        
        // If totalSubtotal is 0, split tax/tip equally or 0?
        // If 0, avoid division by zero.
        
        let taxAllocation = allocateProportionally(totalAmount: taxCents, subtotals: participantSubtotals, totalSubtotal: totalSubtotal)
        let tipAllocation = allocateProportionally(totalAmount: tipCents, subtotals: participantSubtotals, totalSubtotal: totalSubtotal)
        
        // 3. Construct Result
        var results: [ParticipantResult] = []
        var calculatedGrandTotal = 0
        
        // Sort participants for deterministic output order (if needed, or just map)
        for participant in participants {
            let pid = participant.id
            let sub = participantSubtotals[pid] ?? 0
            let tax = taxAllocation[pid] ?? 0
            let tip = tipAllocation[pid] ?? 0
            
            let result = ParticipantResult(
                participantId: pid,
                subtotalCents: sub,
                taxShareCents: tax,
                tipShareCents: tip
            )
            results.append(result)
            calculatedGrandTotal += result.totalCents
        }
        
        return BillCalculationResult(
            participantResults: results,
            totalSubtotalCents: totalSubtotal,
            totalTaxCents: taxCents,
            totalTipCents: tipCents,
            grandTotalCents: totalSubtotal + taxCents + tipCents
        )
    }
    
    // Helper: Proportional Allocation with Remainder Distribution
    private static func allocateProportionally(totalAmount: Int, subtotals: [UUID: Int], totalSubtotal: Int) -> [UUID: Int] {
        if totalSubtotal == 0 {
            // Cannot allocate proportionally if subtotal is 0.
            // Edge case: maybe split equally? Or return 0?
            // If there's tax/tip but no items, technically nobody owes "subtotal",
            // but the tax/tip must include unpaid items or just be phantom.
            // Let's assume if subtotal is 0, tax/tip is 0 for participants (unallocatable).
            return [:]
        }
        
        var shares: [UUID: Int] = [:]
        var allocatedSoFar = 0
        var remainders: [(UUID, Double)] = [] // (ParticipantID, FractionalRemainder)
        
        for (pid, sub) in subtotals {
            // Exact math: share = (sub / totalSub) * totalAmount
            // implementation: (sub * totalAmount) / totalSub
            // Use Double for precision on remainder calculation
            
            let rawShareDouble = (Double(sub) * Double(totalAmount)) / Double(totalSubtotal)
            let flooredShare = Int(rawShareDouble)
            
            shares[pid] = flooredShare
            allocatedSoFar += flooredShare
            
            let fractionalPart = rawShareDouble - Double(flooredShare)
            remainders.append((pid, fractionalPart))
        }
        
        let leftOver = totalAmount - allocatedSoFar
        
        // Distribute leftover cents to those with largest fractional parts
        // Sort localized by fractional part descending
        // If tie, use UUID string description as stable tie breaker
        remainders.sort { (lhs, rhs) -> Bool in
            if abs(lhs.1 - rhs.1) > 0.000001 {
                return lhs.1 > rhs.1
            } else {
                return lhs.0.uuidString < rhs.0.uuidString
            }
        }
        
        for i in 0..<leftOver {
            if i < remainders.count {
                let pid = remainders[i].0
                shares[pid, default: 0] += 1
            }
        }
        
        return shares
    }
}
