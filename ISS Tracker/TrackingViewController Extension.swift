//
//  TrackingViewController Extension.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 2/20/2025.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit
import MapKit

extension TrackingViewController {
    
    /// Update the info box data asynchronously
    private func updateCoordinatesDisplay() async {
        await MainActor.run { [self] in
            guard
                let lat = Double(latitude),
                let lon = Double(longitude),
                let altDouble = Double(altitude),
                let velDouble = Double(velocity)
            else {
                // Safely handle parsing issues or invalid numbers
                positionString        = Globals.spacer
                altitudeLabel.text    = ""
                coordinatesLabel.text = ""
                velocityLabel.text    = ""
                return
            }
            
            // Coordinates
            positionString = "    Position: \(CoordinateConversions.decimalCoordinatesToDegMinSec(latitude: lat, longitude: lon, format: Globals.coordinatesStringFormat))"
            
            // Altitude
            if let altitudeInKmNumber = Constants.numberFormatter.string(from: NSNumber(value: altDouble)) {
                altitudeInKm = altitudeInKmNumber
            }
            if let altitudeInMilesNumber = Constants.numberFormatter.string(from: NSNumber(value: altDouble * Globals.kilometersToMiles)) {
                altitudeInMiles = altitudeInMilesNumber
            }
            altString = "    Altitude: \(altitudeInKm) km  (\(altitudeInMiles) mi)"
            
            // Velocity
            if let velocityInKmHNumber = Constants.numberFormatter.string(from: NSNumber(value: velDouble)) {
                velocityInKmH = velocityInKmHNumber
            }
            if let velocityInMPHNumber = Constants.numberFormatter.string(from: NSNumber(value: velDouble * Globals.kilometersToMiles)) {
                velocityInMPH = velocityInMPHNumber
            }
            velString = "    Velocity: \(velocityInKmH) km/h  (\(velocityInMPH) mph)"
            
            altitudeLabel.text    = altString
            coordinatesLabel.text = positionString
            velocityLabel.text    = velString
        }
    }
    
    /// Draw orbit ground track line overlay asynchronously
    private func drawOrbitGroundTrackLine() async {
        await MainActor.run { [self] in
            appendCurrentCoordinate()
            
            guard Globals.orbitGroundTrackLineEnabled,
                  listOfCoordinates.count >= 2
            else {
                return
            }
            
            drawPolyline()
            removeExcessCoordinates()
        }
    }
    
    private func appendCurrentCoordinate() {
        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude) ?? 0.0, longitude: CLLocationDegrees(longitude) ?? 0.0)
        listOfCoordinates.append(coordinate)
    }
    
    private func drawPolyline() {
        let lastTwoCoordinates = Array(listOfCoordinates.suffix(2))
        let polyline = MKPolyline(coordinates: lastTwoCoordinates, count: lastTwoCoordinates.count)
        let polylineRenderer = MKPolylineRenderer(overlay: polyline)
        polylineRenderer.strokeColor = .blue
        polylineRenderer.fillColor = .blue
        map.addOverlay(polyline)
    }
    
    private func removeExcessCoordinates() {
        let maxCoordinates = 4
        if listOfCoordinates.count == maxCoordinates {
            listOfCoordinates.removeFirst(maxCoordinates - 1)
        }
    }
    
    /// Overlay delegate
    /// - Parameters:
    ///   - mapView: An MKMapView
    ///   - overlay: An MKOverlay
    /// - Returns: A renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = colorForTarget(target)
        renderer.lineWidth = 5.0
        renderer.lineCap = .round
        return renderer
    }
    
    private func colorForTarget(_ target: StationsAndSatellites) -> UIColor {
        switch target {
        case .iss:
            return UIColor(named: Theme.issOrbitalColor) ?? .gray
        case .tss:
            return UIColor(named: Theme.tssOrbitalColor) ?? .gray
        case .hst:
            return UIColor(named: Theme.hubbleOrbitalColor) ?? .gray
        case .none:
            return UIColor(named: Theme.issOrbitalColor) ?? .gray
        }
    }
    
    /// Set up the overlays and any buttons that depend on the user's settings
    fileprivate func setUpAllOverlaysAndButtons() {
        
        DispatchQueue.main.async {
            self.setUpDisplayConfiguration()
            
            if Globals.zoomFactorWasResetInSettings {     // If reset was pressed in Settings, or if the zoom scale factor was changed, this flag will be set. So, reset zoom to default values for the selected scale factor and call zoomValueChanged method.
                self.setUpZoomSlider(usingSavedZoomFactor: false)
                self.zoomValueChanged(self.zoomSlider)
            }
            
            if Globals.showCoordinatesIsOn {
                self.displayInfoBox(true)
            } else {
                self.displayInfoBox(false)
            }
            
            if Globals.displayZoomFactorBelowMarkerIsOn {
                self.zoomFactorLabel.isHidden        = false
                self.setupZoomFactorLabel(self.timerValue)
            } else {
                self.zoomFactorLabel.isHidden        = true
            }
            
            if Globals.orbitGroundTrackLineEnabled {
                self.clearOrbitTrackButton.alpha     = 1.0
                self.clearOrbitTrackButton.isEnabled = true
            } else {
                self.clearOrbitTrackButton.alpha     = 0.60
                self.clearOrbitTrackButton.isEnabled = false
            }
            
            self.cursor.isHidden = false     // Now, show the marker
        }
    }
    
    /// Helper method to update the 2D map with the satellite's current position
    fileprivate func updateMap() {
        self.location = CLLocationCoordinate2DMake(CLLocationDegrees(self.latitude) ?? 0.0, CLLocationDegrees(self.longitude) ?? 0.0)
        self.span = MKCoordinateSpan.init(latitudeDelta: self.latDelta, longitudeDelta: self.lonDelta)
        self.region = MKCoordinateRegion.init(center: self.location, span: self.span)
        self.map.setRegion(self.region, animated: true)
    }
    
    /// Update map and globe
    fileprivate func updateGlobeAndMapForPositionsOfStations() {
        DispatchQueue.main.async {
            self.setUpAllOverlaysAndButtons()
            
            self.updateMap()
            
            // Draw ground track, if enabled
            if Globals.orbitGroundTrackLineEnabled {
                Task {
                    await self.drawOrbitGroundTrackLine()
                }
            }
            
            // Update the coordinates and other data in the info box, if enabled
            if Globals.showCoordinatesIsOn {
                Task {
                    await self.updateCoordinatesDisplay()
                }
            }
            
            // Update mini globe with ISS position, footprint, and orbital track, if enabled.
            if Globals.displayGlobe {
                self.updateEarthGlobeScene(in: self.globe, hubbleLatitude: self.hLat, hubbleLongitude: self.hLon, issLatitude: self.iLat, issLongitude: self.iLon, tssLatitude: self.tLat, tssLongitude: self.tLon, hubbleLastLat: &self.hubbleLastLat, issLastLat: &self.issLastLat, tssLastLat: &self.tssLastLat)
                self.setUpCoordinatesLabel(withTopCorners: false)
                self.globeScene.isHidden        = false
                self.globeExpandButton.isHidden = false
                self.globeStatusLabel.isHidden  = false
            } else {
                self.setUpCoordinatesLabel(withTopCorners: true)
                self.globeScene.isHidden        = true
                self.globeExpandButton.isHidden = true
                self.globeStatusLabel.isHidden  = true
            }
        }
    }
    
    /// Locate satellite position and other data
    /// - Parameter satellite: The target satellite as a StationsAndSatellites object
    func locateSatellite(for satellite: StationsAndSatellites) {
        let satelliteCodeNumber = satellite.satelliteNORADCode
        
        /// Make sure we can create the URL from the endpoint and parameters
        guard let endpointURL = URL(string: Constants.generalEndpointString + "\(satelliteCodeNumber)/0/0/0/1/" + "&apiKey=\(Constants.generalAPIKey)") else { return }
        
        /// Task to get JSON data from API by sending request to API endpoint, parse response for position data, and then display positions.
        /// Uses a capture list to capture a weak reference to self. This should prevent a retain cycle and allow ARC to release instance and reduce memory load.
        let globeUpdateTask = URLSession.shared.dataTask(with: endpointURL) { [ self ] (data, response, error) in
            if let data {
                let decoder = JSONDecoder()
                do {
                    let parsedPosition = try decoder.decode(SatelliteOrbitPosition.self, from: data)  // Parse JSON data
                    self.coordinates   = parsedPosition.positions
                    
                    switch satellite {
                    case .iss:
                        DispatchQueue.main.sync {
                            issLatitude            = coordinates[0].satlatitude
                            issLongitude           = coordinates[0].satlongitude
                            iLat                   = String(issLatitude)
                            iLon                   = String(issLongitude)
                            latitude               = String(issLatitude)
                            longitude              = String(issLongitude)
                            tssLatitude            = 0
                            tssLongitude           = 0
                            tLat                   = ""
                            tLon                   = ""
                            hubbleLatitude         = 0
                            hubbleLongitude        = 0
                            hLat                   = ""
                            hLon                   = ""
                        }
                    case .tss:
                        DispatchQueue.main.sync {
                            tssLatitude            = coordinates[0].satlatitude
                            tssLongitude           = coordinates[0].satlongitude
                            tLat                   = String(tssLatitude)
                            tLon                   = String(tssLongitude)
                            latitude               = String(tssLatitude)
                            longitude              = String(tssLongitude)
                            issLatitude            = 0
                            issLongitude           = 0
                            iLat                   = ""
                            iLon                   = ""
                            hubbleLatitude         = 0
                            hubbleLongitude        = 0
                            hLat                   = ""
                            hLon                   = ""
                        }
                    case .hst:
                        DispatchQueue.main.sync {
                            hubbleLatitude         = coordinates[0].satlatitude
                            hubbleLongitude        = coordinates[0].satlongitude
                            hLat                   = String(hubbleLatitude)
                            hLon                   = String(hubbleLongitude)
                            latitude               = String(hubbleLatitude)
                            longitude              = String(hubbleLongitude)
                            issLatitude            = 0
                            issLongitude           = 0
                            iLat                   = ""
                            iLon                   = ""
                            tssLatitude            = 0
                            tssLongitude           = 0
                            tLat                   = ""
                            tLon                   = ""
                        }
                    case .none:
                        return
                    }
                    
                    DispatchQueue.main.sync {
                        velocity = satellite.satelliteVelocity     // Use hard-coded velecity from the model
                        altitude = String(coordinates[0].sataltitude)
                        atDateAndTime = String(coordinates[0].timestamp)
                        
                        updateGlobeAndMapForPositionsOfStations()  // Update positions and info box
                    }
                    
                } catch {
                    // If parsing fails
                    DispatchQueue.main.async {
                        self.stopAction()
                        self.showAlert(title: "Can't get ISS location", message: "Wait a few minutes\nand then tap ▶︎ again.")
                    }
                }
            } else {
                // If can't access API
                DispatchQueue.main.async {
                    self.stopAction()
                    self.showNoInternetAlert()
                }
            }
        }
        
        globeUpdateTask.resume()
    }
}
