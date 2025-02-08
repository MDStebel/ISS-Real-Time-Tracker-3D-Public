//
//  Astronaut.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 7/9/16.
//  Updated by Michael on 2/7/2025.
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
    
    /// Calculates the number of days an astronaut has been in space (today minus the launch date).
    /// If the launch date is invalid, returns 0.
    /// - Returns: Number of days since launch.
    func numberOfDaysInSpace() -> Int {
        let todaysDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Globals.outputDateFormatStringShortForm
        
        guard let startDate = dateFormatter.date(from: launchDateFormatted) else {
            return 0
        }
        
        let timeInterval = todaysDate.timeIntervalSince(startDate)
        return Int(timeInterval / Globals.numberOfSecondsInADay)
    }
    
    // MARK: - JSON Parsing
    
    /// Parses JSON data containing current crew information and returns an array of Astronauts.
    /// - Parameter data: The data returned from the API.
    /// - Returns: An optional array of Astronauts.
    static func parseCurrentCrew(from data: Data?) -> [Astronaut]? {
        guard let data = data else { return nil }
        
        // Type alias for a dictionary to make code easier to read.
        typealias JSONDictionary = [String: Any]
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary,
                  let numberOfAstronauts = json["number"] as? Int,
                  let astronautsArray = json["people"] as? [JSONDictionary] else {
                return nil
            }
            
            var crew = [Astronaut]()
            
            for astronaut in astronautsArray {
                guard let name          = astronaut["name"] as? String,
                      let title         = astronaut["title"] as? String,
                      let country       = astronaut["country"] as? String,
                      let spaceCraft    = astronaut["location"] as? String,
                      let launchDate    = astronaut["launchdate"] as? String,
                      let bio           = astronaut["biolink"] as? String,
                      let shortBioBlurb = astronaut["bio"] as? String,
                      let image         = astronaut["biophoto"] as? String,
                      let twitter       = astronaut["twitter"] as? String,
                      let mission       = astronaut["mission"] as? String,
                      let launchVehicle = astronaut["launchvehicle"] as? String,
                      let expedition    = astronaut["expedition"] as? String else {
                    return nil
                }
                
                let astronautObj = Astronaut(name: name,
                                             title: title,
                                             country: country,
                                             spaceCraft: spaceCraft,
                                             launchDate: launchDate,
                                             bio: bio,
                                             launchVehicle: launchVehicle,
                                             shortBioBlurb: shortBioBlurb,
                                             image: image,
                                             twitter: twitter,
                                             mission: mission,
                                             expedition: expedition)
                crew.append(astronautObj)
            }
            
            // Ensure the number of parsed astronauts matches the expected count.
            guard crew.count == numberOfAstronauts else { return nil }
            return crew
        } catch {
            return nil
        }
    }
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
