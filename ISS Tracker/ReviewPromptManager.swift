//
//  ReviewPromptManager.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 2/9/25.
//  Updated by Michael on 7/1/2025.
//  Copyright © 2025 Michael Stebel Consulting, LLC. All rights reserved.
//

import UIKit
import StoreKit
import os.log

/// A manager class to handle scheduling and presenting the review prompt.
class ReviewPromptManager {
    private var reviewRequestWorkItem: DispatchWorkItem?
    
    private let minimumPromptTime: TimeInterval
    private let maximumPromptTime: TimeInterval
    
    init(minimumPromptTime: TimeInterval = 30, maximumPromptTime: TimeInterval = 75) {
        self.minimumPromptTime = minimumPromptTime
        self.maximumPromptTime = maximumPromptTime
    }
    
    /// Schedules a review request after a random delay between minimumPromptTime and maximumPromptTime.
    @MainActor func scheduleReviewRequest() {
        // Cancel any previously scheduled request
        reviewRequestWorkItem?.cancel()
        
        guard minimumPromptTime < maximumPromptTime else {
            os_log("Invalid time range: minimumPromptTime must be less than maximumPromptTime.")
            return
        }
        
        // Generate a random delay within the range
        let randomDelay = TimeInterval(UInt32.random(in: UInt32(minimumPromptTime)..<UInt32(maximumPromptTime)))
        os_log("Scheduling review request in %{public}.2f seconds", randomDelay)
        
        // Create a DispatchWorkItem to request review after the delay.
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.requestReview()
            }
        }
        reviewRequestWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay, execute: workItem)
    }
    
    /// Cancels any scheduled review request.
    func cancelReviewRequest() {
        reviewRequestWorkItem?.cancel()
        reviewRequestWorkItem = nil
    }
    
    /// Requests an App Store review.
    @MainActor private func requestReview() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            os_log("Unable to retrieve windowScene for review request.")
            return
        }
        
        AppStore.requestReview(in: windowScene)
    }
}
