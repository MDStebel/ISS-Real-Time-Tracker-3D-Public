//
//  CGColor to Hex Extension.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 4/17/19.
//  Copyright © 2019-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

// Extension to CGColor that converts a CGColor to a hex string representation with or without alpha
extension CGColor {
    /// A convenience property that returns the hex string for this color's RGB components
    /// *without* the alpha channel.
    ///
    /// If the color isn't in an RGB-compatible space or has an unexpected number of components,
    /// this returns `nil`.
    var hexString: String? {
        return hexString(includeAlpha: false)
    }
    
    /// Returns a hex string representation of the color’s components in `RRGGBB` or `RRGGBBAA` format.
    ///
    /// - Parameter includeAlpha: Whether the alpha channel should be included.
    /// - Returns: An optional hex string, or `nil` if the color space is not supported.
    func hexString(includeAlpha: Bool = false) -> String? {
        // Make sure we have an RGB-based color space and at least 3 color components (R, G, B)
        guard let components = components,
              numberOfComponents >= 3,
              let colorSpace = colorSpace, colorSpace.model == .rgb else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        // For alpha, fall back to 1.0 if it’s missing (e.g., some grayscale colors might have only 2 components)
        let a: Float = (components.count >= 4) ? Float(components[3]) : 1.0
        
        if includeAlpha {
            return String(
                format: "%02lX%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255),
                lroundf(a * 255)
            )
        } else {
            return String(
                format: "%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255)
            )
        }
    }
}
