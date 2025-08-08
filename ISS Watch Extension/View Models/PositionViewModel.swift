//
//  PositionViewModel.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 9/8/21.
//  Updated by Michael on 8/8/2025.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import Combine
import Foundation
import Observation
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
    private let deltaThreshold: Float = 10  // Used to ensure a reliable heading calculation
    
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

        // Define the satellites we track in a single place for clarity
        let satellites: [StationsAndSatellites] = [.iss, .tss, .hst]

        // Fetch satellite positions.
        for sat in satellites {
            getSatellitePosition(for: sat)
        }

        // Update subsolar point position.
        updateSubSolarPoint()

        // Update each satellite's display on the globe.
        for sat in satellites {
            updateDisplay(for: sat)
        }

        // Update the Sun's position and auto-spin state
        earthGlobe.setUpTheSun(lat: subsolarCoordinates.latitude, lon: subsolarCoordinates.longitude)
        earthGlobe.autoSpinGlobeRun(run: spinEnabled)
    }
    /// Wrapper that binds the correct properties and renderers for a given satellite
    private func updateDisplay(for satellite: StationsAndSatellites) {
        switch satellite {
        case .iss:
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
        case .tss:
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
        case .hst:
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
        case .none:
            break
        }
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

        // First-time render for this satellite: show marker and viewing circle immediately
        if lastLatitude == 0 {
            viewingCircle(currentLatitude, currentLongitude)
            marker(currentLatitude, currentLongitude)
            lastLatitude = currentLatitude
            return
        }

        // Subsequent updates: only draw the orbit track if the latitude change is within a sane threshold
        if abs(delta) < deltaThreshold {
            headingFactor = (delta < 0) ? -1 : 1
            orbitTrack(currentLatitude, currentLongitude, headingFactor)
        }

        // Always refresh marker and viewing circle at the newest position
        viewingCircle(currentLatitude, currentLongitude)
        marker(currentLatitude, currentLongitude)

        lastLatitude = currentLatitude
    }
}

extension PositionViewModel {
    // MARK: - Satellite field bindings (to remove repetitive switching)
    private typealias FloatKP = ReferenceWritableKeyPath<PositionViewModel, Float>
    private typealias StringKP = ReferenceWritableKeyPath<PositionViewModel, String>

    private struct SatBindings {
        let lat: FloatKP
        let lon: FloatKP
        let alt: FloatKP
        let altKm: StringKP
        let altMi: StringKP
        let latStr: StringKP
        let lonStr: StringKP
    }

    private func bindings(for satellite: StationsAndSatellites) -> SatBindings? {
        switch satellite {
        case .iss:
            return SatBindings(
                lat: \PositionViewModel.issLatitude,
                lon: \PositionViewModel.issLongitude,
                alt: \PositionViewModel.issAltitude,
                altKm: \PositionViewModel.issAltitudeInKm,
                altMi: \PositionViewModel.issAltitudeInMi,
                latStr: \PositionViewModel.issFormattedLatitude,
                lonStr: \PositionViewModel.issFormattedLongitude
            )
        case .tss:
            return SatBindings(
                lat: \PositionViewModel.tssLatitude,
                lon: \PositionViewModel.tssLongitude,
                alt: \PositionViewModel.tssAltitude,
                altKm: \PositionViewModel.tssAltitudeInKm,
                altMi: \PositionViewModel.tssAltitudeInMi,
                latStr: \PositionViewModel.tssFormattedLatitude,
                lonStr: \PositionViewModel.tssFormattedLongitude
            )
        case .hst:
            return SatBindings(
                lat: \PositionViewModel.hubbleLatitude,
                lon: \PositionViewModel.hubbleLongitude,
                alt: \PositionViewModel.hubbleAltitude,
                altKm: \PositionViewModel.hubbleAltitudeInKm,
                altMi: \PositionViewModel.hubbleAltitudeInMi,
                latStr: \PositionViewModel.hubbleFormattedLatitude,
                lonStr: \PositionViewModel.hubbleFormattedLongitude
            )
        case .none:
            return nil
        }
    }
    
    /// Helper to format a coordinate value as a DMS string using the app's standard format.
    private func formatCoordinate(_ value: Float, isLatitude: Bool) -> String {
        CoordinateConversions.decimalCoordinatesToDegMinSec(
            coordinate: Double(value),
            format: Globals.coordinatesStringFormat,
            isLatitude: isLatitude
        )
    }
    
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
        guard let b = bindings(for: satellite) else { return }
        let pos = positionData.positions[0]

        let lat = Float(pos.satlatitude)
        let lon = Float(pos.satlongitude)
        let alt = Float(pos.sataltitude)

        // Assign numeric fields via key paths
        self[keyPath: b.lat] = lat
        self[keyPath: b.lon] = lon
        self[keyPath: b.alt] = alt

        // Pre-format altitude strings
        let altKmStr = numberFormatter.string(from: NSNumber(value: Double(alt))) ?? ""
        let altMiStr = numberFormatter.string(from: NSNumber(value: Double(alt) * Globals.kilometersToMiles)) ?? ""
        self[keyPath: b.altKm] = "\(altKmStr) km"
        self[keyPath: b.altMi] = "\(altMiStr) mi"

        // Pre-format coordinate strings
        self[keyPath: b.latStr] = formatCoordinate(lat, isLatitude: true)
        self[keyPath: b.lonStr] = formatCoordinate(lon, isLatitude: false)
    }
}
