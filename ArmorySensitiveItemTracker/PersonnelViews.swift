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
                    Text("Platoon: \(soldier.platoon)")
                    Text("Squad: \(soldier.squad)")
                    Text("Team: \(soldier.team)")
                    Text("Position: \(soldier.position)")
                }
                
                if viewModel.canEditPersonnelRecord(soldier) {
                    Section("Personnel Actions") {
                        NavigationLink("Edit Personnel Information") {
                            EditSoldierView(soldierID: soldier.id)
                        }
                    }
                }
                
                if viewModel.canManageAssignedItems(for: soldier) {
                    Section("Sensitive Item Actions") {
                        NavigationLink("Issue / Turn In Items") {
                            IssueTurnInView()
                        }
                    }
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
    @State private var platoon = ""
    @State private var squad = ""
    @State private var team = ""
    @State private var position = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var allowedRanks: [String] {
        guard let currentUser = viewModel.currentUser else {
            return ArmyProfileOptions.allRanks
        }
        
        return RankAuthority.allowedRanks(
            upTo: currentUser.soldierInformation.rank
        )
    }
    
    var body: some View {
        Form {
            Section("Soldier Information") {
                Picker("Rank", selection: $rank) {
                    Text("Select Rank").tag("")
                    
                    ForEach(allowedRanks, id: \.self) { rank in
                        Text(rank).tag(rank)
                    }
                }
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }
            
            Section("Unit Information") {
                
                Picker("Platoon", selection: $platoon) {
                    Text("Select Platoon").tag("")
                    
                    ForEach(ArmyProfileOptions.platoons, id: \.self) { platoon in
                        Text(platoon).tag(platoon)
                    }
                }
                
                Picker("Squad", selection: $squad) {
                    Text("Select Squad").tag("")
                    
                    ForEach(ArmyProfileOptions.squads, id: \.self) { squad in
                        Text(squad).tag(squad)
                    }
                }
                
                Picker("Team", selection: $team) {
                    Text("Select Team").tag("")
                    
                    ForEach(ArmyProfileOptions.teams, id: \.self) { team in
                        Text(team).tag(team)
                    }
                }
                
                Picker("Position", selection: $position) {
                    Text("Select Position").tag("")
                    
                    ForEach(ArmyProfileOptions.positions, id: \.self) { position in
                        Text(position).tag(position)
                    }
                }
            }
            
            Button("Save Soldier") {
                do {
                    try viewModel.addSoldier(
                        rank: rank,
                        firstName: firstName,
                        lastName: lastName,
                        platoon: platoon,
                        squad: squad,
                        team: team,
                        position: position
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

struct EditSoldierView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    let soldierID: UUID
    
    @State private var rank = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var platoon = ""
    @State private var squad = ""
    @State private var team = ""
    @State private var position = ""
    @State private var selectedRole: UserRole = .soldier
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var allowedRanks: [String] {
        guard let currentUser = viewModel.currentUser else {
            return ArmyProfileOptions.allRanks
        }
        
        return RankAuthority.allowedRanks(
            upTo: currentUser.soldierInformation.rank
        )
    }
    
    var body: some View {
        Form {
            Section("Soldier Information") {
                Picker("Rank", selection: $rank) {
                    Text("Select Rank").tag("")
                    
                    ForEach(allowedRanks, id: \.self) { rank in
                        Text(rank).tag(rank)
                    }
                }
                
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }
            
            Section("Unit Information") {
                
                Picker("Platoon", selection: $platoon) {
                    ForEach(ArmyProfileOptions.platoons, id: \.self) {
                        Text($0).tag($0)
                    }
                }
                
                Picker("Squad", selection: $squad) {
                    ForEach(ArmyProfileOptions.squads, id: \.self) {
                        Text($0).tag($0)
                    }
                }
                
                Picker("Team", selection: $team) {
                    ForEach(ArmyProfileOptions.teams, id: \.self) {
                        Text($0).tag($0)
                    }
                }
                
                Picker("Position", selection: $position) {
                    ForEach(ArmyProfileOptions.positions, id: \.self) {
                        Text($0).tag($0)
                    }
                }
            }
            
            Section("Role / Permission") {
                Picker("Role", selection: $selectedRole) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
            }
            
            Button("Save Changes") {
                saveChanges()
            }
        }
        .navigationTitle("Edit Soldier")
        .onAppear {
            loadSoldier()
        }
        .alert("Unable to Save", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadSoldier() {
        guard let soldier = viewModel.soldiers.first(where: { $0.id == soldierID }) else {
            return
        }
        
        rank = soldier.rank
        firstName = soldier.firstName
        lastName = soldier.lastName
        platoon = soldier.platoon
        squad = soldier.squad
        team = soldier.team
        position = soldier.position
        selectedRole = soldier.role
    }
    
    private func saveChanges() {
        do {
            try viewModel.updateSoldier(
                soldierID: soldierID,
                rank: rank,
                firstName: firstName,
                lastName: lastName,
                platoon: platoon,
                squad: squad,
                team: team,
                position: position,
                role: selectedRole
            )
            
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
