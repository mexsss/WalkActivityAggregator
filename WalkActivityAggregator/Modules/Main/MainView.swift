//
//  MainView.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import UIKit

protocol MainViewDelegate: class {
    func mainView(didSelectAnalyze view: MainView)
    func mainView(didSelectShare view: MainView)
}

class MainView: XIBView {
    
    // MARK: Outlets
    @IBOutlet
    private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet
    private weak var progressLabel: UILabel!
    @IBOutlet
    private weak var analyzeButton: UIButton!
    @IBOutlet
    private weak var shareButton: UIButton!
    
    // MARK: XIBView
    override func setupXIB() {
        super.setupXIB()
        
        activityIndicatorView.isHidden = true
        activityIndicatorView.startAnimating()
        progressLabel.text = ""
        analyzeButton.isEnabled = true
        shareButton.isHidden = true
    }
    
    // MARK: Public properties
    
    /// Delegate property to handle View's events
    ///
    weak var delegate: MainViewDelegate?
    
    /// Controls Activity indicator visibility
    ///
    var isActivityVisible: Bool = false {
        didSet {
            activityIndicatorView.isHidden = !isActivityVisible
        }
    }
    
    /// Controls Analyze button accessability. User shouldn't start new
    /// analysis until the current one is not completed or cancelled
    ///
    var isAnalyzeEnabled: Bool = true {
        didSet {
            analyzeButton.isEnabled = isAnalyzeEnabled
        }
    }
    
    /// Controls Share button visibility. User shouldn't access sharing
    /// until no anlysis results are ready
    ///
    var isSharingVisible: Bool = false {
        didSet {
            shareButton.isHidden = !isSharingVisible
        }
    }
    
    /// Controls Share button accessability. User shouldn't start new
    /// export until the current one is not completed
    ///
    var isSharingEnabled: Bool = true {
        didSet {
            shareButton.isEnabled = isSharingEnabled
        }
    }
    
    /// Displays progress in %. Range from 0.0 to 1.0. If the value is lower
    /// then 0.01, the text will be hidden.
    ///
    var progress: Float = 0.0 {
        didSet {
            guard progress != oldValue else { return }
            guard progress >= 0.01 else {
                progressLabel.text = ""
                return
            }
            progressLabel.text = "\(Int((progress*100)))%"
        }
    }
}

// MARK: Handlers
private extension MainView {
    @IBAction
    func didSelectAnalyze(_ sender: Any) {
        delegate?.mainView(didSelectAnalyze: self)
    }
    
    @IBAction
    func didSelectShare(_ sender: Any) {
        delegate?.mainView(didSelectShare: self)
    }
}

