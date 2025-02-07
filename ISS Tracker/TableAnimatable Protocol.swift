//
//  Animatable Table Protocol.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 10/10/16.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

/// Protocol that provides animation of cells in a table
protocol TableAnimatable: AnyObject {
    func animate(table tableToAnimate: UITableView)
}

extension TableAnimatable {
    /// Default implementation.
    ///
    /// Animates the drawing of a table such that it looks springy.
    /// - Parameter tableToAnimate: Table to animate.
    func animate(table tableToAnimate: UITableView) {
        tableToAnimate.reloadData()
        let cells = tableToAnimate.visibleCells
        let tableViewHeight = tableToAnimate.bounds.size.height
        
        // Animation constants
        let animationDuration: TimeInterval = 1.75
        let delayIncrement: TimeInterval = 0.08
        let springDamping: CGFloat = 0.8
        let initialVelocity: CGFloat = 0
        
        DispatchQueue.main.async {
            for (index, cell) in cells.enumerated() {
                // Start the cell below the table
                cell.transform = CGAffineTransform(translationX: 0, y: tableViewHeight)
                
                UIView.animate(
                    withDuration: animationDuration,
                    delay: Double(index) * delayIncrement,
                    usingSpringWithDamping: springDamping,
                    initialSpringVelocity: initialVelocity,
                    options: .curveEaseInOut,
                    animations: {
                        cell.transform = .identity
                    },
                    completion: nil
                )
            }
        }
    }
}
