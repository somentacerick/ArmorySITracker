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
        case .companyOfficer,
             .companyNCO,
             .companyArmorer,
             .platoonOfficer,
             .platoonNCO,
             .platoonArmorer,
             .squadLeader,
             .teamLeader:
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
    var position: String
    
    init(
        rank: String = "",
        firstName: String = "",
        lastName: String = "",
        company: String = "",
        platoon: String = "",
        squad: String = "",
        team: String = "",
        position: String = ""
    ) {
        self.rank = rank
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.platoon = platoon
        self.squad = squad
        self.team = team
        self.position = position
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
        let parts = [company, platoon, squad, team, position].filter {
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
    var linkedSoldierID: UUID?
    
    init(
        id: UUID = UUID(),
        username: String,
        password: String,
        soldierInformation: UserSoldierInformation = UserSoldierInformation(),
        role: UserRole = .companyOfficer,
        linkedSoldierID: UUID? = nil
    ) {
        self.id = id
        self.loginInformation = UserLoginInformation(
            username: username,
            password: password
        )
        self.soldierInformation = soldierInformation
        self.role = role
        self.linkedSoldierID = linkedSoldierID
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
    
    static let positions = [
        "Team Leader",
        "Automatic Rifleman",
        "Grenadier",
        "Rifleman",
        "Machine Gunner",
        "Assistant Gunner",
        "Medic",
        "Squad Leader",
        "Platoon Leader",
        "Platoon Sergeant",
        "Commander",
        "1st Sergeant"
    ]
}

struct RankAuthority {
    static let rankOrder: [String: Int] = [
        "PVT": 1,
        "PV2": 2,
        "PFC": 3,
        "SPC": 4,
        "CPL": 5,
        "SGT": 6,
        "SSG": 7,
        "SFC": 8,
        "1SG": 9,
        "2LT": 10,
        "1LT": 11,
        "CPT": 12
    ]
    
    static func level(for rank: String) -> Int {
        rankOrder[rank.trimmed.uppercased()] ?? 0
    }
    
    static func allowedRanks(upTo currentUserRank: String) -> [String] {
        let currentLevel = level(for: currentUserRank)
        
        if currentLevel == 0 {
            return ArmyProfileOptions.allRanks
        }
        
        return ArmyProfileOptions.allRanks.filter {
            level(for: $0) <= currentLevel
        }
    }
}

struct InventoryCatalogOptions {
    static let weapons = [
        "M4A1 Carbine",
        "M9",
        "M17",
        "M110",
        "M320",
        "M249",
        "M240",
        "AT4",
        "M72 LAW"
    ]
    
    static let communications = [
        "Harris AN/PRC-163",
        "ATAK"
    ]
    
    static let nightVision = [
        "PVS-14",
        "NVG-40",
        "PVS-31",
        "AN/PSQ-20"
    ]
    
    static let optics = [
        "M68 CCO",
        "EOTECH",
        "ACOG",
        "LPVO",
        "Vortex XM157"
    ]
    
    static let other = [
        "Radio Battery",
        "M4A1 Magazine",
        "M17 Magazine",
        "M110 Magazine",
        "M249 Drum Magazine",
        "M240 Drum Magazine",
        "M249 Barrel",
        "M240 Barrel",
        "M9 Magazine"
    ]
    
    static func itemNames(for category: ItemCategory) -> [String] {
        switch category {
        case .weapon:
            return weapons
        case .optic:
            return optics
        case .communication:
            return communications
        case .nvg:
            return nightVision
        case .other:
            return other
        }
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
    var position: String
    var role: UserRole
    
    var displayName: String {
        "\(rank) \(lastName), \(firstName)"
    }
    
    var unitLine: String {
        let parts = [company, platoon, squad, team, position].filter {
            !$0.trimmed.isEmpty
        }
        
        return parts.joined(separator: " • ")
    }
    
    var searchableText: String {
        "\(rank) \(firstName) \(lastName) \(company) \(platoon) \(squad) \(team) \(position) \(role.rawValue)"
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
    var quantity: Int?
    
    var searchableText: String {
        "\(itemName) \(serialNumber) \(category.rawValue) \(status.rawValue) \(condition.rawValue) \(notes)"
    }
    
    var quantityDisplay: String {
        if let quantity {
            return "Qty: \(quantity)"
        }
        
        return "Serialized Item"
    }
    
    var symbolName: String {
        switch category {
        case .weapon:
            return "gun"
        case .optic:
            return "eye"
        case .communication:
            return "antenna.radiowaves.left.and.right"
        case .nvg:
            return "binoculars"
        case .other:
            return "number.square"
        }
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
