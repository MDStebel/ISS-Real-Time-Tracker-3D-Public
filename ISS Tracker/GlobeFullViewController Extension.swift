//
//  GlobeFullViewController Extension.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 10/27/20.
//  Copyright © 2020-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit
import SwiftUI

extension GlobeFullViewController {
    
    fileprivate func updateGlobeForPositionsOfStations() {
        DispatchQueue.main.async {
            self.updateEarthGlobeScene(in: self.fullGlobe, hubbleLatitude: self.hLat, hubbleLongitude: self.hLon, issLatitude: self.iLat, issLongitude: self.iLon, tssLatitude: self.tLat, tssLongitude: self.tLon, hubbleLastLat: &self.hubbleLastLat, issLastLat: &self.issLastLat, tssLastLat: &self.tssLastLat)
            
            self.isRunningLabel?.text = "Running"
        }
    }
    
    /// Method to get all supported satellite coordinates from the API and update the globe. Can be called by a timer.
    func earthGlobeLocateSatellites() {
        // Get the current satellite locations
        for sat: StationsAndSatellites in [.iss, .tss, .hst] {
            earthGlobeLocateSatellite(for: sat)
        }

        // Update positions of all satellites
        updateGlobeForPositionsOfStations()
    }
    
    /// Method to get current satellite coordinates from the API and update the globe.
    func earthGlobeLocateSatellite(for satellite: StationsAndSatellites) {
        let satelliteCodeNumber = satellite.satelliteNORADCode
        
        /// Make sure we can create the URL from the endpoint and parameters
        guard let endpointURL = URL(string: Constants.generalEndpointString + "\(satelliteCodeNumber)/0/0/0/1/" + "&apiKey=\(Constants.generalAPIKey)") else { return }
        
        /// Task to get JSON data from API by sending request to API endpoint, parse response for TSS data, and then display TSS position, etc.
        /// Uses a capture list to capture a weak reference to self. This should prevent a retain cycle and allow ARC to release instance and reduce memory load.
        let globeUpdateTask = URLSession.shared.dataTask(with: endpointURL) { [ weak self ] (data, response, error) in

            if let data {
                let decoder = JSONDecoder()
                
                do {
                    // Parse JSON
                    let parsedPosition = try decoder.decode(SatelliteOrbitPosition.self, from: data)
                    
                    // Background image may have been changed by user in Settings. If so, change it.
                    if Globals.globeBackgroundWasChanged {
                        DispatchQueue.main.async {
                            self?.setGlobeBackgroundImage()
                        }
                        Globals.globeBackgroundWasChanged = false
                    }
                    
                    switch satellite {
                    case .iss:
                        DispatchQueue.main.sync {
                            self?.coordinates            = parsedPosition.positions
                            self?.issLatitude            = self?.coordinates[0].satlatitude ?? 0.0
                            self?.issLongitude           = self?.coordinates[0].satlongitude ?? 0.0
                            self?.iLat                   = String((self?.issLatitude)!)
                            self?.iLon                   = String((self?.issLongitude)!)
                        }
                    case .tss:
                        DispatchQueue.main.sync {
                            self?.coordinates            = parsedPosition.positions
                            self?.tssLatitude            = self?.coordinates[0].satlatitude ?? 0.0
                            self?.tssLongitude           = self?.coordinates[0].satlongitude ?? 0.0
                            self?.tLat                   = String((self?.tssLatitude)!)
                            self?.tLon                   = String((self?.tssLongitude)!)
                        }
                    case .hst:
                        DispatchQueue.main.sync {
                            self?.coordinates            = parsedPosition.positions
                            self?.hubbleLatitude         = self?.coordinates[0].satlatitude ?? 0.0
                            self?.hubbleLongitude        = self?.coordinates[0].satlongitude ?? 0.0
                            self?.hLat                   = String((self?.hubbleLatitude)!)
                            self?.hLon                   = String((self?.hubbleLongitude)!)
                        }
                    case .none:
                        return
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self?.isRunningLabel?.text = "Can't get \(satellite.satelliteName) location."
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.isRunningLabel?.text = "Can't get \(satellite.satelliteName) location."
                }
            }
        }
        globeUpdateTask.resume()
    }
}
