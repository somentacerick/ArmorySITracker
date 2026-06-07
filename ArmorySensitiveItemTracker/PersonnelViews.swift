//
//  PersonnelViews.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI


//Handles the personnel roster section
//Displays soldier by rank, name, platoon, and squad/team
//Supports searching personnel, viewing soldier details, and adding new soldiers when the user role has permission

struct PersonnelRosterView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    @State private var searchText = ""
    @State private var showAddSoldier = false
    
    var body: some View {
        List {
            ForEach(viewModel.filteredSoldiers(searchText: searchText)) { soldier in
                NavigationLink {
                    SoldierDetailView(soldierID: soldier.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(soldier.displayName)
                            .font(.headline)
                        
                        Text(soldier.unitLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Personnel Roster")
        .searchable(text: $searchText, prompt: "Search personnel")
        .toolbar {
            if viewModel.currentUser?.role.canEditPersonnel == true {
                Button {
                    showAddSoldier = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSoldier) {
            NavigationStack {
                AddSoldierView()
            }
        }
    }
}

struct SoldierDetailView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    let soldierID: UUID
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        if let soldier = viewModel.soldiers.first(where: { $0.id == soldierID }) {
            List {
                Section("Soldier Information") {
                    Text(soldier.displayName)
                    Text("Company: \(soldier.company)")
                    Text("Platoon: \(soldier.platoon)")
                    Text("Squad: \(soldier.squad)")
                    Text("Team: \(soldier.team)")
                }
                
                Section("Assigned Equipment") {
                    let assignedItems = viewModel.items(for: soldier.id)
                    
                    if assignedItems.isEmpty {
                        Text("No assigned equipment.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(assignedItems) { item in
                            NavigationLink {
                                ItemDetailView(itemID: item.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.itemName)
                                        .font(.headline)
                                    
                                    Text("Serial: \(item.serialNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    if let issueDate = item.issueDate {
                                        Text("Issued: \(issueDate.shortDisplay)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Text("Status: \(item.status.rawValue)")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                if viewModel.currentUser?.role.canManageSI == true {
                    Section("Actions") {
                        NavigationLink("Assign Item") {
                            IssueTurnInView()
                        }
                        
                        NavigationLink("Turn In Item") {
                            IssueTurnInView()
                        }
                    }
                }
            }
            .navigationTitle(soldier.lastName)
            .alert("Personnel Action", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        } else {
            ContentUnavailableView(
                "Soldier Not Found",
                systemImage: "person.crop.circle.badge.questionmark"
            )
        }
    }
}

struct AddSoldierView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var rank = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var platoon = ""
    @State private var squad = ""
    @State private var team = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Soldier Information") {
                TextField("Rank", text: $rank)
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }
            
            Section("Unit Information") {
                TextField("Company", text: $company)
                TextField("Platoon", text: $platoon)
                TextField("Squad", text: $squad)
                TextField("Team", text: $team)
            }
            
            Button("Save Soldier") {
                do {
                    try viewModel.addSoldier(
                        rank: rank,
                        firstName: firstName,
                        lastName: lastName,
                        company: company,
                        platoon: platoon,
                        squad: squad,
                        team: team
                    )
                    
                    dismiss()
                } catch {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
        .navigationTitle("Add Soldier")
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
