//
//  LaunchAnimationViewController.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 10/31/16.
//  Updated by Michael on 8/7/2025.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

/// Animated launch screen
/// This is the entry view controller for the app. Animates then segues to the tracking view controller.
class LaunchAnimationViewController: UIViewController {
    
    // MARK: - Constants
    
    private let iconAnimationDuration: TimeInterval = 5.0
    private let iconAnimationRotationAngle: CGFloat = -CGFloat.pi / 6.0
    private let iconAnimationScaleFactor: CGFloat = 0.5
    private let titleAnimationDuration: TimeInterval = 5.0
    private let titleInitialScaleFactor: CGFloat = 0.33
    private let titleFinalScaleFactor: CGFloat = 4.0
    private let threeDInitialScaleFactor: CGFloat = 0.05
    private let issIconExtraOffset: CGFloat = 20.0
    private let segueToMainViewController = "mainViewControllerSegue"
    
    // MARK: - Properties
    
    private var issImageFinalTransform = CGAffineTransform.identity
    private var titleFinalTransform = CGAffineTransform.identity
    
    // MARK: - Outlets
    
    @IBOutlet private var ISSImage: UIImageView!
    @IBOutlet private var appNameTitleForLaunchAnimation: UILabel!
    
    // MARK: - Lifecycle Methods
    
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up initial states (e.g., hidden, alpha, and initial transform)
        setupInitialStates()
        
        // Calculate final transforms based on the view’s bounds
        setupISSImageFinalTransform()
        setupTitleFinalTransform()
        
        getVersionAndCopyrightData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateLaunchScreen()
    }
    
    // MARK: - Setup Methods
    
    /// Configure initial view states before the animation starts.
    private func setupInitialStates() {
        // ISSImage starts in its default state.
        ISSImage.transform = .identity
        ISSImage.alpha = 1.0
        
        // Configure appNameTitleForLaunchAnimation with a small scale, hidden, and transparent.
        appNameTitleForLaunchAnimation.transform = CGAffineTransform(scaleX: titleInitialScaleFactor, y: titleInitialScaleFactor)
        appNameTitleForLaunchAnimation.alpha = 0.0
        appNameTitleForLaunchAnimation.isHidden = true
    }
    
    /// Compute the final transform for the ISS icon animation.
    private func setupISSImageFinalTransform() {
        let xTranslation = view.bounds.width + issIconExtraOffset
        let yTranslation = view.bounds.height + issIconExtraOffset
        
        issImageFinalTransform = CGAffineTransform.identity
            .translatedBy(x: xTranslation, y: -yTranslation)
            .scaledBy(x: iconAnimationScaleFactor, y: iconAnimationScaleFactor)
            .rotated(by: iconAnimationRotationAngle)
    }
    
    /// Compute the final transform for the app name title animation.
    private func setupTitleFinalTransform() {
        // Starting from the initial scale, then applying the final scale multiplier.
        titleFinalTransform = CGAffineTransform(scaleX: titleInitialScaleFactor, y: titleInitialScaleFactor)
            .scaledBy(x: titleFinalScaleFactor, y: titleFinalScaleFactor)
    }
    
    // MARK: - Animation Method
    
    private func animateLaunchScreen() {
        UIView.animate(
            withDuration: iconAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.2,
            options: .curveEaseInOut,
            animations: { [weak self] in
                guard let self = self else { return }
                
                // Animate ISSImage out
                self.ISSImage.transform = self.issImageFinalTransform
                self.ISSImage.alpha = 0.0
                
                // Animate appNameTitleForLaunchAnimation into view
                self.appNameTitleForLaunchAnimation.isHidden = false
                self.appNameTitleForLaunchAnimation.alpha = 1.0
                self.appNameTitleForLaunchAnimation.transform = self.titleFinalTransform
            },
            completion: { [weak self] _ in
                guard let self = self else { return }
                self.performSegue(withIdentifier: self.segueToMainViewController, sender: self)
            }
        )
    }
    
    // MARK: - Helper Methods
    
    private func getVersionAndCopyrightData() {
        Globals.copyrightString = Bundle.main.humanReadableCopyright
        Globals.versionNumber = Bundle.main.appVersion
        Globals.buildNumber = Bundle.main.buildNumber
    }
    
    // Optionally, override didReceiveMemoryWarning if needed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
