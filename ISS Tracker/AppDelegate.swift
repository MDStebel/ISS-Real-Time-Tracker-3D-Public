//
//  AppDelegate.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 1/28/16.
//  Updated by Michael on 2/24/2025
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties

    var window: UIWindow?
    var referenceToViewController = TrackingViewController()
    var referenceToGlobeFullViewController = GlobeFullViewController()
    
    // ReviewPromptManager instance handles review scheduling logic.
    private lazy var reviewPromptManager = ReviewPromptManager(minimumPromptTime: 30, maximumPromptTime: 75)

    // MARK: - Application Lifecycle

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureGlobalSettings()
        reviewPromptManager.scheduleReviewRequest()
        return true
    }
    
    // MARK: - Orientation Control

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }
    
    // MARK: - Handle state changes

    private func configureGlobalSettings() {
        window?.tintColor = UIColor(named: Theme.tint)
    }

    // We only restore settings once during the foreground transition.
    func applicationWillEnterForeground(_ application: UIApplication) {
        SettingsDataModel.restoreUserSettings()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        SettingsDataModel.restoreUserSettings()
        if referenceToGlobeFullViewController.isViewLoaded {
            referenceToGlobeFullViewController.startUpdatingGlobe()
        }
    }
    
    // Handle state changes by stopping actions, saving settings, and stopping globe updates.
    func applicationWillResignActive(_ application: UIApplication) {
        handleAppStateChange()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        handleAppStateChange()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        handleAppStateChange()
    }

    private func handleAppStateChange() {
        referenceToViewController.stopAction()
        
        // Save user settings on a background thread to avoid blocking the main thread.
        DispatchQueue.global(qos: .background).async {
            SettingsDataModel.saveUserSettings()
        }
        
        if referenceToGlobeFullViewController.isViewLoaded {
            referenceToGlobeFullViewController.stopUpdatingGlobe()
        }
    }
}
