//
//  BundleExtensionForVersion.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 1/20/25.
//  Copyright © 2025 Michael Stebel Consulting, LLC. All rights reserved.
//

import Foundation

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var humanReadableCopyright: String {
        infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© ISS Real-Time Tracker"
    }
}
