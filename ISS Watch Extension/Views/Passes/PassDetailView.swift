//
//  PassDetailView.swift
//  ISS Watch
//
//  Created by Michael Stebel on 6/11/24.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import SwiftUI

struct PassDetailView: View {
    
    var pass: Passes.Pass
    var station: StationsAndSatellites
    
    @StateObject private var vm = PassesViewModel()
    
    var body: some View {
        
        // Header info
        let dm = Date(timeIntervalSince1970: pass.startUTC).formatted(.dateTime.month(.abbreviated)) // Month
        let dw = Date(timeIntervalSince1970: pass.startUTC).formatted(.dateTime.weekday())           // Day of the week
        let dd = Date(timeIntervalSince1970: pass.startUTC).formatted(.dateTime.day())               // Day of the month
        let tm = getCountdownText()                                                                  // Minutes to pass start
        let du = timeString(from: pass.duration)
        let mg = pass.mag != RatingSystem.unknown.rawValue ? String(pass.mag) : "N/A"
        let fv = Date(timeIntervalSince1970: pass.startVisibility).formatted(date: .omitted, time: .shortened)
        
        // Start
        let st = Date(timeIntervalSince1970: pass.startUTC).formatted(date: .omitted, time: .shortened)
        let sa = String(format: "%.0f%", pass.startAz) + Globals.degreeSign
        let sc = String(pass.startAzCompass)
        let se = String(format: "%.1f%", pass.startEl) + Globals.degreeSign
       
        // Max
        let mt = Date(timeIntervalSince1970: pass.maxUTC).formatted(date: .omitted, time: .shortened)
        let ma = String(format: "%.0f%", pass.maxAz) + Globals.degreeSign
        let mc = String(pass.maxAzCompass)
        let me = String(format: "%.1f%", pass.maxEl) + Globals.degreeSign
        
        // End
        let et = Date(timeIntervalSince1970: pass.endUTC).formatted(date: .omitted, time: .shortened)
        let ea = String(format: "%.0f%", pass.endAz) + Globals.degreeSign
        let ec = String(pass.endAzCompass)
        let ee = String(format: "%.1f%", pass.endEl ?? 0.0) + Globals.degreeSign                     // Ending elevation isn't always returned, for some reason
        
        ZStack {
            gradientBackground(with: [.issrttRed, .ISSRTT3DGrey])
            
            ScrollView {
                VStack {
                    
                    DetailSubheading(heading: "General")
                    
                    if pass.mag != RatingSystem.unknown.rawValue && station == .iss  {
                        passQualityView(for: pass.mag)
                    }
                    
                    StatView(label: "Date", stat: dw + ", " + dm + " " + dd)
                    StatView(label: "T-Minus", stat: tm)
                    StatView(label: "First vis.", stat: fv)
                    StatView(label: "Duration", stat: du)
                    StatView(label: "Magnitude", stat: mg)
                    
                    DetailSubheading(heading: "Pass Start")
                    
                    StatView(label: "Time", stat: st)
                    StatView(label: "Azimuth", stat: sa)
                    StatView(label: "Compass", stat: sc)
                    StatView(label: "Elevation", stat: se)
                    
                    DetailSubheading(heading: "Max Viewing")
                    
                    StatView(label: "Time", stat: mt)
                    StatView(label: "Azimuth", stat: ma)
                    StatView(label: "Compass", stat: mc)
                    StatView(label: "Elevation", stat: me)
                    
                    DetailSubheading(heading: "Pass End")
                    
                    StatView(label: "Time", stat: et)
                    StatView(label: "Azimuth", stat: ea)
                    StatView(label: "Compass", stat: ec)
                    StatView(label: "Elevation", stat: ee)
                    
                }
                .padding(2)
            }
            .navigationTitle("Pass Viewing")
        }
    }
    
    // MARK: - Helper functions
    
    /// Compute time until the pass starts.
    /// We use compactMap to safely handle the optional values and eliminate nil components.
    /// Instead of handling spaces manually, compactMap and joined(separator:) allow us to join non-nil components with a space only where needed.
    /// - Returns: Formatted string representation of the time remaining in days hours minutes
    private func getCountdownText() -> String {
        let diff = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: Date(timeIntervalSince1970: pass.startUTC))
        
        let days = (diff.day ?? 0) > 0 ? "\(diff.day!)d" : nil
        let hours = (diff.hour ?? 0) > 0 ? "\(diff.hour!)h" : nil
        let minutes = (diff.minute ?? 0) > 0 ? "\(diff.minute!)m" : nil
        
        let timeComponents = [days, hours, minutes].compactMap { $0 }
        
        return timeComponents.joined(separator: " ")
    }
    
    /// Generate a string of minutes and seconds from number of seconds.
    /// - Parameter seconds: Number of seconds as integer
    /// - Returns: String representation
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%dm %02ds", minutes, remainingSeconds)
    }
    
    /// Return 1-4 stars in a view based on the magnitude of the pass
    /// - Parameter pass: The pass
    /// - Returns: A view consisting of an HStack of rating stars
    private func passQualityView(for magnitude: Double) -> some View {
        HStack(spacing: 4) {
            Text("Quality:")
                .font(.caption)
                .fontWeight(.bold)
                .opacity(1.0)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            HStack(spacing: 2) {
                ForEach(0 ..< 4) { star in
                    Image(star < (vm.getNumberOfStars(forMagnitude: magnitude) ?? 0) ? .icons8StarFilledWhite : .starUnfilledWatch)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15)
                }
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 0, leading: 2, bottom: -4, trailing: 0))
    }
}

#Preview {
    PassDetailView(pass: Passes.Pass(startAz: 270, startAzCompass: "W", startEl: 20, startUTC: 1720659580.0, maxAz: 355, maxAzCompass: "NNE", maxEl: 50, maxUTC: 1720659585.0, endAz: 10, endAzCompass: "NNE", endUTC: 1720659590.0, endEl: 5.0, mag: -2.1, duration: 300, startVisibility: 1728744955), station: .iss)
}
