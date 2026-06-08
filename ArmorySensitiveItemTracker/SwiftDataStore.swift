//
//  SwiftDataStore.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/7/26.
//

import Foundation
import SwiftData

//SwiftData used as a persistent storage model
//Stores the app's saved data

@Model
final class AppDataStore {
    @Attribute(.unique) var key: String
    var savedData: Data
    
    init(
        key: String = "main",
        savedData: Data = Data()
    ) {
        self.key = key
        self.savedData = savedData
    }
}
