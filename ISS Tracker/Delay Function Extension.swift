//
//  Delay Function.swift
//
//  Created by Michael Stebel on 12/4/15.
//  Copyright © 2015-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Schedules the given closure to be executed on the main queue after a specified delay.
    ///
    /// - Parameters:
    ///   - delay: The delay (in seconds) before executing the closure.
    ///   - closure: The closure to execute after the delay.
    func delay(_ delay: TimeInterval, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
