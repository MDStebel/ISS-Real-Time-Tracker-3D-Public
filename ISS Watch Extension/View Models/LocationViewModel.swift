//
//  LocationViewModel.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 6/16/24.
//  Updated by Michael on 8/8/2025.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import CoreLocation
import Foundation
import Observation

@Observable
final class LocationViewModel {
    
    var authorizationStatus: CLAuthorizationStatus
    var latitude: Double  = 0.0
    var longitude: Double = 0.0
    
    private let locationManager: LocationManager

    init() {
        let manager = LocationManager()
        self.locationManager = manager
        self.authorizationStatus = manager.authorizationStatus

        Task {
            for await location in manager.locationStream() {
                if let coordinate = location?.coordinate {
                    await MainActor.run {
                        self.latitude = coordinate.latitude
                        self.longitude = coordinate.longitude
                    }
                }
            }
        }

        Task {
            for await status in manager.authorizationStatusStream() {
                await MainActor.run {
                    self.authorizationStatus = status
                }
            }
        }
    }
}
