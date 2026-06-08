//
//  ArmyTheme.swift
//  ArmorySensitiveItemTracker
//
//  Created by Erick Somentac on 6/8/26.
//

import SwiftUI

struct ArmyTheme {
    static let olive = Color(red: 0.28, green: 0.32, blue: 0.19)
    static let darkOlive = Color(red: 0.16, green: 0.19, blue: 0.11)
    static let fieldGreen = Color(red: 0.36, green: 0.43, blue: 0.24)
    static let tan = Color(red: 0.72, green: 0.64, blue: 0.48)
    static let sand = Color(red: 0.88, green: 0.82, blue: 0.68)
    static let darkText = Color(red: 0.10, green: 0.10, blue: 0.08)
    static let warning = Color(red: 0.55, green: 0.18, blue: 0.12)
}

struct ArmyCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ArmyTheme.sand.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CenteredArmyTitleModifier: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(ArmyTheme.sand)
                }
            }
            .toolbarBackground(ArmyTheme.olive, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func armyCardStyle() -> some View {
        modifier(ArmyCardBackground())
    }
    
    func centeredArmyTitle(_ title: String) -> some View {
        modifier(CenteredArmyTitleModifier(title: title))
    }
}
