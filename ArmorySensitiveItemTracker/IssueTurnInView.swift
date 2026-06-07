//
//  IssueTurnInView.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI

//Handles accountability transactions
//Allows authorized users to issue an item to a soldier or turn an assigned item back in
//Validates selections and record transaction details ie item, soldier, condition, and notes

enum TransactionMode: String, CaseIterable, Identifiable {
    case issue = "Issue"
    case turnIn = "Turn In"
    
    var id: String { rawValue }
}

struct IssueTurnInView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    @State private var mode: TransactionMode = .issue
    @State private var selectedSoldierID = ""
    @State private var selectedItemID = ""
    @State private var transactionDate = Date()
    @State private var condition: ItemCondition = .serviceable
    @State private var notes = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var issueItems: [InventoryItem] {
        viewModel.items.filter { $0.status == .unassigned }
    }
    
    private var turnInItems: [InventoryItem] {
        viewModel.items.filter { $0.assignedSoldierID != nil }
    }
    
    private var displayedItems: [InventoryItem] {
        mode == .issue ? issueItems : turnInItems
    }
    
    var body: some View {
        Form {
            Section("Transaction Type") {
                Picker("Mode", selection: $mode) {
                    ForEach(TransactionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            if mode == .issue {
                Section("Select Soldier") {
                    Picker("Soldier", selection: $selectedSoldierID) {
                        Text("Select Soldier").tag("")
                        
                        ForEach(viewModel.soldiers) { soldier in
                            Text(soldier.displayName)
                                .tag(soldier.id.uuidString)
                        }
                    }
                }
            }
            
            Section("Select Item") {
                Picker("Item", selection: $selectedItemID) {
                    Text("Select Item").tag("")
                    
                    ForEach(displayedItems) { item in
                        Text("\(item.itemName) - \(item.serialNumber)")
                            .tag(item.id.uuidString)
                    }
                }
            }
            
            if mode == .turnIn,
               let itemID = UUID(uuidString: selectedItemID),
               let item = viewModel.item(for: itemID),
               let soldier = viewModel.soldier(for: item.assignedSoldierID) {
                Section("Current Holder") {
                    Text(soldier.displayName)
                    Text(soldier.unitLine)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Transaction Details") {
                DatePicker(
                    "Date",
                    selection: $transactionDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                
                Picker("Condition", selection: $condition) {
                    ForEach(ItemCondition.allCases) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }
            
            Button(mode == .issue ? "Issue Item" : "Turn In Item") {
                submitTransaction()
            }
            .disabled(viewModel.currentUser?.role.canManageSI != true)
        }
        .navigationTitle("Issue / Turn In")
        .onChange(of: mode) {
            selectedSoldierID = ""
            selectedItemID = ""
            notes = ""
            condition = .serviceable
            transactionDate = Date()
        }
        .alert("Transaction", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func submitTransaction() {
        guard viewModel.currentUser?.role.canManageSI == true else {
            alertMessage = "Your current role does not have permission to perform this action."
            showAlert = true
            return
        }
        
        guard let itemID = UUID(uuidString: selectedItemID) else {
            alertMessage = "Please select an item."
            showAlert = true
            return
        }
        
        do {
            switch mode {
            case .issue:
                guard let soldierID = UUID(uuidString: selectedSoldierID) else {
                    alertMessage = "Please select a soldier."
                    showAlert = true
                    return
                }
                
                try viewModel.issueItem(
                    itemID: itemID,
                    soldierID: soldierID,
                    condition: condition,
                    notes: notes,
                    date: transactionDate
                )
                
            case .turnIn:
                try viewModel.turnInItem(
                    itemID: itemID,
                    condition: condition,
                    notes: notes,
                    date: transactionDate
                )
            }
            
            alertMessage = "\(mode.rawValue) completed successfully."
            showAlert = true
            
            selectedSoldierID = ""
            selectedItemID = ""
            notes = ""
            condition = .serviceable
            transactionDate = Date()
            
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
