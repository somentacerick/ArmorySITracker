//
//  RootViews.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI
import SwiftData
import LocalAuthentication

//Controls app floww
//Decides whether the user sees the login screen or the main app tabs
//Contains login screen, role-based dashboard, dashboard summary cards, navigation links, and logout action


struct RootView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if viewModel.currentUser == nil {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            viewModel.configureSwiftData(context: modelContext)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    @State private var username = ""
    @State private var password = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                ArmyTheme.sand.opacity(0.12)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 80))
                            .foregroundStyle(ArmyTheme.olive)
                        
                        Text("Armory Sensitive Item Tracker")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(ArmyTheme.darkOlive)
                        
                        Text("Company Level Accountability")
                            .font(.subheadline)
                            .foregroundStyle(ArmyTheme.darkText.opacity(0.75))
                    }
                    
                    VStack(spacing: 14) {
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(ArmyTheme.sand.opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ArmyTheme.olive.opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(ArmyTheme.sand.opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ArmyTheme.olive.opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button {
                            login()
                        } label: {
                            Text("Login")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ArmyTheme.olive)
                                .foregroundStyle(ArmyTheme.sand)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            faceIDLogin()
                        } label: {
                            Label("Face ID", systemImage: "faceid")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ArmyTheme.darkOlive)
                                .foregroundStyle(ArmyTheme.sand)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(ArmyTheme.sand.opacity(0.12))
            .centeredArmyTitle("Login")
            .alert("Login Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func faceIDUnlockSavedUser() {
        do {
            try viewModel.unlockWithSavedUser()
        } catch {
            alertMessage = "No saved profile was found. Please log in with username and password first."
            showAlert = true
        }
    }
    
    private func login() {
        do {
            try viewModel.login(
                username: username,
                password: password
            )
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func faceIDLogin() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            alertMessage = "Face ID is not available or has not been set up on this device."
            showAlert = true
            return
        }
        
        let reason = "Use Face ID to unlock the Armory Sensitive Item Tracker."
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    faceIDUnlockSavedUser()
                } else {
                    alertMessage = authenticationError?.localizedDescription ?? "Face ID authentication failed."
                    showAlert = true
                }
            }
        }
    }
}
    
enum MainAppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case roster = "Roster"
    case inventory = "Inventory"
    case issue = "Issue"
    case reports = "Reports"
    case profile = "Profile"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .dashboard:
            return "house"
        case .roster:
            return "person.3"
        case .inventory:
            return "shippingbox"
        case .issue:
            return "arrow.left.arrow.right"
        case .reports:
            return "chart.bar"
        case .profile:
            return "person.crop.circle"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: MainAppTab = .dashboard
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationStack {
                        DashboardView()
                    }
                    
                case .roster:
                    NavigationStack {
                        PersonnelRosterView()
                    }
                    
                case .inventory:
                    NavigationStack {
                        CompanyInventoryView()
                    }
                    
                case .issue:
                    NavigationStack {
                        IssueTurnInView()
                    }
                    
                case .reports:
                    NavigationStack {
                        ReportsView()
                    }
                    
                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ArmyTheme.sand.opacity(0.12))
            
            Divider()
                .background(ArmyTheme.olive)
            
            CustomBottomNavigationBar(selectedTab: $selectedTab)
        }
    }
}

struct CustomBottomNavigationBar: View {
    @Binding var selectedTab: MainAppTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainAppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(
                        selectedTab == tab ? ArmyTheme.sand : ArmyTheme.tan.opacity(0.8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(ArmyTheme.darkOlive)
    }
}
struct DashboardView: View {
    @EnvironmentObject var viewModel: InventoryViewModel
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                if let user = viewModel.currentUser {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        VStack(spacing: 6) {
                            Text("Welcome")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            Text(user.profileDisplayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text(user.role.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Tap to view or edit profile")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                
                LazyVGrid(columns: columns, spacing: 14) {
                    DashboardSummaryCube(
                        title: "Total Items",
                        value: "\(viewModel.items.count)",
                        systemImage: "shippingbox"
                    )
                    
                    DashboardSummaryCube(
                        title: "Assigned",
                        value: "\(viewModel.assignedItems.count)",
                        systemImage: "checkmark.circle"
                    )
                    
                    DashboardSummaryCube(
                        title: "Unassigned",
                        value: "\(viewModel.unassignedItems.count)",
                        systemImage: "tray"
                    )
                    
                    DashboardSummaryCube(
                        title: "Missing / Damaged",
                        value: "\(viewModel.missingOrDamagedItems.count)",
                        systemImage: "exclamationmark.triangle"
                    )
                }
                
                DashboardPendingTurnInCard(
                    value: "\(viewModel.pendingTurnInItems.count)"
                )
            }
            .padding()
        }
        .centeredArmyTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Logout", role: .destructive) {
                        viewModel.logout()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct DashboardSummaryCube: View {
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
            
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 145)
        .padding()
        .background(ArmyTheme.sand.opacity(0.35))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ArmyTheme.olive.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct DashboardPendingTurnInCard: View {
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(ArmyTheme.warning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Pending Turn Ins")
                    .font(.headline)
                    .foregroundStyle(ArmyTheme.darkOlive)
                
                Text("Items that still need to be returned or cleared.")
                    .font(.caption)
                    .foregroundStyle(ArmyTheme.darkText.opacity(0.8))
            }
            
            Spacer()
            
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(ArmyTheme.darkOlive)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ArmyTheme.tan.opacity(0.35))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ArmyTheme.olive.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

