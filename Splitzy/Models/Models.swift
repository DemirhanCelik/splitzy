//
//  Models.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class Bill {
    var id: UUID
    var ownerUserId: String?
    var title: String
    var createdAt: Date
    var currency: String
    var taxCents: Int
    var tipCents: Int
    var shareToken: String?
    var isLinkActive: Bool
    
    @Relationship(deleteRule: .cascade) var participants: [Participant] = []
    @Relationship(deleteRule: .cascade) var items: [Item] = []
    
    init(
        id: UUID = UUID(),
        ownerUserId: String? = nil,
        title: String = "",
        createdAt: Date = Date(),
        currency: String = Locale.current.currency?.identifier ?? "USD",
        taxCents: Int = 0,
        tipCents: Int = 0,
        shareToken: String? = nil,
        isLinkActive: Bool = true
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.title = title
        self.createdAt = createdAt
        self.currency = currency
        self.taxCents = taxCents
        self.tipCents = tipCents
        self.shareToken = shareToken
        self.isLinkActive = isLinkActive
    }
}

@Model
final class Participant {
    var id: UUID
    var displayName: String
    var linkedUserId: String?
    var createdAt: Date
    
    // Inverse relationship is inferred by SwiftData usually, but explicit inverse can be safer if needed.
    // For now, implicit reference from Bill.participants is fine.
    var bill: Bill?
    
    @Relationship(deleteRule: .cascade) var allocatedItems: [ItemAllocation] = []
    
    init(
        id: UUID = UUID(),
        displayName: String,
        linkedUserId: String? = nil,
        createdAt: Date = Date(),
        bill: Bill? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.linkedUserId = linkedUserId
        self.createdAt = createdAt
        self.bill = bill
    }
}

@Model
final class Item {
    var id: UUID
    var name: String
    var unitPriceCents: Int
    var quantity: Int
    var createdAt: Date
    
    var bill: Bill?
    
    @Relationship(deleteRule: .cascade) var allocations: [ItemAllocation] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        unitPriceCents: Int = 0,
        quantity: Int = 1,
        createdAt: Date = Date(),
        bill: Bill? = nil
    ) {
        self.id = id
        self.name = name
        self.unitPriceCents = unitPriceCents
        self.quantity = quantity
        self.createdAt = createdAt
        self.bill = bill
    }
}

@Model
final class ItemAllocation {
    var id: UUID
    var shareWeight: Int
    
    var item: Item?
    var participant: Participant?
    
    init(
        id: UUID = UUID(),
        shareWeight: Int = 1,
        item: Item? = nil,
        participant: Participant? = nil
    ) {
        self.id = id
        self.shareWeight = shareWeight
        self.item = item
        self.participant = participant
    }
}
