//
//  SplitCalculatorTests.swift
//  SplitzyTests
//
//  Created by Demirhan Celik on 12/27/25.
//

import XCTest
@testable import Splitzy

final class SplitCalculatorTests: XCTestCase {

    // Helper to create UUIDs deterministically if needed, usually random is fine for logic tests
    // unless checking specific sort order. For allocation, we sort by UUID as tie breaker.
    
    func testSinglePerson() throws {
        let p1 = CalcParticipant(id: UUID(), name: "P1")
        let item = CalcItem(id: UUID(), name: "Burger", priceCents: 1000, quantity: 1, assignedParticipantIds: [p1.id])
        
        let result = SplitCalculator.calculate(
            items: [item],
            taxCents: 100,
            tipCents: 200,
            participants: [p1]
        )
        
        XCTAssertEqual(result.totalSubtotalCents, 1000)
        XCTAssertEqual(result.participantResults.count, 1)
        XCTAssertEqual(result.participantResults.first?.subtotalCents, 1000)
        XCTAssertEqual(result.participantResults.first?.taxShareCents, 100)
        XCTAssertEqual(result.participantResults.first?.tipShareCents, 200)
        XCTAssertEqual(result.participantResults.first?.totalCents, 1300)
    }

    func testTwoPeopleEqualSplit() throws {
        let p1 = CalcParticipant(id: UUID(), name: "P1")
        let p2 = CalcParticipant(id: UUID(), name: "P2")
        
        let item = CalcItem(id: UUID(), name: "Pizza", priceCents: 2000, quantity: 1, assignedParticipantIds: [p1.id, p2.id])
        
        let result = SplitCalculator.calculate(
            items: [item],
            taxCents: 200, // 10%
            tipCents: 400, // 20%
            participants: [p1, p2]
        )
        
        // Total: 2000 + 200 + 400 = 2600.
        // Each pays 1300.
        
        let r1 = result.participantResults.first(where: { $0.participantId == p1.id })!
        let r2 = result.participantResults.first(where: { $0.participantId == p2.id })!
        
        XCTAssertEqual(r1.subtotalCents, 1000)
        XCTAssertEqual(r2.subtotalCents, 1000)
        XCTAssertEqual(r1.taxShareCents, 100)
        XCTAssertEqual(r2.taxShareCents, 100)
        XCTAssertEqual(r1.tipShareCents, 200)
        XCTAssertEqual(r2.tipShareCents, 200)
    }

    func testOneItemSharedAmong3_Rounding() throws {
        // Price 100. Split 3 ways.
        // 33, 33, 33. Remainder 1.
        // First person in assigned list gets remainder (simple logic in code) or random?
        // Code implementation: "for (index, participantId) in item.assignedParticipantIds.enumerated() ... if index < remainder { share += 1 }"
        // So the first person in the list gets the extra penny.
        
        let pA = CalcParticipant(id: UUID(), name: "A")
        let pB = CalcParticipant(id: UUID(), name: "B")
        let pC = CalcParticipant(id: UUID(), name: "C")
        
        let item = CalcItem(id: UUID(), name: "Fries", priceCents: 100, quantity: 1, assignedParticipantIds: [pA.id, pB.id, pC.id])
        
        let result = SplitCalculator.calculate(
            items: [item],
            taxCents: 0,
            tipCents: 0,
            participants: [pA, pB, pC]
        )
        
        let rA = result.participantResults.first(where: { $0.participantId == pA.id })!
        let rB = result.participantResults.first(where: { $0.participantId == pB.id })!
        let rC = result.participantResults.first(where: { $0.participantId == pC.id })!
        
        // Sum must be 100
        XCTAssertEqual(rA.subtotalCents + rB.subtotalCents + rC.subtotalCents, 100)
        
        // Based on logic: pA is index 0. Remainder 100 % 3 = 1. index 0 < 1 is true.
        XCTAssertEqual(rA.subtotalCents, 34)
        XCTAssertEqual(rB.subtotalCents, 33)
        XCTAssertEqual(rC.subtotalCents, 33)
    }
    
    func testTaxTipProportional() throws {
        // P1 buys 1000 item.
        // P2 buys 3000 item.
        // Tax 400. Tip 800.
        // P1 subtotal fraction: 1000 / 4000 = 0.25
        // P2 subtotal fraction: 3000 / 4000 = 0.75
        
        // P1 tax: 0.25 * 400 = 100
        // P2 tax: 0.75 * 400 = 300
        
        // P1 tip: 0.25 * 800 = 200
        // P2 tip: 0.75 * 800 = 600
        
        let p1 = CalcParticipant(id: UUID(), name: "P1")
        let p2 = CalcParticipant(id: UUID(), name: "P2")
        
        let i1 = CalcItem(id: UUID(), name: "Cheap", priceCents: 1000, quantity: 1, assignedParticipantIds: [p1.id])
        let i2 = CalcItem(id: UUID(), name: "Expensive", priceCents: 3000, quantity: 1, assignedParticipantIds: [p2.id])
        
        let result = SplitCalculator.calculate(
            items: [i1, i2],
            taxCents: 400,
            tipCents: 800,
            participants: [p1, p2]
        )
        
        let r1 = result.participantResults.first(where: { $0.participantId == p1.id })!
        let r2 = result.participantResults.first(where: { $0.participantId == p2.id })!
        
        XCTAssertEqual(r1.taxShareCents, 100)
        XCTAssertEqual(r2.taxShareCents, 300)
        
        XCTAssertEqual(r1.tipShareCents, 200)
        XCTAssertEqual(r2.tipShareCents, 600)
    }
    
    func testRoundingRemainderDistribution() throws {
        // Test allocation rounding logic specifically.
        // Total Subtotal: 300. P1: 100 (1/3), P2: 100 (1/3), P3: 100 (1/3).
        // Tax: 100.
        // Share: 100 * (1/3) = 33.333...
        // Total allocated: 33 * 3 = 99. Leftover: 1.
        // Who gets it? Tie breaking logic.
        // Since subtotals are equal, fractional parts are equal (0.333...).
        // Tie breaker is UUID string. One of them gets 34.
        
        let p1 = CalcParticipant(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "A")
        let p2 = CalcParticipant(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "B")
        let p3 = CalcParticipant(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "C")
        
        // Ensure items result in equal subtotals
        let i1 = CalcItem(id: UUID(), name: "I1", priceCents: 100, quantity: 1, assignedParticipantIds: [p1.id])
        let i2 = CalcItem(id: UUID(), name: "I2", priceCents: 100, quantity: 1, assignedParticipantIds: [p2.id])
        let i3 = CalcItem(id: UUID(), name: "I3", priceCents: 100, quantity: 1, assignedParticipantIds: [p3.id])
        
        let result = SplitCalculator.calculate(
            items: [i1, i2, i3],
            taxCents: 100,
            tipCents: 0,
            participants: [p1, p2, p3]
        )
        
        let taxSum = result.participantResults.map(\.taxShareCents).reduce(0, +)
        XCTAssertEqual(taxSum, 100)
        
        // One should have 34, others 33.
        let taxes = result.participantResults.map(\.taxShareCents).sorted()
        XCTAssertEqual(taxes, [33, 33, 34])
    }
    
    func testMultipleQuantitiesAndAssignments() throws {
        // Item: 2 Beers @ 500 each = 1000 total.
        // Assigned to P1 and P2.
        // 1000 / 2 = 500 each.
        
        let p1 = CalcParticipant(id: UUID(), name: "P1")
        let p2 = CalcParticipant(id: UUID(), name: "P2")
        
        let item = CalcItem(id: UUID(), name: "Beer", priceCents: 500, quantity: 2, assignedParticipantIds: [p1.id, p2.id])
        
        let result = SplitCalculator.calculate(
            items: [item],
            taxCents: 0,
            tipCents: 0,
            participants: [p1, p2]
        )
        
        let r1 = result.participantResults.first(where: { $0.participantId == p1.id })!
        let r2 = result.participantResults.first(where: { $0.participantId == p2.id })!
        
        XCTAssertEqual(r1.subtotalCents, 500)
        XCTAssertEqual(r2.subtotalCents, 500)
    }
}
