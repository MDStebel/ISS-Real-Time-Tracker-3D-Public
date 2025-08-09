//
//  Delay Function.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 12/4/15.
//  Updated by Michael on 8/8/2025.
//  Copyright © 2015-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Schedule a closure to run on the main actor after a delay. Returns a `DispatchWorkItem` so you can cancel if needed.
    ///
    /// - Parameters:
    ///   - seconds: How many seconds to wait before executing.
    ///   - block: The closure to execute after the delay.
    /// - Returns: The scheduled `DispatchWorkItem` which can be cancelled via `workItem.cancel()`.
    @discardableResult
    @MainActor
    func schedule(after seconds: TimeInterval, perform block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: workItem)
        return workItem
    }

    /// Async/await-friendly suspension on the main actor for UI workflows.
    /// Prefer this in modern code when you don't need cancellation via `DispatchWorkItem`.
    @MainActor
    func sleepUI(for seconds: TimeInterval) async {
        #if compiler(>=5.9)
        try? await Task.sleep(for: .seconds(seconds))
        #else
        let ns = UInt64(max(0, seconds) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: ns)
        #endif
    }

    /// Backwards-compatibility wrapper. Use `schedule(after:perform:)` instead.
    @available(*, deprecated, renamed: "schedule(after:perform:)")
    @MainActor
    func delay(_ seconds: TimeInterval, closure: @escaping () -> Void) {
        _ = schedule(after: seconds, perform: closure)
    }
}
