//
//  Date Conversions Extension.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 5/27/16.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

/// Extension to DateFormatter to convert dates. Conforms to StringDateConversions protocol.
extension DateFormatter {
    
    /// Converts a date string from one format to another.
    /// - Parameters:
    ///   - dateString: The original date string.
    ///   - fromFormat: Format the date string is currently in.
    ///   - toFormat: Desired format for output date string.
    /// - Returns: An optional date string in the new format.
    static func convertDateString(_ dateString: String,
                                  fromFormat: String,
                                  toFormat: String) -> String? {
        let originalFormatter = DateFormatter()
        originalFormatter.dateFormat = fromFormat
        
        guard let parsedDate = originalFormatter.date(from: dateString) else {
            return nil
        }
        
        let targetFormatter = DateFormatter()
        targetFormatter.dateFormat = toFormat
        
        return targetFormatter.string(from: parsedDate)
    }
    
    /// Converts a `Date` to a string representation using the specified format.
    /// - Parameters:
    ///   - date: The `Date` to be converted.
    ///   - format: The desired output format.
    /// - Returns: A date string in the given format.
    static func string(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
