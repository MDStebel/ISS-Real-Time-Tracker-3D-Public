//
//  GlobeView.swift
//  ISS Watch
//
//  Created by Michael Stebel on 8/26/21.
//  Copyright © 2021-2025 ISS Real-Time Tracker. All rights reserved.
//

import SwiftUI
import SceneKit

struct GlobeView: View {
    
    // Get the current phase of the scene
    @Environment(\.scenePhase) private var scenePhase
    
    // We're observing our view model
    @StateObject private var vm = PositionViewModel()
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                // MARK: Globe
                
                // Render the globe. This will update continually as new coordinates are received from the view model.
                SceneView(scene: vm.globeScene,
                          pointOfView: vm.globeMainNode,
                          options: [.allowsCameraControl]
                )
                
                // Show progress indicator when starting up/resetting
                if vm.isStartingUp {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5) // Larger progress indicator
                    VStack {
                        Text("Loading...")
                            .font(.subheadline) // Adjust font style for better visibility
                            .opacity(0.75)
                            .minimumScaleFactor(0.7)
                            .padding(.top, 15) // Add some spacing between the text and top of screen
                        Spacer()
                    }
                }
                
                // MARK: Buttons
                
                VStack {
                    Spacer() // we want the buttons at the bottom of the screen
                    
                    // Button group
                    HStack(spacing: -35) {
                        Button(action: {
                            vm.reset()                              // Reset globe
                        })
                        {
                            Image(systemName: vm.isStartingUp ? "arrow.triangle.2.circlepath" : "arrow.circlepath")
                                .contentTransition(.symbolEffect(.replace.wholeSymbol))
                        }
                        .withSmallButtonModifier
                        
                        Button(action: {
                            vm.spinEnabled.toggle()                 // Toggle globe rotation
                        })
                        {
                            Image(systemName: vm.spinEnabled ? "rotate.3d.fill" : "rotate.3d")
                                .contentTransition(.symbolEffect(.replace.wholeSymbol))
                        }
                        .withSmallButtonModifier
                        
                        NavigationLink(
                            destination: DetailView(vm: vm)         // Show detail view with data from our view model
                        )
                        {
                            Image(systemName: "tablecells")
                                .scaleEffect(0.9)
                        }
                        .withSmallButtonModifier
                        
                        NavigationLink(
                            destination: CrewView()                 // Show crew view
                        )
                        {
                            Image(systemName: "person.fill")
                        }
                        .withSmallButtonModifier
                    }
                    .padding([.horizontal])
                    .padding([.bottom], 3.0)
                }
                // Pop up an alert if there was an error fetching data
                .alert(isPresented: $vm.wasError) {
                    Alert(title: Text(vm.errorForAlert?.title ?? "Oops!"),
                          message: Text(vm.errorForAlert?.message ?? "Can't get data.")
                    )
                }
            }
            .ignoresSafeArea(edges: [.vertical])
            .navigationTitle("Globe")
            .navigationBarTitleDisplayMode(.inline)     // We want the small navigation title
            
            // MARK: Handle lifecycle events
            
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    // The scene has become active, so start updating
                    vm.start()
                case .inactive, .background:
                    // The app has become inactive, so stop updating
                    vm.stop()
                @unknown default:
                    fatalError("The app has entered an unknown state.")
                }
            }
        }
    }
}
    
struct GlobeView_Previews: PreviewProvider {
    static var previews: some View {
        GlobeView()
    }
}
