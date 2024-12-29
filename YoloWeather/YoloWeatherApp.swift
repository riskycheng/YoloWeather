//
//  YoloWeatherApp.swift
//  YoloWeather
//
//  Created by Jian Cheng on 2024/12/28.
//

import SwiftUI

@main
struct YoloWeatherApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
