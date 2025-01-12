//
//  ViewModel.swift
//  ISS Watch
//
//  Created by Michael Stebel on 9/8/21.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import Combine
import Foundation
import SceneKit

@Observable
final class PositionViewModel: ObservableObject {
    
    // MARK: - Published properties
    
    var earthGlobe: EarthGlobe    = EarthGlobe()
    var errorForAlert: ErrorCodes?
    var globeMainNode: SCNNode?
    var globeScene: SCNScene?
    
    var hubbleAltitude: Float     = 0.0
    var hubbleAltitudeInKm        = ""
    var hubbleAltitudeInMi        = ""
    var hubbleFormattedLatitude   = ""
    var hubbleFormattedLongitude  = ""
    
    var issAltitude: Float        = 0.0
    var issAltitudeInKm           = ""
    var issAltitudeInMi           = ""
    var issFormattedLatitude      = ""
    var issFormattedLongitude     = ""
   
    var subsolarLatitude: String  = ""
    var subsolarLongitude: String = ""
    
    var tssAltitude: Float        = 0.0
    var tssAltitudeInKm           = ""
    var tssAltitudeInMi           = ""
    var tssFormattedLatitude      = ""
    var tssFormattedLongitude     = ""
    
    var isStartingUp              = true
    var spinEnabled               = true
    var wasError                  = false
    
    // MARK: - Properties
    
    private let apiEndpointString                                        = ApiEndpoints.issTrackerAPIEndpointC
    private let apiKey                                                   = ApiKeys.issLocationKey
    private let numberFormatter                                          = NumberFormatter()
    private let timerValue                                               = 3.0
    
    private var timer: AnyCancellable?
    private var cancellables: Set<AnyCancellable>                        = []
    
    private var hubbleHeadingFactor: Float                               = 0.0
    private var hubbleLastLat: Float                                     = 0.0
    private var hubbleLatitude: Float                                    = 0.0
    private var hubbleLongitude: Float                                   = 0.0
    
    private var issHeadingFactor: Float                                  = 0.0
    private var issLastLat: Float                                        = 0.0
    private var issLatitude: Float                                       = 0.0
    private var issLongitude: Float                                      = 0.0
    
    private var subsolarCoordinates: (latitude: Float, longitude: Float) = (0, 0)

    private var tssHeadingFactor: Float                                  = 0.0
    private var tssLastLat: Float                                        = 0.0
    private var tssLatitude: Float                                       = 0.0
    private var tssLongitude: Float                                      = 0.0
    
    // MARK: - Methods
    
    init() {
        reset()
        initHelper()
        updateEarthGlobe()                  // Update the globe once before starting the timer
        start()
    }
    
    deinit {
        stop()
    }
    
    /// Reset the globe
    func reset() {
        earthGlobe    = EarthGlobe()
        isStartingUp  = true
        spinEnabled   = true
        issLastLat    = 0
        tssLastLat    = 0
        hubbleLastLat = 0
        
        initHelper()
    }
    
    /// Helps with initialization and reset
    private func initHelper() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [self] in       // Will tell the view to show the progress indicator
            isStartingUp = false
        }
        
        // Set up our scene
        globeMainNode = earthGlobe.cameraNode
        globeScene    = earthGlobe.scene
        earthGlobe.setupInSceneView()
    }
    
    /// Set up and start the timer
    func start() {
        timer = Timer
            .publish(every: timerValue, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateEarthGlobe()
            }
    }
 
    /// Stop updating
    func stop() {
        timer?.cancel()
    }
    
    /// The engine that powers this view model. Updates the globe scene for the new coordinates
    private func updateEarthGlobe() {
        
        // MARK: Helper functions
        
        /// Helper function to remove the last child node in the nodes array
        func removeLastNode() {
            if let nodeToRemove = earthGlobe.globe.childNodes.last {
                nodeToRemove.removeFromParentNode()
            }
        }
        
        /// Helper fucntion to get and format the subsolar point
        func updateSubSolarPoint() {
            subsolarCoordinates = AstroCalculations.getSubSolarCoordinates()
            subsolarLatitude    = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(subsolarCoordinates.latitude), format: Globals.coordinatesStringFormat, isLatitude: true)
            subsolarLongitude   = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(subsolarCoordinates.longitude), format: Globals.coordinatesStringFormat, isLatitude: false)
        }
        
        
        /// We need to remove each of the nodes we've added before adding them again at new coordinates, or we get a f'ng mess!
        var numberOfChildNodes = earthGlobe.getNumberOfChildNodes()
        while numberOfChildNodes > 0 {
            removeLastNode()
            numberOfChildNodes -= 1
        }
        
        // MARK: Get coordinates for everything we're tracking
        
        // Iterate over all the satellites to determiine where are each of the satellites right now
        for sat: StationsAndSatellites in [.iss, .tss, .hst] {
            getSatellitePosition(for: sat)
        }
        
        // Get the subsolar point
        updateSubSolarPoint()
        
        // MARK: Update the globe scene
        
        // For each target, if we have the last coordinates, add the markers, otherwise we don't know which way the orbits are oriented
        if issLastLat != 0 {
            // MARK: Set up ISS
            issHeadingFactor = issLatitude - issLastLat < 0 ? -1 : 1
            earthGlobe.addOrbitTrackAroundTheGlobe(for: .iss, lat: issLatitude, lon: issLongitude, headingFactor: issHeadingFactor)
            
            // Add footprint
            earthGlobe.addISSViewingCircle(lat: issLatitude, lon: issLongitude)
            
            // Add satellite marker
            earthGlobe.addISSMarker(lat: issLatitude, lon: issLongitude)
        }
            
        if tssLastLat != 0 {
            // MARK: Set up Tiangong
            tssHeadingFactor = tssLatitude - tssLastLat < 0 ? -1 : 1
            earthGlobe.addOrbitTrackAroundTheGlobe(for: .tss, lat: tssLatitude, lon: tssLongitude, headingFactor: tssHeadingFactor)
            
            // Add footprint
            earthGlobe.addTSSViewingCircle(lat: tssLatitude, lon: tssLongitude)
            
            // Add satellite marker
            earthGlobe.addTSSMarker(lat: tssLatitude, lon: tssLongitude)
        }
            
        if hubbleLastLat != 0 {
            // MARK: Set up Hubble
            hubbleHeadingFactor = hubbleLatitude - hubbleLastLat < 0 ? -1 : 1
            earthGlobe.addOrbitTrackAroundTheGlobe(for: .hst, lat: hubbleLatitude, lon: hubbleLongitude, headingFactor: hubbleHeadingFactor)
            
            // Add footprint
            earthGlobe.addHubbleViewingCircle(lat: hubbleLatitude, lon: hubbleLongitude)
            
            // Add satellite marker
            earthGlobe.addHubbleMarker(lat: hubbleLatitude, lon: hubbleLongitude)
            
        }
            
            // MARK: Set up the Sun at the current subsolar point
            earthGlobe.setUpTheSun(lat: subsolarCoordinates.latitude, lon: subsolarCoordinates.longitude)
            
            earthGlobe.autoSpinGlobeRun(run: spinEnabled)

        // Save last latitude for each track to use in calculating north or south heading vector after the second track update
        issLastLat    = issLatitude
        tssLastLat    = tssLatitude
        hubbleLastLat = hubbleLatitude
        
    }
}

extension PositionViewModel {
    /// Get the current satellite coordinates
    /// - Parameter satellite: The satellite we're tracking as a StationAndSatellites object.
    private func getSatellitePosition(for satellite: StationsAndSatellites) {
        
        /// Helper method to extract our coordinates
        func getCoordinates(from positionData: SatelliteOrbitPosition) {
            switch satellite {
            case .iss:
                issLatitude              = Float(positionData.positions[0].satlatitude)
                issLongitude             = Float(positionData.positions[0].satlongitude)
                issAltitude              = Float(positionData.positions[0].sataltitude)
                issAltitudeInKm          = "\(numberFormatter.string(from: NSNumber(value: Double(issAltitude))) ?? "") km"
                issAltitudeInMi          = "\(numberFormatter.string(from: NSNumber(value: Double(issAltitude) * Globals.kilometersToMiles)) ?? "") mi"
                issFormattedLatitude     = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(issLatitude), format: Globals.coordinatesStringFormat, isLatitude: true)
                issFormattedLongitude    = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(issLongitude), format: Globals.coordinatesStringFormat, isLatitude: false)
            case .tss:
                tssLatitude              = Float(positionData.positions[0].satlatitude)
                tssLongitude             = Float(positionData.positions[0].satlongitude)
                tssAltitude              = Float(positionData.positions[0].sataltitude)
                tssAltitudeInKm          = "\(numberFormatter.string(from: NSNumber(value: Double(tssAltitude))) ?? "") km"
                tssAltitudeInMi          = "\(numberFormatter.string(from: NSNumber(value: Double(tssAltitude) * Globals.kilometersToMiles)) ?? "") mi"
                tssFormattedLatitude     = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(tssLatitude), format: Globals.coordinatesStringFormat, isLatitude: true)
                tssFormattedLongitude    = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(tssLongitude), format: Globals.coordinatesStringFormat, isLatitude: false)
            case .hst:
                hubbleLatitude           = Float(positionData.positions[0].satlatitude)
                hubbleLongitude          = Float(positionData.positions[0].satlongitude)
                hubbleAltitude           = Float(positionData.positions[0].sataltitude)
                hubbleAltitudeInKm       = "\(numberFormatter.string(from: NSNumber(value: Double(hubbleAltitude))) ?? "") km"
                hubbleAltitudeInMi       = "\(numberFormatter.string(from: NSNumber(value: Double(hubbleAltitude) * Globals.kilometersToMiles)) ?? "") mi"
                hubbleFormattedLatitude  = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(hubbleLatitude), format: Globals.coordinatesStringFormat, isLatitude: true)
                hubbleFormattedLongitude = CoordinateConversions.decimalCoordinatesToDegMinSec(coordinate: Double(hubbleLongitude), format: Globals.coordinatesStringFormat, isLatitude: false)
            case .none:
                break
            }
        }
        
        let satelliteCodeNumber = satellite.satelliteNORADCode
        
        /// Make sure we can create the URL from the endpoint and parameters
        guard let url = URL(string: apiEndpointString + "\(satelliteCodeNumber)/0/0/0/1/" + "&apiKey=\(apiKey)") else { return }
        
        /// Get data using Combine's dataTaskPublisher
        URLSession.shared.dataTaskPublisher(for: url)
            .map { (data: Data, response: URLResponse) in
                data
            }
            .decode(type: SatelliteOrbitPosition.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.wasError = true
                    self?.errorForAlert = ErrorCodes(message: "\(error.localizedDescription)")
                } else {
                    self?.wasError = false
                }
            }, receiveValue: { position in
                getCoordinates(from: position)
            })
            .store(in: &cancellables)
    }
}
