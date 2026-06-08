//
//  ArmorySensitiveItemTrackerApp.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/6/26.
//

import SwiftUI
import SwiftData

//Main Entry point of app. Creates shared "InventoryViewModel" for all screens to access the same inv, pers, login, transac data
@main
struct ArmorySensitiveItemTrackerApp: App {
    @StateObject private var viewModel = InventoryViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
        }
        .modelContainer(for: AppDataStore.self)
    }
}
