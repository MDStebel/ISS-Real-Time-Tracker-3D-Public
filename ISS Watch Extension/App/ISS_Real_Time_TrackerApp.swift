//
//  ISS_Real_Time_TrackerApp.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 8/26/21.
//  Updated by Michael on 8/8/2025.
//  Copyright © 2021-2025 ISS Real-Time Tracker. All rights reserved.
//

import SwiftUI

@main
struct ISS_Real_Time_TrackerApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            GlobeView()
        }
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
