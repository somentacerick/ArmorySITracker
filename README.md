
# Armory Sensitive Item Tracker

## Description

Armory Sensitive Item Tracker is an iOS application designed to help manage company-level military sensitive item accountability. The app allows users to track personnel, assigned equipment, inventory items, issue/draw/turn-in transactions, item status, and accountability reports.

The app was built using SwiftUI and SwiftData. It focuses on a realistic company-level armory workflow where users can log in, manage their profile, view personnel, track sensitive items, issue equipment, draw equipment for training or operations, turn items back in, and review transaction history.

## Features

- Username and password login
- Face ID button support
- User profile management
- Soldier information tracking
- Rank, platoon, squad, team, position, and role selection
- Role-based permissions
- Unique Commander and First Sergeant roles
- Personnel roster
- Add and edit soldier records
- Soldier detail screen with assigned equipment
- Company inventory screen
- Serialized sensitive item tracking
- Non-serialized sensitive item quantity tracking
- Inventory category filtering
- Inventory status filtering
- Issue, Draw, and Turn In transactions
- Draw purpose options: Training, Field Operation, and Range
- Turn-in result options: Returned to Armory, Returned From Draw, Missing, Damaged, and Repaired
- Missing, damaged, drawn, assigned, unassigned, and maintenance statuses
- Company Armorer maintenance action
- Transaction history with performed-by tracking
- Reports and inventory check summary
- SwiftData local persistence
- Army-themed user interface

## App Screens

### Login Screen

The login screen allows users to enter their username and password. A Face ID button is included for biometric login support after a saved profile exists. The screen includes an app title image and Army-themed styling.

### Dashboard

The dashboard is the main home screen. It welcomes the logged-in user by rank, name, and role. It also displays summary cards for total items, assigned items, unassigned items, missing/damaged items, and pending turn-ins.

### Profile

The profile screen separates account login information from soldier information. Users can update their username, password, rank, name, platoon, squad, team, position, and role. Profile information is also synced to the personnel roster.

### Personnel Roster

The personnel roster displays all soldiers in the company-level roster. Authorized users can add soldiers, view soldier details, and edit personnel information depending on their role permissions.

### Soldier Detail

The soldier detail screen displays an individual soldier’s rank, name, unit information, role, and assigned sensitive items.

### Company Inventory

The inventory screen displays all sensitive items available to the user based on role permissions. Items are organized by category and status. Serialized items use serial numbers, while non-serialized items use quantity tracking.

### Item Detail

The item detail screen shows item information, current holder, condition, status, notes, and transaction history. Authorized users can mark items missing or damaged, turn items in, or send items to maintenance.

### Issue / Draw / Turn In

The transaction screen allows authorized users to issue equipment to soldiers, draw assigned items for a specific purpose, and turn items back in with a result status.

### Reports

The reports screen provides an accountability summary, assigned item list, unassigned item list, missing/damaged items, by-soldier accountability counts, and recent transactions.

## Technologies Used

- Swift
- SwiftUI
- SwiftData
- LocalAuthentication
- SF Symbols
- Xcode

## Data Persistence

The app uses SwiftData for local data storage. Personnel records, inventory items, transaction history, saved users, and current profile information are saved locally so that data remains available after the app is closed and reopened.

## Role-Based Permissions

The app includes role-based access control. Commander and First Sergeant have company-level access. Platoon leadership, squad leaders, team leaders, armorers, and soldiers have different access levels based on their role and assigned unit level.

## Project Purpose

The purpose of this project is to demonstrate a complete iOS application workflow for company-level sensitive item accountability. The app combines user authentication, personnel management, inventory tracking, transaction logging, role-based access, local storage, and reporting into one structured mobile application.
