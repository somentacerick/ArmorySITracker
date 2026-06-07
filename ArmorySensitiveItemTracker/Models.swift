//
//  Models.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import Foundation

//Main data strucs used throughout.
//Defines soldiers, inv items, users, roles, item catag, item status, item condition, and transaction records
//Protocols/Extensions for reusable behavior (ie searching/date formatting)

protocol SearchableRecord {
    var searchableText: String { get }
}

enum UserRole: String, CaseIterable, Identifiable, Codable {
    case companyLeadership = "Captain / First Sergeant"
    case platoonLeadership = "Platoon Leader / Platoon Sergeant"
    case squadLeader = "Squad Leader"
    case teamLeader = "Team Leader"
    case soldier = "Soldier"
    
    case companyArmorer = "Company Armorer"
    case platoonArmorer = "Platoon Armorer"
    
    var id: String { rawValue }
    
    var canEditPersonnel: Bool {
        switch self {
        case .companyLeadership, .platoonLeadership, .squadLeader, .teamLeader:
            return true
        case .companyArmorer, .platoonArmorer, .soldier:
            return false
        }
    }
    
    var canManageSI: Bool {
        switch self {
        case .companyLeadership, .companyArmorer, .platoonLeadership, .platoonArmorer, .squadLeader, .teamLeader:
            return true
        case .soldier:
            return false
        }
    }
    
    var canViewReports: Bool {
        self != .soldier
    }
}
    
struct AppUser: Identifiable, Codable {
    let id: UUID
    var username: String
    var role: UserRole
    
    init(id: UUID = UUID(), username: String, role: UserRole) {
        self.id = id
        self.username = username
        self.role = role
    }
}

enum ItemCategory: String, CaseIterable, Identifiable, Codable {
    case weapon = "Weapon"
    case optic = "Optic"
    case communication = "Communication"
    case nvg = "Night Vision Goggles"
    case other = "Other"
    
    var id: String { rawValue }
}

enum ItemStatus: String, CaseIterable, Identifiable, Codable {
    case unassigned = "Unassigned"
    case assigned = "Assigned"
    case missing = "Missing"
    case damaged = "Damaged"
    case pendingTurnIn = "Pending Turn In"
    
    var id: String { rawValue }
}

enum ItemCondition: String, CaseIterable, Identifiable, Codable {
    case serviceable = "Serviceable"
    case needsInspection = "Needs Inspection"
    case damaged = "Damaged"
    
    var id: String { rawValue }
}

enum TransactionType: String, Codable {
    case issue = "Issue"
    case turnIn = "Turn In"
    case statusChange = "Status Change"
}

struct Soldier: Identifiable, Codable, Hashable, SearchableRecord {
    var id: UUID
    var rank: String
    var firstName: String
    var lastName: String
    var company: String
    var platoon: String
    var squad: String
    var team: String
    
    var displayName: String {
        "\(rank) \(lastName), \(firstName)"
    }
    
    var unitLine: String {
        "\(company) • \(platoon) • \(squad) • \(team)"
    }
    
    var searchableText: String {
        "\(rank) \(firstName) \(lastName) \(platoon) \(squad) \(team)"
    }
}

struct InventoryItem: Identifiable, Codable, Hashable, SearchableRecord {
    var id: UUID
    var itemName: String
    var serialNumber: String
    var category: ItemCategory
    var status: ItemStatus
    var assignedSoldierID: UUID?
    var condition: ItemCondition
    var issueDate: Date?
    var notes: String
    
    var searchableText: String {
        "\(itemName) \(serialNumber) \(category.rawValue) \(status.rawValue) \(condition.rawValue) \(notes)"
    }
}

struct TransactionRecord: Identifiable, Codable {
    var id: UUID
    var type: TransactionType
    var itemID: UUID
    var soldierID: UUID?
    var date: Date
    var condition: ItemCondition
    var notes: String
}

extension Date {
    var shortDisplay: String {
        Self.shortFormatter.string(from: self)
    }
    
    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

