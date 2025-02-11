//
//  Dome3DWrapperViewController.swift
//  ISS Tracker
//
//  Created by Michael Stebel on 2/10/25.
//  Copyright © 2025 Michael Stebel Consulting, LLC. All rights reserved.
//

import UIKit
import SwiftUI

// Make sure your Dome3DView and SkyPoint are defined somewhere in your project.
// For example, you might have them in Dome3DView.swift.

import UIKit
import SwiftUI

class Dome3DWrapperViewController: UIViewController {
    // This property will be set before the segue.
    var skyPoints: [SkyPoint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create your SwiftUI Dome3DView with the passed skyPoints.
        let dome3DView = Dome3DView(skyPoints: skyPoints)
        let hostingController = UIHostingController(rootView: dome3DView)
        
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}
