//
//  RootViews.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI


//Controls app floww
//Decides whether the user sees the login screen or the main app tabs
//Contains login screen, role-based dashboard, dashboard summary cards, navigation links, and logout action

struct RootView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    var body: some View {
        if viewModel.currentUser == nil {
            LoginView()
        } else {
            MainTabView()
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    @State private var username = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .companyLeadership
    @State private var useFaceID = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Login") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                    
                    SecureField("Password", text: $password)
                    
                    Toggle("Use Face ID next time", isOn: $useFaceID)
                }
                
                Section("Demo Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                }
                
                Button("Login") {
                    do {
                        try viewModel.login(
                            username: username,
                            password: password,
                            role: selectedRole
                        )
                    } catch {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
            .navigationTitle("Armory Tracker")
            .alert("Login Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            
            NavigationStack {
                PersonnelRosterView()
            }
            .tabItem {
                Label("Roster", systemImage: "person.3")
            }
            
            NavigationStack {
                CompanyInventoryView()
            }
            .tabItem {
                Label("Inventory", systemImage: "shippingbox")
            }
            
            if viewModel.currentUser?.role.canManageSI == true {
                NavigationStack {
                    IssueTurnInView()
                }
                .tabItem {
                    Label("Issue", systemImage: "arrow.left.arrow.right")
                }
            }
            
            if viewModel.currentUser?.role.canViewReports == true {
                NavigationStack {
                    ReportsView()
                }
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }
            }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    var body: some View {
        List {
            if let user = viewModel.currentUser {
                Section("Current User") {
                    Text(user.username)
                    
                    Text(user.role.rawValue)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Inventory Summary") {
                DashboardRow(
                    title: "Total Items",
                    value: "\(viewModel.items.count)",
                    systemImage: "shippingbox"
                )
                
                DashboardRow(
                    title: "Assigned",
                    value: "\(viewModel.assignedItems.count)",
                    systemImage: "checkmark.circle"
                )
                
                DashboardRow(
                    title: "Unassigned",
                    value: "\(viewModel.unassignedItems.count)",
                    systemImage: "tray"
                )
                
                DashboardRow(
                    title: "Missing/Damaged",
                    value: "\(viewModel.missingOrDamagedItems.count)",
                    systemImage: "exclamationmark.triangle"
                )
                
                DashboardRow(
                    title: "Pending Turn-Ins",
                    value: "\(viewModel.pendingTurnInItems.count)",
                    systemImage: "clock"
                )
            }
            
            Section("Navigation") {
                NavigationLink("Personnel Roster") {
                    PersonnelRosterView()
                }
                
                NavigationLink("Company Inventory") {
                    CompanyInventoryView()
                }
                
                if viewModel.currentUser?.role.canManageSI == true {
                    NavigationLink("Issue / Turn In") {
                        IssueTurnInView()
                    }
                }
                
                if viewModel.currentUser?.role.canViewReports == true {
                    NavigationLink("Reports") {
                        ReportsView()
                    }
                }
            }
            
            Section {
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                }
            }
        }
        .navigationTitle("Dashboard")
    }
}

struct DashboardRow: View {
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            
            Spacer()
            
            Text(value)
                .fontWeight(.bold)
        }
    }
}
