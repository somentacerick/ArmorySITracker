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
        FileManager.default.urls(for: .documentDirectory, in: .userDomain)[0].appendingPathComponent(fileName)
    }
    
    func load() -> SavedInventoryData> {
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
final class InvtoryViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var soldiers: [Soldier] = []
    @Published var items: [InventoryItem] = []
    @Published var transactions: [TransactionRecord] = []
    
    private let storage = InventoryStorage()
    
    init() {
        loadData()
    }
    
}

