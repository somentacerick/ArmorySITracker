//
//  InventoryViewModel.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import Foundation

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
    
    func login(username: String, password: String, role: UserRole) throws {
        guard !username.trimmed.isEmpty else {
            throw InventoryError.emptyField("Username")
        }
        
        guard !password.trimmed.isEmpty else {
            throw InventoryError.emptyField("Password")
        }
        
        currentUser = AppUser(
            username: username.trimmed,
            role: role
        )
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
    
    func addSoldier(
        rank: String,
        firstName: String,
        lastName: String,
        company: String,
        platoon: String,
        squad: String,
        team: String
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
        
        let soldier = Soldier(
            id: UUID(),
            rank: rank.trimmed.uppercased(),
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            company: company.trimmed,
            platoon: platoon.trimmed,
            squad: squad.trimmed,
            team: team.trimmed
        )
        
        soldiers.append(soldier)
        saveData()
    }
    
    func addItem(
        itemName: String,
        serialNumber: String,
        category: ItemCategory,
        condition: ItemCondition,
        notes: String
    ) throws {
        guard currentUser?.role.canManageSI == true else {
            throw InventoryError.unauthorized
        }
        
        guard !itemName.trimmed.isEmpty else {
            throw InventoryError.emptyField("Item name")
        }
        
        guard !serialNumber.trimmed.isEmpty else {
            throw InventoryError.emptyField("Serial number")
        }
        
        let cleanSerial = serialNumber.trimmed.uppercased()
        
        guard !items.contains(where: { $0.serialNumber.uppercased() == cleanSerial }) else {
            throw InventoryError.duplicateSerial
        }
        
        let item = InventoryItem(
            id: UUID(),
            itemName: itemName.trimmed,
            serialNumber: cleanSerial,
            category: category,
            status: .unassigned,
            assignedSoldierID: nil,
            condition: condition,
            issueDate: nil,
            notes: notes.trimmed
        )
        
        items.append(item)
        saveData()
    }
    
    func issueItem(
        itemID: UUID,
        soldierID: UUID,
        condition: ItemCondition,
        notes: String
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
        notes: String
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
            } else {
                loadSampleData()
                saveData()
            }
        }
        
        private func saveData() {
            let data = SavedInventoryData(
                soldiers: soldiers,
                items: items,
                transactions: transactions
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
            team: "Alpha Team"
        )
        
        let soldierTwo = Soldier(
            id: UUID(),
            rank: "SPC",
            firstName: "Mason",
            lastName: "Rivera",
            company: "A CO",
            platoon: "1st PLT",
            squad: "2nd Squad",
            team: "Bravo Team"
        )
        
        let soldierThree = Soldier(
            id: UUID(),
            rank: "PFC",
            firstName: "Jordan",
            lastName: "Lee",
            company: "A CO",
            platoon: "2nd PLT",
            squad: "Weapons Squad",
            team: "Gun Team"
        )
        
        soldiers = [
            soldierOne,
            soldierTwo,
            soldierThree
        ]
        items = [
            InventoryItem(
                id: UUID(),
                itemName: "Training Rifle",
                serialNumber: "WPN-1001",
                category: .weapon,
                status: .assigned,
                assignedSoldierID: soldierOne.id,
                condition: .serviceable,
                issueDate: Date().addingTimeInterval(-86400 * 14),
                notes: "Sample data only"
            ),
            InventoryItem(
                id: UUID(),
                itemName: "Radio",
                serialNumber: "COM-2044",
                category: .communication,
                status: .unassigned,
                assignedSoldierID: nil,
                condition: .serviceable,
                issueDate: nil,
                notes: "Sample data only"
            ),
            InventoryItem(
                id: UUID(),
                itemName: "Night Vision Goggles",
                serialNumber: "NVG-3302",
                category: .nvg,
                status: .damaged,
                assignedSoldierID: soldierTwo.id,
                condition: .damaged,
                issueDate: Date().addingTimeInterval(-86400 * 7),
                notes: "Damaged lens - sample data only"
            )
        ]
        
        transactions = []
    }
}
