//
//  EarthGlobeProtocol.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 2/26/2022.
//  Updated by Michael on 2/6/2025.
//  Copyright © 2020-2025 ISS Real-Time Tracker. All rights reserved.
//

import SceneKit
import UIKit

/// Protocol that adds EarthGlobe support to a UIViewController subclass, with properties and methods to create the scene and update it.
protocol EarthGlobeProtocol: UIViewController {
    var issLastLat: Float { get set }
    var tssLastLat: Float { get set }
    var hubbleLastLat: Float { get set }
    
    func setUpEarthGlobeScene(for globe: EarthGlobe, in scene: SCNView, hasTintedBackground: Bool)
    
    func updateEarthGlobeScene(in globe: EarthGlobe,
                               hubbleLatitude: String?,
                               hubbleLongitude: String?,
                               issLatitude: String?,
                               issLongitude: String?,
                               tssLatitude: String?,
                               tssLongitude: String?,
                               hubbleLastLat: inout Float,
                               issLastLat: inout Float,
                               tssLastLat: inout Float)
}

// MARK: - Default implementations

extension EarthGlobeProtocol {
    
    func setUpEarthGlobeScene(for globe: EarthGlobe, in scene: SCNView, hasTintedBackground: Bool) {
        globe.setupInSceneView(scene, customPinchGestureIsEnabled: false)
        
        if hasTintedBackground {
            scene.backgroundColor     = UIColor(named: Theme.popupBgd)?.withAlphaComponent(0.60) // Tinted for map view overlay mode
            scene.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            scene.layer.cornerRadius  = 10
            scene.layer.masksToBounds = true
        } else {
            scene.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0) // Transparent background for full-screen mode
        }
    }
    
    func updateEarthGlobeScene(in globe: EarthGlobe,
                               hubbleLatitude: String?,
                               hubbleLongitude: String?,
                               issLatitude: String?,
                               issLongitude: String?,
                               tssLatitude: String?,
                               tssLongitude: String?,
                               hubbleLastLat: inout Float,
                               issLastLat: inout Float,
                               tssLastLat: inout Float) {
        
        // Helper to parse coordinate strings into a Float tuple and determine if valid coordinates were provided.
        func parseCoordinates(lat: String?, lon: String?) -> (isValid: Bool, lat: Float, lon: Float) {
            let latitude  = Float(lat ?? "") ?? 0.0
            let longitude = Float(lon ?? "") ?? 0.0
            // If the sum of lat and lon is not zero, we assume valid coordinates.
            return ((latitude + longitude) != 0.0, latitude, longitude)
        }
        
        // Parse coordinates for each satellite.
        let (addISS, iLat, iLon)       = parseCoordinates(lat: issLatitude, lon: issLongitude)
        let (addTSS, tLat, tLon)       = parseCoordinates(lat: tssLatitude, lon: tssLongitude)
        let (addHubble, hLat, hLon)    = parseCoordinates(lat: hubbleLatitude, lon: hubbleLongitude)
        
        // Remove all previously added child nodes.
        while globe.getNumberOfChildNodes() > 0 {
            globe.removeLastNode()
        }
        
        // Helper to update heading factor based on the change in latitude.
        func updateHeading(for currentLat: Float, lastLat: inout Float) -> (shouldShowOrbit: Bool, headingFactor: Float) {
            let delta = currentLat - lastLat
            let shouldShowOrbit = (lastLat != 0 && abs(delta) < 0.5)
            let headingFactor: Float = shouldShowOrbit ? (delta < 0 ? -1 : 1) : 1
            lastLat = currentLat
            return (shouldShowOrbit, headingFactor)
        }
        
        let (showISSOrbitNow, issHeadingFactor)       = updateHeading(for: iLat, lastLat: &issLastLat)
        let (showTSSOrbitNow, tssHeadingFactor)       = updateHeading(for: tLat, lastLat: &tssLastLat)
        let (showHubbleOrbitNow, hubbleHeadingFactor) = updateHeading(for: hLat, lastLat: &hubbleLastLat)
        
        // Set up the Sun based on the current subsolar coordinates.
        let subSolarCoordinates = AstroCalculations.getSubSolarCoordinates()
        globe.setUpTheSun(lat: subSolarCoordinates.latitude, lon: subSolarCoordinates.longitude)
        
        // Add orbit tracks if applicable.
        if addISS && showISSOrbitNow {
            globe.addOrbitTrackAroundTheGlobe(for: .iss, lat: iLat, lon: iLon, headingFactor: issHeadingFactor)
        }
        if addTSS && showTSSOrbitNow {
            globe.addOrbitTrackAroundTheGlobe(for: .tss, lat: tLat, lon: tLon, headingFactor: tssHeadingFactor)
        }
        if addHubble && showHubbleOrbitNow {
            globe.addOrbitTrackAroundTheGlobe(for: .hst, lat: hLat, lon: hLon, headingFactor: hubbleHeadingFactor)
        }
        
        // Add markers and viewing circles for each valid satellite.
        if addISS {
            globe.addISSMarker(lat: iLat, lon: iLon)
            globe.addISSViewingCircle(lat: iLat, lon: iLon)
        }
        if addTSS {
            globe.addTSSMarker(lat: tLat, lon: tLon)
            globe.addTSSViewingCircle(lat: tLat, lon: tLon)
        }
        if addHubble {
            globe.addHubbleMarker(lat: hLat, lon: hLon)
            globe.addHubbleViewingCircle(lat: hLat, lon: hLon)
        }
        
        // Autorotate the globe if the auto-rotate setting is enabled.
        globe.autoSpinGlobeRun(run: Globals.autoRotateGlobeEnabled)
    }
}
