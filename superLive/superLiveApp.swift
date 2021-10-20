//
//  superLiveApp.swift
//  superLive
//
//  Created by Alexis Ponce on 10/20/21.
//

import SwiftUI

@main
struct superLiveApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
