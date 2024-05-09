//
//  mapsSdkApp.swift
//  mapsSdk
//
//  Created by monscerrat gutierrez on 06/05/24.
//

import SwiftUI
import CoreData


@main
struct mapsSdkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
