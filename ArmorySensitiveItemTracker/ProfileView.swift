//
//  ProfileView.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI

// Allows the logged in user to view and update their profile.
// The profile includes username, password, rank, first name,
// last name, and role. The selected role controls what tabs
// and actions the user can access in the app.

struct ProfileView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    @State private var username = ""
    @State private var password = ""
    
    @State private var rank = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var platoon = ""
    @State private var squad = ""
    @State private var team = ""
    
    @State private var selectedRole: UserRole = .companyOfficer
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Account Login Information") {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                
                SecureField("Password", text: $password)
                
                Button("Save Login Information") {
                    saveLoginInformation()
                }
            }
            
            Section("Soldier Information") {
                Picker("Rank", selection: $rank) {
                    Text("Select Rank").tag("")
                    
                    ForEach(ArmyProfileOptions.allRanks, id: \.self) { rank in
                        Text(rank).tag(rank)
                    }
                }
                
                TextField("First Name", text: $firstName)
                
                TextField("Last Name", text: $lastName)
            }
            
            Section("Unit Information") {
                Picker("Company", selection: $company) {
                    Text("Select Company").tag("")
                    
                    ForEach(ArmyProfileOptions.companies, id: \.self) { company in
                        Text(company).tag(company)
                    }
                }
                
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
            }
            
            Section("App Role / Permissions") {
                Picker("Role", selection: $selectedRole) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                
                Button("Save Soldier Information") {
                    saveSoldierInformation()
                }
            }
            
            Section("Current Profile Display") {
                Text(profilePreview)
                    .font(.headline)
                
                Text(unitPreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(selectedRole.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            loadCurrentUser()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var profilePreview: String {
        let cleanRank = rank.trimmed.uppercased()
        let cleanLast = lastName.trimmed
        let cleanFirst = firstName.trimmed
        
        if cleanRank.isEmpty || cleanLast.isEmpty || cleanFirst.isEmpty {
            return "Complete Profile"
        }
        
        return "\(cleanRank) \(cleanLast), \(cleanFirst)"
    }
    
    private var unitPreview: String {
        let parts = [company, platoon, squad, team].filter {
            !$0.trimmed.isEmpty
        }
        
        if parts.isEmpty {
            return "Unit information not set"
        }
        
        return parts.joined(separator: " • ")
    }
    
    private func loadCurrentUser() {
        guard let user = viewModel.currentUser else {
            return
        }
        
        username = user.loginInformation.username
        password = user.loginInformation.password
        
        rank = user.soldierInformation.rank
        firstName = user.soldierInformation.firstName
        lastName = user.soldierInformation.lastName
        company = user.soldierInformation.company
        platoon = user.soldierInformation.platoon
        squad = user.soldierInformation.squad
        team = user.soldierInformation.team
        
        selectedRole = user.role
    }
    
    private func saveLoginInformation() {
        do {
            try viewModel.updateLoginInformation(
                username: username,
                password: password
            )
            
            alertTitle = "Login Saved"
            alertMessage = "Your login information was updated successfully."
            showAlert = true
            
        } catch {
            alertTitle = "Unable to Save"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func saveSoldierInformation() {
        do {
            try viewModel.updateSoldierProfileInformation(
                rank: rank,
                firstName: firstName,
                lastName: lastName,
                company: company,
                platoon: platoon,
                squad: squad,
                team: team,
                role: selectedRole
            )
            
            alertTitle = "Profile Saved"
            alertMessage = "Your soldier information was updated successfully."
            showAlert = true
            
        } catch {
            alertTitle = "Unable to Save"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
