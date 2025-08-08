//
//  Astronaut.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 7/9/16.
//  Updated by Michael on 8/7/2025.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import Foundation

/// Model that encapsulates an astronaut/comonaut.
///
/// Initialize an Astronaut instance with the member-wise initializer:
/// Astronaut(name: title: country: spaceCraft: launchDate: bio: launchVehicle: shortBioBlurb: image: twitter: mission: expedition:)
struct Astronaut: Decodable, Hashable {
    
    // MARK: - Properties
    
    let name: String
    let title: String
    let country: String
    let spaceCraft: String
    let launchDate: String
    let bio: String
    let launchVehicle: String
    let shortBioBlurb: String
    let image: String
    let twitter: String
    let mission: String
    let expedition: String
    
    // Map JSON keys to our property names
    private enum CodingKeys: String, CodingKey {
        case name, title, country
        case spaceCraft = "location"
        case launchDate = "launchdate"
        case bio = "biolink"
        case launchVehicle = "launchvehicle"
        case shortBioBlurb = "bio"
        case image = "biophoto"
        case twitter, mission, expedition
    }
    
    /// Returns the uppercase string of the country.
    private var countryFormatted: String {
        country.uppercased()
    }
    
    /// Returns a flag representing the country if available; otherwise, returns the formatted country.
    var flag: String {
        Globals.countryFlags[country] ?? countryFormatted
    }
    
    /// A short description combining the astronaut's name and flag.
    var shortAstronautDescription: String {
        "\(name)  \(flag)"
    }
    
    /// Returns the launch date formatted according to the output format specified in Globals.
    /// If conversion fails, returns an empty string.
    var launchDateFormatted: String {
        DateFormatter.convertDateString(launchDate,
                                        fromFormat: Globals.dateFormatStringEuropeanForm,
                                        toFormat: Globals.outputDateFormatStringShortForm) ?? ""
    }
    
    // MARK: - Methods

    /// Shared date formatter for European-form launch dates to avoid reallocation.
    private static let launchDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = Globals.dateFormatStringEuropeanForm
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
    
    /// Calculates the number of whole days an astronaut has been in space (today minus the launch date).
    /// Parsing uses the source `launchDate` format directly for accuracy.
    /// - Returns: Number of days since launch (non-negative).
    func numberOfDaysInSpace() -> Int {
        guard let startDate = Astronaut.launchDateFormatter.date(from: launchDate) else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, days)
    }
    
    // MARK: - JSON Parsing
    
    /// Parses JSON data containing current crew information and returns an array of `Astronaut`.
    /// Uses `JSONDecoder` with `Decodable` models instead of manual dictionary parsing.
    /// - Parameter data: The data returned from the API.
    /// - Returns: An optional array of Astronauts, or `nil` if decoding fails.
    static func parseCurrentCrew(from data: Data?) -> [Astronaut]? {
        guard let data = data else { return nil }
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(CurrentCrewResponse.self, from: data)
            // If the API's count mismatches, still return what we successfully decoded.
            if response.people.count != response.number {
                return response.people
            }
            return response.people
        } catch {
            return nil
        }
    }
}


// MARK: - API Response Model

private struct CurrentCrewResponse: Decodable {
    let number: Int
    let people: [Astronaut]
}


extension Astronaut: CustomStringConvertible, Comparable {
    static func < (lhs: Astronaut, rhs: Astronaut) -> Bool {
        lhs.name < rhs.name
    }
    
    static func == (lhs: Astronaut, rhs: Astronaut) -> Bool {
        lhs.name == rhs.name
    }
    
    /// Returns a comma-delimited string representation of the astronaut.
    var description: String {
        "\(name), \(title), \(flag)"
    }
}
