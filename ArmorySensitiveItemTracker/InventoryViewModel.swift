//
//  InventoryViewModel.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import Foundation
import Combine

//Main app logic
//Manages personnel, inv items, transactions, login state, role permissions, validation, issuing items, turning items in, updating item status, filtering/searching records, and saving/loading local data

enum InventoryError: LocalizedError {
    case emptyField(String)
    case duplicateSerial
    case itemAlreadyAssigned
    case itemNotAssigned
    case missingItem
    case missingSoldier
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty."
        case .duplicateSerial:
            return "An item with this serial number already exists."
        case .itemAlreadyAssigned:
            return "This item is already assigned."
        case .itemNotAssigned:
            return "This item is not currently assigned."
        case .missingItem:
            return "The selected item could not be found."
        case .missingSoldier:
            return "The selected soldier could not be found."
        case .unauthorized:
            return "Your current role does not have permission to perform this action."
        }
    }
}

struct SavedInventoryData: Codable {
    var soldiers: [Soldier]
    var items: [InventoryItem]
    var transactions: [TransactionRecord]
    var currentUser: AppUser?
}

final class InventoryStorage {
    private let fileName = "armory_inventory_data.json"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    func load() -> SavedInventoryData? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return try? JSONDecoder().decode(SavedInventoryData.self, from: data)
    }
    
    func save(_ data: SavedInventoryData) throws {
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: fileURL, options: [.atomic])
    }
}

@MainActor
final class InventoryViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var soldiers: [Soldier] = []
    @Published var items: [InventoryItem] = []
    @Published var transactions: [TransactionRecord] = []
    
    private let storage = InventoryStorage()
    
    init() {
        loadData()
    }
    
    var assignedItems: [InventoryItem] {
        items.filter { $0.status == .assigned }
    }
    
    var unassignedItems: [InventoryItem] {
        items.filter { $0.status == .unassigned }
    }
    
    var missingOrDamagedItems: [InventoryItem] {
        items.filter { $0.status == .missing || $0.status == .damaged }
    }
    
    var pendingTurnInItems: [InventoryItem] {
        items.filter { $0.status == .pendingTurnIn }
    }
    
    func login(username: String, password: String) throws {
        guard !username.trimmed.isEmpty else {
            throw InventoryError.emptyField("Username")
        }
        
        guard !password.trimmed.isEmpty else {
            throw InventoryError.emptyField("Password")
        }
        
        currentUser = AppUser(
            username: username.trimmed,
            password: password.trimmed,
            role: .companyOfficer
        )
        
        saveData()
    }
    
    func logout() {
        currentUser = nil
    }
    
    func soldier(for id: UUID?) -> Soldier? {
        guard let id else {
            return nil
        }
        
        return soldiers.first { $0.id == id }
    }
    
    func item(for id: UUID) -> InventoryItem? {
        items.first { $0.id == id }
    }
    
    func items(for soldierID: UUID) -> [InventoryItem] {
        items
            .filter { $0.assignedSoldierID == soldierID }
            .sorted { $0.itemName < $1.itemName }
    }
    
    func filteredSoldiers(searchText: String) -> [Soldier] {
        let text = searchText.trimmed.lowercased()
        
        return soldiers
            .filter {
                text.isEmpty || $0.searchableText.lowercased().contains(text)
            }
            .sorted {
                $0.lastName < $1.lastName
            }
    }
    
    func filteredItems(searchText: String, status: ItemStatus?, category: ItemCategory?) -> [InventoryItem] {
        let text = searchText.trimmed.lowercased()
        
        return items
            .filter {
                text.isEmpty || $0.searchableText.lowercased().contains(text)
            }
            .filter {
                status == nil || $0.status == status
            }
            .filter {
                category == nil || $0.category == category
            }
            .sorted {
                $0.itemName < $1.itemName
            }
    }
    
    func updateLoginInformation(
        username: String,
        password: String
    ) throws {
        guard !username.trimmed.isEmpty else {
            throw InventoryError.emptyField("Username")
        }
        
        guard !password.trimmed.isEmpty else {
            throw InventoryError.emptyField("Password")
        }
        
        guard var user = currentUser else {
            return
        }
        
        user.loginInformation = UserLoginInformation(
            username: username.trimmed,
            password: password.trimmed
        )
        
        currentUser = user
        saveData()
    }
    
    func updateSoldierProfileInformation(
        rank: String,
        firstName: String,
        lastName: String,
        company: String,
        platoon: String,
        squad: String,
        team: String,
        position: String,
        role: UserRole
    ) throws {
        guard !rank.trimmed.isEmpty else {
            throw InventoryError.emptyField("Rank")
        }
        
        guard !firstName.trimmed.isEmpty else {
            throw InventoryError.emptyField("First name")
        }
        
        guard !lastName.trimmed.isEmpty else {
            throw InventoryError.emptyField("Last name")
        }
        
        guard !company.trimmed.isEmpty else {
            throw InventoryError.emptyField("Company")
        }
        
        guard !platoon.trimmed.isEmpty else {
            throw InventoryError.emptyField("Platoon")
        }
        
        guard !squad.trimmed.isEmpty else {
            throw InventoryError.emptyField("Squad")
        }
        
        guard !team.trimmed.isEmpty else {
            throw InventoryError.emptyField("Team")
        }
        
        guard !position.trimmed.isEmpty else {
            throw InventoryError.emptyField("Position")
        }
        
        guard var user = currentUser else {
            return
        }
        
        user.soldierInformation = UserSoldierInformation(
            rank: rank.trimmed.uppercased(),
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            company: company.trimmed,
            platoon: platoon.trimmed,
            squad: squad.trimmed,
            team: team.trimmed,
            position: position.trimmed
        )
        
        user.role = role
        currentUser = user
        
        syncCurrentUserToPersonnelRoster()
        saveData()
    }
    
    private func syncCurrentUserToPersonnelRoster() {
        guard var user = currentUser else {
            return
        }
        
        let soldierInfo = user.soldierInformation
        
        let syncedSoldier = Soldier(
            id: user.linkedSoldierID ?? UUID(),
            rank: soldierInfo.rank,
            firstName: soldierInfo.firstName,
            lastName: soldierInfo.lastName,
            company: soldierInfo.company,
            platoon: soldierInfo.platoon,
            squad: soldierInfo.squad,
            team: soldierInfo.team,
            position: soldierInfo.position,
            role: user.role
        )
        
        if let linkedSoldierID = user.linkedSoldierID,
           let index = soldiers.firstIndex(where: { $0.id == linkedSoldierID }) {
            soldiers[index] = syncedSoldier
        } else {
            soldiers.append(syncedSoldier)
            user.linkedSoldierID = syncedSoldier.id
            currentUser = user
        }
    }
    
    func addSoldier(
        rank: String,
        firstName: String,
        lastName: String,
        company: String,
        platoon: String,
        squad: String,
        team: String,
        position: String,
        role: UserRole = .soldier
    ) throws {
        guard currentUser?.role.canEditPersonnel == true else {
            throw InventoryError.unauthorized
        }
        
        guard !rank.trimmed.isEmpty else {
            throw InventoryError.emptyField("Rank")
        }
        
        guard !firstName.trimmed.isEmpty else {
            throw InventoryError.emptyField("First name")
        }
        guard !lastName.trimmed.isEmpty else {
            throw InventoryError.emptyField("Last name")
        }
        
        guard !company.trimmed.isEmpty else {
            throw InventoryError.emptyField("Company")
        }
        
        guard !platoon.trimmed.isEmpty else {
            throw InventoryError.emptyField("Platoon")
        }
        
        guard !squad.trimmed.isEmpty else {
            throw InventoryError.emptyField("Squad")
        }
        
        guard !team.trimmed.isEmpty else {
            throw InventoryError.emptyField("Team")
        }
        
        guard !position.trimmed.isEmpty else {
            throw InventoryError.emptyField("Position")
        }
        let soldier = Soldier(
            id: UUID(),
            rank: rank.trimmed.uppercased(),
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            company: company.trimmed,
            platoon: platoon.trimmed,
            squad: squad.trimmed,
            team: team.trimmed,
            position: position.trimmed,
            role: role
        )
        
        soldiers.append(soldier)
        saveData()
    }
    
    func addItem(
        itemName: String,
        serialNumber: String,
        category: ItemCategory,
        condition: ItemCondition,
        notes: String,
        quantity: Int? = nil
    ) throws {
        guard currentUser?.role.canManageSI == true else {
            throw InventoryError.unauthorized
        }
        
        guard !itemName.trimmed.isEmpty else {
            throw InventoryError.emptyField("Item name")
        }
        
        if category == .other {
            guard let quantity, quantity > 0 else {
                throw InventoryError.emptyField("Quantity")
            }
        } else {
            guard !serialNumber.trimmed.isEmpty else {
                throw InventoryError.emptyField("Serial number")
            }
        }
        
        let cleanSerial = serialNumber.trimmed.uppercased()
        
        if category != .other {
            guard !items.contains(where: { $0.serialNumber.uppercased() == cleanSerial }) else {
                throw InventoryError.duplicateSerial
            }
        }
        
        let item = InventoryItem(
            id: UUID(),
            itemName: itemName.trimmed,
            serialNumber: category == .other ? "N/A" : cleanSerial,
            category: category,
            status: .unassigned,
            assignedSoldierID: nil,
            condition: condition,
            issueDate: nil,
            notes: notes.trimmed,
            quantity: category == .other ? quantity : nil
        )
        
        items.append(item)
        saveData()
    }
    
    func issueItem(
        itemID: UUID,
        soldierID: UUID,
        condition: ItemCondition,
        notes: String,
        date: Date = Date()
    ) throws {
        guard currentUser?.role.canManageSI == true else {
            throw InventoryError.unauthorized
        }
        
        guard let itemIndex = items.firstIndex(where: { $0.id == itemID }) else {
            throw InventoryError.missingItem
        }
        
        guard soldiers.contains(where: { $0.id == soldierID }) else {
            throw InventoryError.missingSoldier
        }
        
        guard items[itemIndex].assignedSoldierID == nil && items[itemIndex].status == .unassigned else {
            throw InventoryError.itemAlreadyAssigned
        }
        
        items[itemIndex].assignedSoldierID = soldierID
        items[itemIndex].status = .assigned
        items[itemIndex].condition = condition
        items[itemIndex].issueDate = Date()
        
        let transaction = TransactionRecord(
            id: UUID(),
            type: .issue,
            itemID: itemID,
            soldierID: soldierID,
            date: Date(),
            condition: condition,
            notes: notes.trimmed
        )
        
        transactions.append(transaction)
        saveData()
    }
    
    func turnInItem(
        itemID: UUID,
        condition: ItemCondition,
        notes: String,
        date: Date = Date()
    ) throws {
        guard currentUser?.role.canManageSI == true else {
            throw InventoryError.unauthorized
        }
        
        guard let itemIndex = items.firstIndex(where: { $0.id == itemID }) else {
            throw InventoryError.missingItem
        }
        
        guard let previousSoldierID = items[itemIndex].assignedSoldierID else {
            throw InventoryError.itemNotAssigned
        }
        
        items[itemIndex].assignedSoldierID = nil
        items[itemIndex].status = .unassigned
        items[itemIndex].condition = condition
        items[itemIndex].issueDate = nil
        
        let transaction = TransactionRecord(
            id: UUID(),
            type: .turnIn,
            itemID: itemID,
            soldierID: previousSoldierID,
            date: Date(),
            condition: condition,
            notes: notes.trimmed
        )
        
        transactions.append(transaction)
        saveData()
    }
    
    func updateItemStatus(
        itemID: UUID,
        status: ItemStatus,
        notes: String
    ) throws {
        guard currentUser?.role.canManageSI == true else {
            throw InventoryError.unauthorized
        }
        
        guard let itemIndex = items.firstIndex(where: { $0.id == itemID }) else {
            throw InventoryError.missingItem
        }
        
        items[itemIndex].status = status
        
        if status == .damaged {
            items[itemIndex].condition = .damaged
        }
        
        let transaction = TransactionRecord(
            id: UUID(),
            type: .statusChange,
            itemID: itemID,
            soldierID: items[itemIndex].assignedSoldierID,
            date: Date(),
            condition: items[itemIndex].condition,
            notes: notes.trimmed
        )
        
        transactions.append(transaction)
        saveData()
    }
    
    private func loadData() {
        if let savedData = storage.load() {
            soldiers = savedData.soldiers
            items = savedData.items
            transactions = savedData.transactions
            currentUser = savedData.currentUser
        } else {
            loadSampleData()
            saveData()
        }
    }
    
    private func saveData() {
        let data = SavedInventoryData(
            soldiers: soldiers,
            items: items,
            transactions: transactions,
            currentUser: currentUser
        )
        
        try? storage.save(data)
    }
    
    private func loadSampleData() {
        let soldierOne = Soldier(
            id: UUID(),
            rank: "SGT",
            firstName: "Avery",
            lastName: "Johnson",
            company: "A CO",
            platoon: "1st PLT",
            squad: "1st Squad",
            team: "Alpha Team",
            position: "Team Leader",
            role: .teamLeader
        )
        
        let soldierTwo = Soldier(
            id: UUID(),
            rank: "SPC",
            firstName: "Mason",
            lastName: "Rivera",
            company: "A CO",
            platoon: "1st PLT",
            squad: "2nd Squad",
            team: "Bravo Team",
            position: "Rifleman",
            role: .soldier
        )
        
        let soldierThree = Soldier(
            id: UUID(),
            rank: "PFC",
            firstName: "Jordan",
            lastName: "Lee",
            company: "A CO",
            platoon: "2nd PLT",
            squad: "Weapons Squad",
            team: "Gun Team",
            position: "Machine Gunner",
            role: .soldier
        )
        
        soldiers = [
            soldierOne,
            soldierTwo,
            soldierThree
        ]
        items = [
            InventoryItem(
                id: UUID(),
                itemName: "M4A1 Carbine",
                serialNumber: "WPN-1001",
                category: .weapon,
                status: .assigned,
                assignedSoldierID: soldierOne.id,
                condition: .serviceable,
                issueDate: Date().addingTimeInterval(-86400 * 14),
                notes: "Sample data only",
                quantity: nil
            ),
            InventoryItem(
                id: UUID(),
                itemName: "Harris AN/PRC-163",
                serialNumber: "COM-2044",
                category: .communication,
                status: .unassigned,
                assignedSoldierID: nil,
                condition: .serviceable,
                issueDate: nil,
                notes: "Sample data only",
                quantity: nil
            ),
            InventoryItem(
                id: UUID(),
                itemName: "PVS-14",
                serialNumber: "NVG-3302",
                category: .nvg,
                status: .damaged,
                assignedSoldierID: soldierTwo.id,
                condition: .damaged,
                issueDate: Date().addingTimeInterval(-86400 * 7),
                notes: "Damaged lens - sample data only",
                quantity: nil
            ),
            InventoryItem(
                id: UUID(),
                itemName: "M4A1 Magazine",
                serialNumber: "N/A",
                category: .other,
                status: .unassigned,
                assignedSoldierID: nil,
                condition: .serviceable,
                issueDate: nil,
                notes: "Non-serialized sensitive item - sample data only",
                quantity: 30
            )
        ]
        
        transactions = []
    }
    
    func currentUserSoldierInfo() -> UserSoldierInformation? {
        currentUser?.soldierInformation
    }
    
    func isCurrentUser(_ soldier: Soldier) -> Bool {
        guard let userInfo = currentUserSoldierInfo() else {
            return false
        }
        
        return soldier.firstName.lowercased() == userInfo.firstName.lowercased()
        && soldier.lastName.lowercased() == userInfo.lastName.lowercased()
        && soldier.company == userInfo.company
        && soldier.platoon == userInfo.platoon
        && soldier.squad == userInfo.squad
        && soldier.team == userInfo.team
    }
    
    func isSameCompany(_ soldier: Soldier) -> Bool {
        guard let userInfo = currentUserSoldierInfo() else {
            return false
        }
        
        return soldier.company == userInfo.company
    }
    
    func isSamePlatoon(_ soldier: Soldier) -> Bool {
        guard let userInfo = currentUserSoldierInfo() else {
            return false
        }
        
        return soldier.company == userInfo.company
        && soldier.platoon == userInfo.platoon
    }
    
    func isSameSquad(_ soldier: Soldier) -> Bool {
        guard let userInfo = currentUserSoldierInfo() else {
            return false
        }
        
        return soldier.company == userInfo.company
        && soldier.platoon == userInfo.platoon
        && soldier.squad == userInfo.squad
    }
    
    func isSameTeam(_ soldier: Soldier) -> Bool {
        guard let userInfo = currentUserSoldierInfo() else {
            return false
        }
        
        return soldier.company == userInfo.company
        && soldier.platoon == userInfo.platoon
        && soldier.squad == userInfo.squad
        && soldier.team == userInfo.team
    }

    func canEditPersonnelRecord(_ soldier: Soldier) -> Bool {
        guard let user = currentUser else {
            return false
        }
        
        switch user.role {
        case .companyOfficer, .companyNCO:
            return true
            
        case .platoonOfficer, .platoonNCO:
            return isSamePlatoon(soldier)
            
        case .squadLeader:
            return isSameSquad(soldier)
            
        case .teamLeader:
            return isSameTeam(soldier)
            
        case .companyArmorer, .platoonArmorer, .soldier:
            return false
        }
    }

    func canManageAssignedItems(for soldier: Soldier) -> Bool {
        guard let user = currentUser else {
            return false
        }
        
        switch user.role {
        case .companyOfficer, .companyNCO:
            return true
            
        case .platoonOfficer, .platoonNCO:
            return isSamePlatoon(soldier)
            
        case .squadLeader:
            return isSameSquad(soldier)
            
        case .teamLeader:
            return isSameTeam(soldier)
            
        case .companyArmorer:
            return isSameCompany(soldier)
            
        case .platoonArmorer:
            return isSamePlatoon(soldier)
            
        case .soldier:
            return isCurrentUser(soldier)
        }
    }
    
    func visibleItemsForCurrentUser() -> [InventoryItem] {
        guard let user = currentUser else {
            return []
        }
        
        switch user.role {
        case .companyOfficer, .companyNCO, .companyArmorer:
            return items.filter { item in
                guard let soldier = soldier(for: item.assignedSoldierID) else {
                    return true
                }
                
                return isSameCompany(soldier)
            }
            
        case .platoonOfficer, .platoonNCO, .platoonArmorer:
            return items.filter { item in
                guard let soldier = soldier(for: item.assignedSoldierID) else {
                    return false
                }
                
                return isSamePlatoon(soldier)
            }
            
        case .squadLeader:
            return items.filter { item in
                guard let soldier = soldier(for: item.assignedSoldierID) else {
                    return false
                }
                
                return isCurrentUser(soldier) || isSameSquad(soldier)
            }
            
        case .teamLeader:
            return items.filter { item in
                guard let soldier = soldier(for: item.assignedSoldierID) else {
                    return false
                }
                
                return isCurrentUser(soldier) || isSameTeam(soldier)
            }
            
        case .soldier:
            return items.filter { item in
                guard let soldier = soldier(for: item.assignedSoldierID) else {
                    return false
                }
                
                return isCurrentUser(soldier)
            }
        }
    }
    
    func filteredVisibleItems(
        searchText: String,
        status: ItemStatus?,
        category: ItemCategory?
    ) -> [InventoryItem] {
        let text = searchText.trimmed.lowercased()
        
        return visibleItemsForCurrentUser()
            .filter {
                text.isEmpty || $0.searchableText.lowercased().contains(text)
            }
            .filter {
                status == nil || $0.status == status
            }
            .filter {
                category == nil || $0.category == category
            }
            .sorted {
                $0.itemName < $1.itemName
            }
    }
    
    func updateSoldier(
        soldierID: UUID,
        rank: String,
        firstName: String,
        lastName: String,
        company: String,
        platoon: String,
        squad: String,
        team: String,
        position: String,
        role: UserRole
    ) throws {
        guard let index = soldiers.firstIndex(where: { $0.id == soldierID }) else {
            throw InventoryError.missingSoldier
        }
        
        let existingSoldier = soldiers[index]
        
        guard canEditPersonnelRecord(existingSoldier) else {
            throw InventoryError.unauthorized
        }
        
        guard !rank.trimmed.isEmpty else {
            throw InventoryError.emptyField("Rank")
        }
        
        guard !firstName.trimmed.isEmpty else {
            throw InventoryError.emptyField("First name")
        }
        
        guard !lastName.trimmed.isEmpty else {
            throw InventoryError.emptyField("Last name")
        }
        
        guard !company.trimmed.isEmpty else {
            throw InventoryError.emptyField("Company")
        }
        
        guard !platoon.trimmed.isEmpty else {
            throw InventoryError.emptyField("Platoon")
        }
        
        guard !squad.trimmed.isEmpty else {
            throw InventoryError.emptyField("Squad")
        }
        
        guard !team.trimmed.isEmpty else {
            throw InventoryError.emptyField("Team")
        }
        
        guard !position.trimmed.isEmpty else {
            throw InventoryError.emptyField("Position")
        }
        
        guard let currentUser = currentUser else {
            throw InventoryError.unauthorized
        }
        
        let userRankLevel = RankAuthority.level(for: currentUser.soldierInformation.rank)
        let newRankLevel = RankAuthority.level(for: rank)
        
        if userRankLevel > 0 && newRankLevel > userRankLevel {
            throw InventoryError.unauthorized
        }
        
        soldiers[index].rank = rank.trimmed.uppercased()
        soldiers[index].firstName = firstName.trimmed
        soldiers[index].lastName = lastName.trimmed
        soldiers[index].company = company.trimmed
        soldiers[index].platoon = platoon.trimmed
        soldiers[index].squad = squad.trimmed
        soldiers[index].team = team.trimmed
        soldiers[index].position = position.trimmed
        soldiers[index].role = role
        
        saveData()
    }
}
