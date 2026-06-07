//
//  ReportsView.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI

//Displays inventory accountability summaries
//Shows total items, assigned items, unassigned items, missing/damaged items, by soldier accountability counts, and recent transaction history


struct ReportsView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    @State private var generatedSummary = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section("Inventory Check") {
                Button("Run Inventory Check") {
                    generatedSummary = buildReportSummary()
                    alertMessage = "Inventory check completed successfully."
                    showAlert = true
                }
                
                if !generatedSummary.isEmpty {
                    ShareLink(
                        item: generatedSummary,
                        subject: Text("Armory Inventory Summary"),
                        message: Text("Inventory accountability report")
                    ) {
                        Label("Export / Share Summary", systemImage: "square.and.arrow.up")
                    }
                }
            }
            
            Section("Accountability Summary") {
                ReportRow(title: "Total Items", value: "\(viewModel.items.count)")
                ReportRow(title: "Assigned Items", value: "\(viewModel.assignedItems.count)")
                ReportRow(title: "Unassigned Items", value: "\(viewModel.unassignedItems.count)")
                ReportRow(title: "Missing/Damaged Items", value: "\(viewModel.missingOrDamagedItems.count)")
                ReportRow(title: "Pending Turn-Ins", value: "\(viewModel.pendingTurnInItems.count)")
            }
            
            Section("Assigned Items") {
                if viewModel.assignedItems.isEmpty {
                    Text("No assigned items.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.assignedItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemName)
                                .font(.headline)
                            
                            Text("Serial: \(item.serialNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let soldier = viewModel.soldier(for: item.assignedSoldierID) {
                                Text("Assigned To: \(soldier.displayName)")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            Section("Unassigned Items") {
                if viewModel.unassignedItems.isEmpty {
                    Text("No unassigned items.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.unassignedItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemName)
                                .font(.headline)
                            
                            Text("Serial: \(item.serialNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Missing / Damaged Items") {
                if viewModel.missingOrDamagedItems.isEmpty {
                    Text("No missing or damaged items.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.missingOrDamagedItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemName)
                                .font(.headline)
                            
                            Text("Serial: \(item.serialNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("Status: \(item.status.rawValue)")
                                .font(.caption)
                            
                            Text("Condition: \(item.condition.rawValue)")
                                .font(.caption)
                        }
                    }
                }
            }
            
            Section("By Soldier") {
                ForEach(viewModel.soldiers) { soldier in
                    let assignedCount = viewModel.items(for: soldier.id).count
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(soldier.displayName)
                                .font(.headline)
                            
                            Text(soldier.unitLine)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(assignedCount)")
                            .fontWeight(.bold)
                    }
                }
            }
            
            Section("Recent Transactions") {
                let sortedTransactions = viewModel.transactions.sorted {
                    $0.date > $1.date
                }
                
                if sortedTransactions.isEmpty {
                    Text("No transactions recorded yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
            
            if !generatedSummary.isEmpty {
                Section("Generated Summary") {
                    Text(generatedSummary)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Reports")
        .alert("Inventory Check", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func buildReportSummary() -> String {
        var summary = ""
        
        summary += "Armory Sensitive Item Inventory Summary\n"
        summary += "Generated: \(Date().shortDisplay)\n\n"
        
        summary += "Total Items: \(viewModel.items.count)\n"
        summary += "Assigned Items: \(viewModel.assignedItems.count)\n"
        summary += "Unassigned Items: \(viewModel.unassignedItems.count)\n"
        summary += "Missing/Damaged Items: \(viewModel.missingOrDamagedItems.count)\n"
        summary += "Pending Turn-Ins: \(viewModel.pendingTurnInItems.count)\n\n"
        
        summary += "By Soldier:\n"
        
        for soldier in viewModel.soldiers {
            let assignedCount = viewModel.items(for: soldier.id).count
            summary += "- \(soldier.displayName): \(assignedCount) assigned item(s)\n"
        }
        
        summary += "\nMissing / Damaged Items:\n"
        
        if viewModel.missingOrDamagedItems.isEmpty {
            summary += "None\n"
        } else {
            for item in viewModel.missingOrDamagedItems {
                summary += "- \(item.itemName), Serial: \(item.serialNumber), Status: \(item.status.rawValue)\n"
            }
        }
        
        return summary
    }
}

struct ReportRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            
            Spacer()
            
            Text(value)
                .fontWeight(.bold)
        }
    }
}

struct TransactionRow: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    let transaction: TransactionRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transaction.type.rawValue)
                .font(.headline)
            
            if let item = viewModel.item(for: transaction.itemID) {
                Text("\(item.itemName) - \(item.serialNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let soldier = viewModel.soldier(for: transaction.soldierID) {
                Text("Soldier: \(soldier.displayName)")
                    .font(.caption)
            }
            
            Text("Condition: \(transaction.condition.rawValue)")
                .font(.caption)
            
            Text(transaction.date.shortDisplay)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            if !transaction.notes.isEmpty {
                Text("Notes: \(transaction.notes)")
                    .font(.caption)
            }
        }
    }
}
