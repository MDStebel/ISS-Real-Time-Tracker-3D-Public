//
//  AppDelegate.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 1/28/16.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit
import StoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties

    var window: UIWindow?
    var referenceToViewController = TrackingViewController()
    var referenceToGlobeFullViewController = GlobeFullViewController()
    
    private var reviewRequestTimer: Timer?
    
    private let minimumReviewPromptTime: UInt32 = 20
    private let maximumReviewPromptTime: UInt32 = 80

    // MARK: - Methods

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureGlobalSettings()
        scheduleReviewRequest(shortestTime: minimumReviewPromptTime, longestTime: maximumReviewPromptTime)
        return true
    }

    private func configureGlobalSettings() {
        window?.tintColor = UIColor(named: Theme.tint)
        Globals.thisDevice = UIDevice.current.model
        Globals.isIPad = Globals.thisDevice.hasPrefix("iPad")
    }

    private func scheduleReviewRequest(shortestTime: UInt32, longestTime: UInt32) {
        guard shortestTime < longestTime else {
            print("Invalid time range: shortestTime must be less than longestTime.")
            return
        }
        
        // Invalidate any existing timer before creating a new one
        reviewRequestTimer?.invalidate()
        
        let timeInterval = TimeInterval(UInt32.random(in: shortestTime..<longestTime))
        
        // Assign the new timer to the property
        reviewRequestTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(handleTimerFired), userInfo: nil, repeats: false)
    }

    @objc private func handleTimerFired() {
        reviewRequestTimer?.invalidate() // Invalidate the timer when it fires
        reviewRequestTimer = nil         // Clear the reference to the timer
        
        // Call the review request method
        requestReview()
    }

    @objc private func requestReview() {
        // Instead of directly accessing window?.windowScene, which might be nil, we retrieve the first available UIWindowScene from UIApplication.shared.connectedScenes.
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            print("Unable to retrieve windowScene for review request.")
            return
        }
        
        AppStore.requestReview(in: windowScene)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        handleAppStateChange()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        handleAppStateChange()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        SettingsDataModel.restoreUserSettings()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        SettingsDataModel.restoreUserSettings()
        if referenceToGlobeFullViewController.isViewLoaded {
            referenceToGlobeFullViewController.startUpdatingGlobe()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        handleAppStateChange()
    }

    private func handleAppStateChange() {
        referenceToViewController.stopAction()
        SettingsDataModel.saveUserSettings()
        if referenceToGlobeFullViewController.isViewLoaded {
            referenceToGlobeFullViewController.stopUpdatingGlobe()
        }
    }
}
