//
//  Spacecraft Model.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 10/19/21.
//  Copyright © 2022-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

/// Model  for manned spacecraft
public enum Spacecraft: String, CaseIterable {
    
    case crewDragon  = "Crew Dragon"
    case dreamChaser = "Dream Chaser"
    case orion       = "Orion"
    case shenzhou    = "Shenzhou"
    case soyuz       = "Soyuz"
    case starliner   = "Starliner"
    
    var spacecraftImages: UIImage {
        switch self {
        case .crewDragon:
            return #imageLiteral(resourceName: "spacex-dragon-spacecraft-1")
        case .dreamChaser:
            return #imageLiteral(resourceName: "spacex-dragon-spacecraft-1")
        case .orion:
            return #imageLiteral(resourceName: "spacex-dragon-spacecraft-1")
        case .shenzhou:
            return #imageLiteral(resourceName: "Shenzhou")
        case .soyuz:
            return #imageLiteral(resourceName: "Soyuz-2")
        case .starliner:
            return #imageLiteral(resourceName: "starliner-spacecraft")
        }
    }
}
