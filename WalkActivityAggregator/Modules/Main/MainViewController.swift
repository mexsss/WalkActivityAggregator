//
//  MainViewController.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: Private properties
    private var customView: MainView {
        return view as! MainView
    }
    
    private let manager = WalkActivityManager()
    
    // MARK: UIViewController
    override func loadView() {
        let viewHolder = MainView()
        viewHolder.delegate = self
        view = viewHolder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
    }
}

// MARK: WalkActivityManagerDelegate
extension MainViewController: WalkActivityManagerDelegate {
    func walkActivityManager(_ manager: WalkActivityManager, didChangeProgress progress: Float) {
        displayAnalysisProgress(progress)
    }
    
    func walkActivityManager(didCompleteAnalysis manager: WalkActivityManager) {
        displaySharing()
    }
    
    func walkActivityManager(didFailToAnalyze manager: WalkActivityManager) {
        displayAnalyze()
    }
    
    func walkActivityManager(_ manager: WalkActivityManager, didCompleteExportToPath exportedFilePath: String) {
        print("Result file path:\n\(exportedFilePath)")
        
        displaySharing()
        showSharing(for: exportedFilePath)
    }
    
    func walkActivityManager(didFailToExport manager: WalkActivityManager) {
        displaySharing()
    }
}

// MARK: MainViewDelegate
extension MainViewController: MainViewDelegate {
    func mainView(didSelectAnalyze view: MainView) {
        beginAnalysis()
    }
    
    func mainView(didSelectShare view: MainView) {
        beginExport()
    }
}

// MARK: - Private
private extension MainViewController {
    // MARK: States
    
    /// Setup state to `Ready to Analyze`
    ///
    func displayAnalyze() {
        customView.isAnalyzeEnabled = true
        customView.isSharingVisible = false
        customView.isActivityVisible = false
        customView.progress = 0.0
    }
    
    /// Setup state to `Analyzing in progress`
    ///
    func beginAnalysis() {
        if let path = Bundle.main.path(forResource: "mobile_test_inputs", ofType: "csv") {
            customView.isAnalyzeEnabled = false
            customView.isSharingVisible = false
            customView.isActivityVisible = true
            customView.progress = 0.0
            
            manager.analyze(fileAtPath: path)
        }
    }
    
    /// Update analyzing with the actual progress value
    ///
    /// - Parameters:
    ///   - progress: Progress value from 0.0 to 1.0
    func displayAnalysisProgress(_ progress: Float) {
        customView.progress = progress
    }
    
    /// Setup state to `Analysis results are ready for sharing`
    ///
    func displaySharing() {
        customView.isActivityVisible = false
        customView.isSharingVisible = true
        customView.isAnalyzeEnabled = true
        customView.isSharingEnabled = true
    }
    
    /// Setup state to `Prepare for sharing is in progress`
    ///
    func beginExport() {
        customView.isActivityVisible = true
        customView.isAnalyzeEnabled = false
        customView.isSharingEnabled = false
        manager.exportResults()
    }
    
    // MARK: Navigation
    
    /// Navigates to SharingActivity ViewController
    ///
    /// - Parameters:
    ///   - filePath: Path to the sharing file
    func showSharing(for filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)

        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        present(activityVC, animated: true, completion: nil)
    }
}

