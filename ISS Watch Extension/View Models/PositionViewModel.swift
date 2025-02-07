//
//  PositionViewModel.swift
//  ISS Watch
//
//  Created by Michael Stebel on 9/8/21.
//  Updated by Michael on 2/6/2025.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import Combine
import Foundation
import SceneKit

@Observable
final class PositionViewModel: ObservableObject {
    
    // MARK: - Published properties
    
    var earthGlobe: EarthGlobe = EarthGlobe()
    var errorForAlert: ErrorCodes?
    var globeMainNode: SCNNode?
    var globeScene: SCNScene?
    
    var hubbleAltitude: Float = 0.0
    var hubbleAltitudeInKm = ""
    var hubbleAltitudeInMi = ""
    var hubbleFormattedLatitude = ""
    var hubbleFormattedLongitude = ""
    
    var issAltitude: Float = 0.0
    var issAltitudeInKm = ""
    var issAltitudeInMi = ""
    var issFormattedLatitude = ""
    var issFormattedLongitude = ""
    
    var subsolarLatitude: String = ""
    var subsolarLongitude: String = ""
    
    var tssAltitude: Float = 0.0
    var tssAltitudeInKm = ""
    var tssAltitudeInMi = ""
    var tssFormattedLatitude = ""
    var tssFormattedLongitude = ""
    
    var isStartingUp = true
    var spinEnabled = true
    var wasError = false
    
    // MARK: - Properties
    
    private let apiEndpointString = ApiEndpoints.issTrackerAPIEndpointC
    private let apiKey = ApiKeys.issLocationKey
    private let numberFormatter = NumberFormatter()
    private let timerValue = 3.0
    private let deltaThreshold: Float = 10  // used to ensure a reliable heading calculation
    
    private var timer: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    
    // Satellite tracking properties
    private var hubbleHeadingFactor: Float = 0.0
    private var hubbleLastLat: Float = 0.0
    private var hubbleLatitude: Float = 0.0
    private var hubbleLongitude: Float = 0.0
    
    private var issHeadingFactor: Float = 0.0
    private var issLastLat: Float = 0.0
    private var issLatitude: Float = 0.0
    private var issLongitude: Float = 0.0
    
    private var tssHeadingFactor: Float = 0.0
    private var tssLastLat: Float = 0.0
    private var tssLatitude: Float = 0.0
    private var tssLongitude: Float = 0.0
    
    private var subsolarCoordinates: (latitude: Float, longitude: Float) = (0, 0)
    
    // MARK: - Initialization
    
    init() {
        reset()
        initHelper()
        updateEarthGlobe() // one initial update before starting the timer
        start()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Reset the globe and satellite tracking state.
    func reset() {
        earthGlobe = EarthGlobe()
        isStartingUp = true
        spinEnabled = true
        issLastLat = 0
        tssLastLat = 0
        hubbleLastLat = 0
        
        initHelper()
    }
    
    /// Start the timer to update the globe.
    func start() {
        timer = Timer
            .publish(every: timerValue, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateEarthGlobe()
            }
    }
    
    /// Stop the timer.
    func stop() {
        timer?.cancel()
        
    }
    
    // MARK: - Private Methods
    
    /// Common initialization: set up the scene and schedule turning off the startup indicator.
    private func initHelper() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            self?.isStartingUp = false
        }
        
        globeMainNode = earthGlobe.cameraNode
        globeScene = earthGlobe.scene
        earthGlobe.setupInSceneView()
    }
    
    /// Update the earth globe with the latest satellite positions and subsolar point.
    private func updateEarthGlobe() {
        // Remove previously added nodes from the globe
        removeAllGlobeNodes()
        
        // Fetch satellite positions
        for sat in [StationsAndSatellites.iss, .tss, .hst] {
            getSatellitePosition(for: sat)
        }
        
        // Update subsolar point info
        updateSubSolarPoint()
        
        // Update each satellite's display on the globe.
        updateSatelliteDisplay(
            satellite: .iss,
            currentLatitude: issLatitude,
            currentLongitude: issLongitude,
            lastLatitude: &issLastLat,
            headingFactor: &issHeadingFactor,
            orbitTrack: { lat, lon, heading in
                self.earthGlobe.addOrbitTrackAroundTheGlobe(for: .iss, lat: lat, lon: lon, headingFactor: heading)
            },
            viewingCircle: { lat, lon in
                self.earthGlobe.addISSViewingCircle(lat: lat, lon: lon)
            },
            marker: { lat, lon in
                self.earthGlobe.addISSMarker(lat: lat, lon: lon)
            }
        )
        
        updateSatelliteDisplay(
            satellite: .tss,
            currentLatitude: tssLatitude,
            currentLongitude: tssLongitude,
            lastLatitude: &tssLastLat,
            headingFactor: &tssHeadingFactor,
            orbitTrack: { lat, lon, heading in
                self.earthGlobe.addOrbitTrackAroundTheGlobe(for: .tss, lat: lat, lon: lon, headingFactor: heading)
            },
            viewingCircle: { lat, lon in
                self.earthGlobe.addTSSViewingCircle(lat: lat, lon: lon)
            },
            marker: { lat, lon in
                self.earthGlobe.addTSSMarker(lat: lat, lon: lon)
            }
        )
        
        updateSatelliteDisplay(
            satellite: .hst,
            currentLatitude: hubbleLatitude,
            currentLongitude: hubbleLongitude,
            lastLatitude: &hubbleLastLat,
            headingFactor: &hubbleHeadingFactor,
            orbitTrack: { lat, lon, heading in
                self.earthGlobe.addOrbitTrackAroundTheGlobe(for: .hst, lat: lat, lon: lon, headingFactor: heading)
            },
            viewingCircle: { lat, lon in
                self.earthGlobe.addHubbleViewingCircle(lat: lat, lon: lon)
            },
            marker: { lat, lon in
                self.earthGlobe.addHubbleMarker(lat: lat, lon: lon)
            }
        )
        
        // Update the Sun's position
        earthGlobe.setUpTheSun(lat: subsolarCoordinates.latitude, lon: subsolarCoordinates.longitude)
        earthGlobe.autoSpinGlobeRun(run: spinEnabled)
    }
    
    /// Remove all child nodes from the globe.
    private func removeAllGlobeNodes() {
        while earthGlobe.getNumberOfChildNodes() > 0 {
            if let node = earthGlobe.globe.childNodes.last {
                node.removeFromParentNode()
            }
        }
    }
    
    /// Update the subsolar point and its formatted latitude/longitude strings.
    private func updateSubSolarPoint() {
        subsolarCoordinates = AstroCalculations.getSubSolarCoordinates()
        subsolarLatitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
            coordinate: Double(subsolarCoordinates.latitude),
            format: Globals.coordinatesStringFormat,
            isLatitude: true
        )
        subsolarLongitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
            coordinate: Double(subsolarCoordinates.longitude),
            format: Globals.coordinatesStringFormat,
            isLatitude: false
        )
    }
    
    /// Update a given satellite's display on the globe if the change in latitude is within threshold.
    ///
    /// - Parameters:
    ///   - satellite: The satellite type.
    ///   - currentLatitude: The satellite’s current latitude.
    ///   - currentLongitude: The satellite’s current longitude.
    ///   - lastLatitude: In-out parameter holding the last known latitude (will be updated).
    ///   - headingFactor: In-out parameter for determining the orbit direction.
    ///   - orbitTrack: Closure to add the orbit track.
    ///   - viewingCircle: Closure to add the viewing circle.
    ///   - marker: Closure to add the satellite marker.
    private func updateSatelliteDisplay(
        satellite: StationsAndSatellites,
        currentLatitude: Float,
        currentLongitude: Float,
        lastLatitude: inout Float,
        headingFactor: inout Float,
        orbitTrack: (Float, Float, Float) -> Void,
        viewingCircle: (Float, Float) -> Void,
        marker: (Float, Float) -> Void
    ) {
        let delta = currentLatitude - lastLatitude
        if lastLatitude != 0, abs(delta) < deltaThreshold {
            headingFactor = (delta < 0) ? -1 : 1
            orbitTrack(currentLatitude, currentLongitude, headingFactor)
            viewingCircle(currentLatitude, currentLongitude)
            marker(currentLatitude, currentLongitude)
        }
        lastLatitude = currentLatitude
    }
}

extension PositionViewModel {
    /// Get the current satellite coordinates.
    /// - Parameter satellite: The satellite to track.
    private func getSatellitePosition(for satellite: StationsAndSatellites) {
        guard let url = URL(string: "\(apiEndpointString)\(satellite.satelliteNORADCode)/0/0/0/1/&apiKey=\(apiKey)") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: SatelliteOrbitPosition.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.wasError = true
                    self?.errorForAlert = ErrorCodes(message: error.localizedDescription)
                } else {
                    self?.wasError = false
                }
            }, receiveValue: { [weak self] position in
                self?.updateSatelliteCoordinates(from: position, for: satellite)
            })
            .store(in: &cancellables)
    }
    
    /// Update satellite coordinates and formatted strings from the received data.
    /// - Parameters:
    ///   - positionData: The satellite position data.
    ///   - satellite: The satellite type.
    private func updateSatelliteCoordinates(from positionData: SatelliteOrbitPosition, for satellite: StationsAndSatellites) {
        let pos = positionData.positions[0]
        switch satellite {
        case .iss:
            issLatitude = Float(pos.satlatitude)
            issLongitude = Float(pos.satlongitude)
            issAltitude = Float(pos.sataltitude)
            issAltitudeInKm = "\(numberFormatter.string(from: NSNumber(value: Double(issAltitude))) ?? "") km"
            issAltitudeInMi = "\(numberFormatter.string(from: NSNumber(value: Double(issAltitude) * Globals.kilometersToMiles)) ?? "") mi"
            issFormattedLatitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
                coordinate: Double(issLatitude),
                format: Globals.coordinatesStringFormat,
                isLatitude: true
            )
            issFormattedLongitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
                coordinate: Double(issLongitude),
                format: Globals.coordinatesStringFormat,
                isLatitude: false
            )
        case .tss:
            tssLatitude = Float(pos.satlatitude)
            tssLongitude = Float(pos.satlongitude)
            tssAltitude = Float(pos.sataltitude)
            tssAltitudeInKm = "\(numberFormatter.string(from: NSNumber(value: Double(tssAltitude))) ?? "") km"
            tssAltitudeInMi = "\(numberFormatter.string(from: NSNumber(value: Double(tssAltitude) * Globals.kilometersToMiles)) ?? "") mi"
            tssFormattedLatitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
                coordinate: Double(tssLatitude),
                format: Globals.coordinatesStringFormat,
                isLatitude: true
            )
            tssFormattedLongitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
                coordinate: Double(tssLongitude),
                format: Globals.coordinatesStringFormat,
                isLatitude: false
            )
        case .hst:
            hubbleLatitude = Float(pos.satlatitude)
            hubbleLongitude = Float(pos.satlongitude)
            hubbleAltitude = Float(pos.sataltitude)
            hubbleAltitudeInKm = "\(numberFormatter.string(from: NSNumber(value: Double(hubbleAltitude))) ?? "") km"
            hubbleAltitudeInMi = "\(numberFormatter.string(from: NSNumber(value: Double(hubbleAltitude) * Globals.kilometersToMiles)) ?? "") mi"
            hubbleFormattedLatitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
                coordinate: Double(hubbleLatitude),
                format: Globals.coordinatesStringFormat,
                isLatitude: true
            )
            hubbleFormattedLongitude = CoordinateConversions.decimalCoordinatesToDegMinSec(
                coordinate: Double(hubbleLongitude),
                format: Globals.coordinatesStringFormat,
                isLatitude: false
            )
        case .none:
            break
        }
    }
}
