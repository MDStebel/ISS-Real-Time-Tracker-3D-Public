//
//  DataCellView.swift
//  ISS Watch
//
//  Created by Michael Stebel on 9/17/21.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import SwiftUI

/// Custom cell view for coordinates data
struct DataCellView: View {
    
    let title: String
    let altitude: Float?
    let altitudeInKm: String?
    let altitudeInMi: String?
    let latitude: String
    let longitude: String
    let sidebarColor: Color
    let target: StationsAndSatellites
    
    private let max: Float = Globals.hubbleMaxAltitudeInKM   // Scale max
    private let min: Float = Globals.tssMinAltitudeInKM      // Scale min
    private let multiplier: Float = 20
    
    var body: some View {
        HStack {
            // MARK: - Sidebar area
            Rectangle()
                .frame(width: 6)
                .foregroundStyle(sidebarColor)
            
            VStack {
                // MARK: - Title area
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.gray)
                    Spacer()
                }
                
                Spacer()
                
                // MARK: - Data area
                HStack {
                    
                    // MARK: - Conditional view shows altitude scale for satellites only
                    /// Only show the altitude indicator if there's an altitude available
                    /// If not, we'll assume we're showing the subsolar point, so show the Sun
                    if let altKm = altitudeInKm, let altMi = altitudeInMi, let alt = altitude {
                        
                        let range             = max - min                       // Scale range
                        let boundedAlt        = fmin(fmax(alt, min), max)       // Clamp it to keep within scale range
                        let normalizedAlt     = (boundedAlt - min) / range
                        let yOffsetComputed   = -CGFloat(normalizedAlt * multiplier) + 6
                        
                        // Show the altitude scale
                        Image("Y-Axis")
                            .offset(x: -4, y: -4)
                        
                        // Movable indicator with values
                        HStack(spacing: -4) {
                            Image(systemName: "arrowtriangle.left.fill")
                                .resizable()
                                .frame(width: 7, height: 6)
                                .foregroundStyle(sidebarColor)
                                .offset(x: -7.5)
                            
                            VStack(alignment: .leading, spacing: -3) {
                                
                                Text("ALT")
                                    .font(.system(size: 10.0))
                                    .foregroundStyle(sidebarColor)
                                    .bold()
                                    .offset(y: -1.5)
                                
                                Text(altKm)
                                    .withMDSDataLabelModifier
                                
                                Text(altMi)
                                    .withMDSDataLabelModifier
                            }
                            .offset(x: -3, y: 1.5)
                        }
                        .offset(y: yOffsetComputed)   // This will position the alt on the scale
                        
                    // Show the Sun icon if this is not a satellite
                    } else {
                        Image(systemName: "sun.max.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.yellow)
                            .offset(x: 1, y: -5)
                            .frame(width: 40, height: 40, alignment: .leading)
                    }
                    
                    // MARK: - Coordinates area
                    VStack {
                        HStack {
                            Spacer()
                            Text(latitude)
                                .withCoordinatesTextModifier
                        }
                        .offset(x: 0)
                        
                        HStack {
                            Spacer()
                            Text(longitude)
                                .withCoordinatesTextModifier
                        }
                        .offset(x: 0)
                    }
                }
            }
            .padding([.vertical], 2)
            .padding([.leading], 1)
            .padding([.trailing], 6)
        }
        .frame(height: 70)
        .background(Color.ISSRTT3DBackground)
        .cornerRadius(10.0)
    }
}

struct DataCellView_Previews: PreviewProvider {
    static var previews: some View {
        DataCellView(title: "Title", altitude: 435, altitudeInKm: "450 km", altitudeInMi: "249 mi", latitude: "155°55'55\"N", longitude: "177°48'48\"E", sidebarColor: .blue, target: .iss)
    }
}
