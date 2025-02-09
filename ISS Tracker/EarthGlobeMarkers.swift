//
//  EarthGlobeMarkers.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 8/7/16.
//  Updated by Michael on 8/9/2025
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import SceneKit

/// Model for markers to be added to the Earth model
final class EarthGlobeMarkers {
    
    // MARK: - Properties
    
    let altitude: Float
    let image: String
    let node: SCNNode          // The SceneKit node for this marker
    let widthAndHeight: CGFloat
    
    // MARK: - Initializer
    
    /// Initialize a marker to be added to the Earth globe
    /// - Parameters:
    ///   - satellite: Type of satellite as a StationsAndSatellites enum
    ///   - image: Image name to use as marker
    ///   - lat: Latitude of the marker's position on Earth (in degrees)
    ///   - lon: Longitude of the marker's position on Earth (in degrees)
    ///   - isInOrbit: Flag indicating if the marker is above Earth (true) or on its surface (false)
    init(for satellite: StationsAndSatellites, using image: String, lat: Float, lon: Float, isInOrbit: Bool) {
        self.image = image
        
        // Adjust longitude for texture centering (textures are centered on 0,0)
        let adjustedLon = lon + Globals.ninetyDegrees
        
        // Compute marker dimensions and altitude based on whether it's in orbit or not
        let computedWidthAndHeight: CGFloat
        let computedAltitude: Float
        
        if !isInOrbit { // Footprint circle on the ground
            let scaling: CGFloat
            let heightAdj: Float
            
            if satellite == .hst {
                scaling = 1.2
                // The calculation below adjusts the height slightly based on the scaling factor
                heightAdj = 0.9 + Float(scaling / (.pi / 2)) / 10
            } else {
                scaling = 1.0
                heightAdj = 1.0
            }
            
            computedWidthAndHeight = Globals.footprintDiameter * scaling
            computedAltitude = Globals.globeRadiusFactor * Globals.globeRadiusMultiplierToPlaceOnSurface * heightAdj
        } else { // Marker represents a satellite in orbit
            switch satellite {
            case .iss:
                computedWidthAndHeight = Globals.issMarkerWidth
                computedAltitude = Globals.issAltitudeFactor
            case .tss:
                computedWidthAndHeight = Globals.tssMarkerWidth
                computedAltitude = Globals.tssAltitudeFactor
            case .hst:
                computedWidthAndHeight = Globals.hubbleMarkerWidth
                computedAltitude = Globals.hubbleAltitudeFactor
            case .none:
                computedWidthAndHeight = Globals.issMarkerWidth
                computedAltitude = Globals.issAltitudeFactor
            }
        }
        
        self.widthAndHeight = computedWidthAndHeight
        self.altitude = computedAltitude
        
        // Configure the marker's geometry and material
        let plane = SCNPlane(width: computedWidthAndHeight, height: computedWidthAndHeight)
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.diffuse.intensity = 1.0                // Brighter in daylight areas
        material.emission.contents = image
        material.emission.intensity = 0.75               // Slightly dimmer in nighttime areas
        material.isDoubleSided = true
        plane.firstMaterial = material
        
        // Initialize the node with the configured geometry
        self.node = SCNNode(geometry: plane)
        self.node.castsShadow = false
        
        // Map Earth coordinates (lat, adjustedLon, altitude) to xyz coordinates on the globe
        let position = EarthGlobe.transformLatLonCoordinatesToXYZ(lat: lat, lon: adjustedLon, alt: computedAltitude)
        self.node.position = position
        
        // Compute the node's orientation using Euler angles
        // Note: Pitch rotates about the x-axis, yaw about the y-axis, and roll about the z-axis.
        let pitch = -lat * Float(Globals.degreesToRadians)
        let yaw = lon * Float(Globals.degreesToRadians)
        let roll: Float = 0
        self.node.eulerAngles = SCNVector3(x: pitch, y: yaw, z: roll)
    }
    
#if !os(watchOS)
    /// Adds a pulsing animation to the marker node.
    /// This effect is not used in the watchOS version.
    func addPulseAnimation() {
        let scaleMin: Float = 0.80
        let scaleMax: Float = 1.05
        let animation = CABasicAnimation(keyPath: "scale")
        animation.fromValue = SCNVector3(x: scaleMin, y: scaleMin, z: scaleMin)
        animation.toValue = SCNVector3(x: scaleMax, y: scaleMax, z: scaleMax)
        animation.duration = 0.25
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Using a specific key helps if you need to reference or remove the animation later
        self.node.addAnimation(animation, forKey: "pulse")
    }
#endif
}
