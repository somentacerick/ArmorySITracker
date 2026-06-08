//
//  RootViews.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI
import SwiftData


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
                
                Button("Login") {
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
            
            Divider()
            
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
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.thinMaterial)
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
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                
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
        .navigationBarTitleDisplayMode(.inline)
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
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct DashboardPendingTurnInCard: View {
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Pending Turn-Ins")
                    .font(.headline)
                
                Text("Items that still need to be returned or cleared.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
