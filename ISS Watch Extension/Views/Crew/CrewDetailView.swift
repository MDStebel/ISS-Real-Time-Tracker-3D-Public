//
//  CrewDetailView.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 4/13/24.
//  Updated by Michael on 7/31/2025.
//  Copyright © 2024-2025 ISS Real-Time Tracker. All rights reserved.
//

import SwiftUI

struct CrewDetailView: View {
    
    // MARK: - Properties
    
    let crewMember: Crews.People
    
    private let corner = 15.0
    
    var body: some View {
        ZStack {
            gradientBackground(with: [.issrttRed, .ISSRTT3DGrey])
            
            ScrollView {
                ZStack {
                    Circle()
                        .fill(Gradient(colors: [.ISSRTT3DRed.opacity(0.95), .blue.opacity(0.80), .white.opacity(0.25), ]))
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    AsyncImage(url: URL(string: crewMember.biophoto)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .scaleEffect(x: 2, y: 2, anchor: .center)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .padding(EdgeInsets(top: 0, leading: 25, bottom: 0, trailing: 25))
                        case .failure(_):
                            Image(.astronautPlaceholder)
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .padding(EdgeInsets(top: 0, leading: 25, bottom: 0, trailing: 25))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                VStack {
                    
                    // Date calculations
                    let launchdate = DateFormatter.convertDateString(crewMember.launchdate, fromFormat: Globals.dateFormatStringEuropeanForm, toFormat: Globals.outputDateFormatStringShortForm) ?? ""
                    let numDays = numberOfDaysInSpace(since: launchdate)
                    
                    DetailSubheading(heading: "General")
                    
                    StatView(label: "Name", stat: crewMember.name)
                    StatView(label: "Country", stat: crewMember.country)
                    
                    DetailSubheading(heading: "On Station")
                    
                    StatView(label: "Title", stat: crewMember.title)
                    if crewMember.expedition != "N/A" {
                        StatView(label: "Expediiton", stat: crewMember.expedition)
                    }
                    StatView(label: "Days in space", stat: "\(numDays)")
                    
                    DetailSubheading(heading: "Launch")
                    
                    StatView(label: "Date", stat: launchdate)
                    StatView(label: "Mission", stat: crewMember.mission)
                    StatView(label: "Vehicle", stat: crewMember.launchvehicle)
                    
                    DetailSubheading(heading: "Biography")
                    
                    Text(crewMember.bio)
                        .font(.caption)
                        .foregroundColor(.white.opacity(1))
                        .padding(EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 1))
                }
                .padding(2)
            }
            .navigationTitle(crewMember.name)
        }
    }
    
    // MARK: - Helper functions
    
    /// Helper method to calculate the number of days an astronaut has been in space (today - launch date).
    /// If there's an error in the data, this will detect it and return 0 days.
    /// - Returns: Number of days since launch.
    func numberOfDaysInSpace(since launch: String) -> Int {
        let todaysDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Globals.outputDateFormatStringShortForm
        
        if launch != "" {
            let startDate = dateFormatter.date(from: launch)
            return Int(Float(todaysDate.timeIntervalSince(startDate!)) / Float(Globals.numberOfSecondsInADay ))
        } else {
            return 0
        }
    }
}

#Preview {
    CrewDetailView(
        crewMember: Crews.People(
            name: "Oleg Kononenko",
            biophoto: "https://issrttapi.com/kononenko.jpeg",
            country: "Russia",
            launchdate: "2023-09-15",
            title: "Commander",
            location: "International Space Station",
            bio: "Oleg Dmitriyevich Kononenko is a Russian cosmonaut. He has flown to the International Space Station four times. He accumulated over 736 days in orbit during his four long duration flights, the longest time in space of any currently active cosmonaut or astronaut.",
            biolink: "https://en.wikipedia.org/wiki/Oleg_Kononenko",
            twitter: "",
            mission: "Soyuz MS-24",
            launchvehicle: "Soyuz",
            expedition: "71"
        )
    )
}
