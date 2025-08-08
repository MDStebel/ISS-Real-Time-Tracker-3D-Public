//
//  AlertHandler Extension.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 11/9/15.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved..
//

import UIKit

extension UIViewController {
    
    /// Convenience method to display a simple alert with an optional completion handler
    func showAlert(title: String = NSLocalizedString("Alert", comment: "Default alert title"),
                   message: String,
                   buttonTitle: String = NSLocalizedString("OK", comment: "OK button"),
                   completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: buttonTitle, style: .default) { _ in
                completion?()
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    /// Display alert when unable to connect to a server
    func showNoInternetAlert() {
        showAlert(title: NSLocalizedString("Can't connect to the server.", comment: ""),
                  message: NSLocalizedString("Check your Internet connection\nand try again.", comment: ""))
    }
}
