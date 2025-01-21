//
//  CrewMemberDetailView.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 11/18/17.
//  Copyright © 2016-2025 ISS Real-Time Tracker. All rights reserved.
//

import UIKit

class CrewMemberDetailView: UIView {

    // MARK: - Properties
    
    /// Contains the Twitter URL passed from the VC. If it exists, the button will be shown; otherwise, it will be hidden.
    var twitterHandleURL: String? {
        didSet {
            twitterButton.isHidden = (twitterHandleURL?.isEmpty ?? true)
        }
    }
    
    private let cornerRadius = Theme.cornerRadius
    private let shortBioBackgroundColor = UIColor(named: Theme.popupBgd)?.cgColor
    
    // MARK: - Outlets
    
    @IBOutlet weak var shortBioInforomation: UILabel!
    @IBOutlet weak var shortBioName: UILabel!
    @IBOutlet private weak var fullBioButton: UIButton!
    @IBOutlet private weak var twitterButton: UIButton!
    
    // MARK: - Methods
    
    override func layoutIfNeeded() {
        layoutIfNeeded()
    }
    
    /// Opens the crew member's Twitter profile in the Twitter app or Safari.
    @IBAction private func goToTwitter() {
        guard
            let urlString = twitterHandleURL,
            !urlString.isEmpty
        else { return }

        let twitterHandle = urlString.removingPrefix("https://twitter.com/")
        
        guard !twitterHandle.isEmpty, twitterHandle.count > 3 else { return }

        guard
            let appURL = URL(string: "twitter://user?screen_name=\(twitterHandle)"),
            let webURL = URL(string: "https://twitter.com/\(twitterHandle)")
        else { return }

        let application = UIApplication.shared
        
        if application.canOpenURL(appURL) {
            application.open(appURL)
        } else {
            application.open(webURL)
        }
    }
    
    @IBAction private func close(_ sender: Any) {
        removeFromSuperview()
    }
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        layer.cornerRadius    = cornerRadius
        layer.shadowColor     = UIColor.black.cgColor
        layer.shadowRadius    = 4.0
        layer.shadowOpacity   = 0.6
        layer.shadowOffset    = CGSize(width: 0.0, height: 3.0)
        layer.backgroundColor = shortBioBackgroundColor
    }
}
