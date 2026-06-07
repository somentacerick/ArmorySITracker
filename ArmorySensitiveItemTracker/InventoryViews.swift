//
//  InventoryViews.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI


//Handles the company inventory section
//Displays all sensitive inv items, allows searching by serial num/name, filters by status/category, shows item details, adds new items, and supports actions like marking items missing or damaged

struct CompanyInventoryView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    @State private var searchText = ""
    @State private var selectedStatus = "All"
    @State private var selectedCategory = "All"
    @State private var showAddItem = false
    
    private var statusFilter: ItemStatus? {
        ItemStatus.allCases.first { $0.rawValue == selectedStatus }
    }
    
    private var categoryFilter: ItemCategory? {
        ItemCategory.allCases.first { $0.rawValue == selectedCategory }
    }
    
    var body: some View {
        List {
            Section("Filters") {
                Picker("Status", selection: $selectedStatus) {
                    Text("All").tag("All")
                    
                    ForEach(ItemStatus.allCases) { status in
                        Text(status.rawValue).tag(status.rawValue)
                    }
                }
                
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag("All")
                    
                    ForEach(ItemCategory.allCases) { category in
                        Text(category.rawValue).tag(category.rawValue)
                    }
                }
            }
            
            Section("Inventory Items") {
                let filteredItems = viewModel.filteredItems(
                    searchText: searchText,
                    status: statusFilter,
                    category: categoryFilter
                )
                
                if filteredItems.isEmpty {
                    Text("No inventory items found.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            ItemDetailView(itemID: item.id)
                        } label: {
                            ItemRowView(
                                item: item,
                                assignedSoldier: viewModel.soldier(for: item.assignedSoldierID)
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Company Inventory")
        .searchable(text: $searchText, prompt: "Search serial number or item")
        .toolbar {
            if viewModel.currentUser?.role.canManageSI == true {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddItemView()
            }
        }
    }
}

struct ItemRowView: View {
    let item: InventoryItem
    let assignedSoldier: Soldier?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.itemName)
                .font(.headline)
            
            Text("Serial: \(item.serialNumber)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Category: \(item.category.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let assignedSoldier {
                Text("Assigned To: \(assignedSoldier.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Assigned To: Unassigned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Status: \(item.status.rawValue)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(item.condition.rawValue)
                    .font(.caption)
            }
        }
    }
}

struct ItemDetailView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    let itemID: UUID
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        if let item = viewModel.item(for: itemID) {
            List {
                Section("Item Information") {
                    Text("Item: \(item.itemName)")
                    Text("Serial Number: \(item.serialNumber)")
                    Text("Category: \(item.category.rawValue)")
                    Text("Status: \(item.status.rawValue)")
                    Text("Condition: \(item.condition.rawValue)")
                }
                
                Section("Current Holder") {
                    if let soldier = viewModel.soldier(for: item.assignedSoldierID) {
                        Text(soldier.displayName)
                        Text(soldier.unitLine)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Unassigned")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Issue Date") {
                    if let issueDate = item.issueDate {
                        Text(issueDate.shortDisplay)
                    } else {
                        Text("Not issued")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    if item.notes.isEmpty {
                        Text("No notes.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(item.notes)
                    }
                }
                
                Section("History Log") {
                    let itemTransactions = viewModel.transactions
                        .filter { $0.itemID == item.id }
                        .sorted { $0.date > $1.date }
                    
                    if itemTransactions.isEmpty {
                        Text("No transaction history.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(itemTransactions) { transaction in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transaction.type.rawValue)
                                    .font(.headline)
                                
                                Text(transaction.date.shortDisplay)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if let soldier = viewModel.soldier(for: transaction.soldierID) {
                                    Text("Soldier: \(soldier.displayName)")
                                        .font(.caption)
                                }
                                
                                Text("Condition: \(transaction.condition.rawValue)")
                                    .font(.caption)
                                
                                if !transaction.notes.isEmpty {
                                    Text("Notes: \(transaction.notes)")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                if viewModel.currentUser?.role.canManageSI == true {
                    Section("Actions") {
                        Button("Mark Missing") {
                            runAction {
                                try viewModel.updateItemStatus(
                                    itemID: item.id,
                                    status: .missing,
                                    notes: "Marked missing from item detail screen."
                                )
                            }
                        }
                        
                        Button("Mark Damaged") {
                            runAction {
                                try viewModel.updateItemStatus(
                                    itemID: item.id,
                                    status: .damaged,
                                    notes: "Marked damaged from item detail screen."
                                )
                            }
                        }
                        
                        if item.assignedSoldierID != nil {
                            Button("Turn In Item") {
                                runAction {
                                    try viewModel.turnInItem(
                                        itemID: item.id,
                                        condition: item.condition,
                                        notes: "Turned in from item detail screen."
                                    )
                                }
                            }
                        }
                        
                        NavigationLink("Assign / Turn In From Form") {
                            IssueTurnInView()
                        }
                    }
                }
            }
            .navigationTitle(item.itemName)
            .alert("Inventory Action", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        } else {
            ContentUnavailableView(
                "Item Not Found",
                systemImage: "shippingbox.circle"
            )
        }
    }
    
    private func runAction(_ action: () throws -> Void) {
        do {
            try action()
            alertMessage = "Action completed successfully."
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct AddItemView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var itemName = ""
    @State private var serialNumber = ""
    @State private var category: ItemCategory = .weapon
    @State private var condition: ItemCondition = .serviceable
    @State private var notes = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Item Information") {
                TextField("Item Name", text: $itemName)
                TextField("Serial Number", text: $serialNumber)
                
                Picker("Category", selection: $category) {
                    ForEach(ItemCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                
                Picker("Condition", selection: $condition) {
                    ForEach(ItemCondition.allCases) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
            
            Button("Save Item") {
                do {
                    try viewModel.addItem(
                        itemName: itemName,
                        serialNumber: serialNumber,
                        category: category,
                        condition: condition,
                        notes: notes
                    )
                    
                    dismiss()
                } catch {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
        .navigationTitle("Add Item")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Unable to Save", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}
