//
//  Dome3DWrapperViewController.swift
//  ISS Tracker
//
//  Created by Michael Stebel on 2/10/25.
//  Copyright © 2025 Michael Stebel Consulting, LLC. All rights reserved.
//

import UIKit
import SwiftUI

class Dome3DWrapperViewController: UIViewController {
    
    // These will be set before the segue.
    var startAz: Double = 0.0
    var startEl: Double = 0.0
    var maxAz: Double   = 0.0
    var maxEl: Double   = 0.0
    var endAz: Double   = 0.0
    var endEl: Double   = 0.0
    
    private var skyPoints: [SkyPoint] = []
    
    private let fontForTitle = Theme.nasa
    
    // Change status bar to light color for this VC.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(startAz)
        
        // Set the view controller's modal presentation style to fullScreen.
        self.modalPresentationStyle = .fullScreen
        
        // Set the background to a semi-transparent version of your custom color.
        view.backgroundColor = .issrttRed.withAlphaComponent(1.0)
        
        // Create skyPoints to pass to Dome3DView
        skyPoints = createSkypoints()
        
        // Create your SwiftUI Dome3DView with the passed skyPoints.
        let dome3DView = Dome3DView(skyPoints: skyPoints)
        let hostingController = UIHostingController(rootView: dome3DView)
        
        // Set the hosting controller's view background to clear so the parent's background shows through.
        hostingController.view.backgroundColor = .clear
        
        // Add the hosting controller as a child.
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        // Set constraints so that the hosted view fills the entire view controller.
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarAppearance()
    }

    private func setNavigationBarAppearance() {
        let titleFontSize = Theme.navigationBarTitleFontSize
        let barAppearance = UINavigationBarAppearance()
        barAppearance.backgroundColor = UIColor(named: Theme.tint)
        barAppearance.titleTextAttributes = [
            .font: UIFont(name: fontForTitle, size: titleFontSize) as Any,
            .foregroundColor: UIColor.white
        ]
        navigationItem.standardAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
    }
    
    private func createSkypoints() -> [SkyPoint] {
        var skyPoints: [SkyPoint] = []
        
        skyPoints.append(SkyPoint(azimuth: startAz, elevation: startEl))
        skyPoints.append(SkyPoint(azimuth: maxAz, elevation: maxEl))
        skyPoints.append(SkyPoint(azimuth: endAz, elevation: endEl))
        
        print(skyPoints)
        return skyPoints
    }
}
