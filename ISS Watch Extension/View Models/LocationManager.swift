//
//  LocationManager.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 6/16/24.
//  Updated by Michael on 8/8/2025.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import CoreLocation
import Foundation

final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    var location: CLLocation? = nil
    var authorizationStatus: CLAuthorizationStatus
    
    // Async stream continuations (single-subscriber model)
    private var locationContinuation: AsyncStream<CLLocation?>.Continuation?
    private var authContinuation: AsyncStream<CLAuthorizationStatus>.Continuation?
    
    private let locationManager = CLLocationManager()

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    /// Async stream of location updates. Single active subscriber is supported.
    func locationStream() -> AsyncStream<CLLocation?> {
        // Finish any existing stream before creating a new one
        locationContinuation?.finish()
        locationContinuation = nil

        return AsyncStream<CLLocation?> { continuation in
            // Keep a reference to yield updates from delegate callbacks
            self.locationContinuation = continuation
            // Yield the current value immediately if available
            if let current = self.location {
                continuation.yield(current)
            }
            continuation.onTermination = { [weak self] _ in
                self?.locationContinuation = nil
            }
        }
    }

    /// Async stream of authorization status updates. Single active subscriber is supported.
    func authorizationStatusStream() -> AsyncStream<CLAuthorizationStatus> {
        // Finish any existing stream before creating a new one
        authContinuation?.finish()
        authContinuation = nil

        return AsyncStream<CLAuthorizationStatus> { continuation in
            self.authContinuation = continuation
            // Yield the current value immediately
            continuation.yield(self.authorizationStatus)
            continuation.onTermination = { [weak self] _ in
                self?.authContinuation = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        saveLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        locationContinuation?.yield(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            self.locationManager.startUpdatingLocation()
        } else {
            self.locationManager.stopUpdatingLocation()
        }
        authContinuation?.yield(status)
    }
    
    /// Save location in app group
    /// - Parameters:
    ///   - lat: The latitude as a double
    ///   - lon: The longitude as a double
    private func saveLocation(latitude lat: Double, longitude lon: Double) {
        let sharedDefaults = UserDefaults(suiteName: Globals.appSuiteName)
        sharedDefaults?.set(lat, forKey: "latitude")
        sharedDefaults?.set(lon, forKey: "longitude")
    }
    
    deinit {
        locationContinuation?.finish()
        authContinuation?.finish()
    }
}
