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
    case companyOfficer = "Commander"
    case companyNCO = "First Sergeant"
    case platoonOfficer = "Platoon Leader"
    case platoonNCO = "Platoon Sergeant"
    case squadLeader = "Squad Leader"
    case teamLeader = "Team Leader"
    case soldier = "Soldier"
    case companyArmorer = "Company Armorer"
    case platoonArmorer = "Platoon Armorer"
    
    var id: String { rawValue }
    
    var canEditPersonnel: Bool {
        var canEditPersonnel: Bool {
            switch self {
            case .soldier:
                return false
            case .companyOfficer,
                 .companyNCO,
                 .platoonOfficer,
                 .platoonNCO,
                 .squadLeader,
                 .teamLeader,
                 .companyArmorer,
                 .platoonArmorer:
                return true
            }
        }
        
    var canManageSI: Bool {
        switch self {
        case .companyOfficer, .companyNCO, .companyArmorer,
             .platoonOfficer, .platoonNCO, .platoonArmorer,
             .squadLeader, .teamLeader:
            return true
        case .soldier:
            return false
        }
    }
    
    var canViewReports: Bool {
        self != .soldier
    }
}

struct UserLoginInformation: Codable, Hashable {
    var username: String
    var password: String
}

struct UserSoldierInformation: Codable, Hashable {
    var rank: String
    var firstName: String
    var lastName: String
    var company: String
    var platoon: String
    var squad: String
    var team: String
    
    init(
        rank: String = "",
        firstName: String = "",
        lastName: String = "",
        company: String = "",
        platoon: String = "",
        squad: String = "",
        team: String = ""
    ) {
        self.rank = rank
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.platoon = platoon
        self.squad = squad
        self.team = team
    }
    
    var displayName: String {
        let cleanRank = rank.trimmed.uppercased()
        let cleanLast = lastName.trimmed
        let cleanFirst = firstName.trimmed
        
        if cleanRank.isEmpty || cleanLast.isEmpty || cleanFirst.isEmpty {
            return "Complete Profile"
        }
        
        return "\(cleanRank) \(cleanLast), \(cleanFirst)"
    }
    
    var unitLine: String {
        let parts = [company, platoon, squad, team].filter {
            !$0.trimmed.isEmpty
        }
        
        if parts.isEmpty {
            return "Unit information not set"
        }
        
        return parts.joined(separator: " • ")
    }
}

struct AppUser: Identifiable, Codable {
    let id: UUID
    var loginInformation: UserLoginInformation
    var soldierInformation: UserSoldierInformation
    var role: UserRole
    
    init(
        id: UUID = UUID(),
        username: String,
        password: String,
        soldierInformation: UserSoldierInformation = UserSoldierInformation(),
        role: UserRole = .companyOfficer
    ) {
        self.id = id
        self.loginInformation = UserLoginInformation(
            username: username,
            password: password
        )
        self.soldierInformation = soldierInformation
        self.role = role
    }
    
    var profileDisplayName: String {
        soldierInformation.displayName
    }
    
    var username: String {
        loginInformation.username
    }
    
    var password: String {
        loginInformation.password
    }
}

struct ArmyProfileOptions {
    static let enlistedRanks = [
        "PVT",
        "PV2",
        "PFC",
        "SPC",
        "CPL",
        "SGT",
        "SSG",
        "SFC",
        "1SG"
    ]
    
    static let officerRanks = [
        "2LT",
        "1LT",
        "CPT"
    ]
    
    static let allRanks = enlistedRanks + officerRanks
    
    static let companies = [
        "Alpha",
        "Bravo",
        "Charlie",
        "Delta",
        "Echo",
        "Fox",
        "HHC"
    ]
    
    static let platoons = [
        "1st",
        "2nd",
        "3rd",
        "4th",
        "HQ"
    ]
    
    static let squads = [
        "1st",
        "2nd",
        "3rd",
        "4th",
        "Weapons"
    ]
    
    static let teams = [
        "Alpha",
        "Bravo"
    ]
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

