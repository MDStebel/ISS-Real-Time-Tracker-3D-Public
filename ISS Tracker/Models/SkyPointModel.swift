//
//  SkyPointModel.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 2/27/25.
//  Copyright © 2025 Michael Stebel Consulting, LLC. All rights reserved.
//

import Foundation

/// A simple struct to hold sky coordinates.
struct SkyPoint {
    var azimuth: Double   // in degrees, where 0° is North
    var elevation: Double // in degrees, where 0° is at the horizon and 90° is the zenith
}
