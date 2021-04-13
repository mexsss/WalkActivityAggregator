//
//  WalkActivityManager.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import Foundation

/// Delegate protocol for `WalkActivityManager`. Allows to handle the main
/// flow events of analysis and export.
///
protocol WalkActivityManagerDelegate: class {
    
    // MARK: Analysis
    
    /// Notifies about the analysis progress change.
    ///
    /// - Parameters:
    ///   - manager: Instance of `WalkActivityManager` performing the action
    ///   - progress: The progress value from 0.0 to 1.0.
    func walkActivityManager(_ manager: WalkActivityManager, didChangeProgress progress: Float)
    
    /// Notifies about the analysis state, when it's complete.
    ///
    /// - Parameters:
    ///   - manager: Instance of `WalkActivityManager` performing the action
    func walkActivityManager(didCompleteAnalysis manager: WalkActivityManager)
    
    /// Notifies delegate about the inconsistent error to proceed the analysis.
    ///
    /// - Parameters:
    ///   - manager: Instance of `WalkActivityManager` performing the action
    func walkActivityManager(didFailToAnalyze manager: WalkActivityManager)
    
    // MARK: Export
    
    /// Notifies about the export state, when it's complete.
    ///
    /// - Parameters:
    ///   - manager: Instance of `WalkActivityManager` performing the action
    ///   - exportedFilePath: Path to the file, contains the analysis result.
    /// The file stores in Cache directory.
    func walkActivityManager(_ manager: WalkActivityManager, didCompleteExportToPath exportedFilePath: String)
    
    /// Notifies about the export state, when it's failed.
    ///
    /// - Parameters:
    ///   - manager: Instance of `WalkActivityManager` performing the action
    func walkActivityManager(didFailToExport manager: WalkActivityManager)
}

class WalkActivityManager {
    
    // MARK: Components
    private let parser: WalkActivityParser
    private let analyzer: WalkActivityAnalyzer
    private var exporter: WalkActivityExporter?
    
    // MARK: Progress
    
    /// Contains the actual value of the analysis progress.
    /// The value from 0.0 to 1.0.
    private(set) var progress: Float = 0.0 {
        didSet {
            notifyAnalysisProgressIfNeed()
        }
    }
    /// Specifies the minimal value of progress change, so `delegate`
    /// are not notified on insignificant progress.
    private let minimalProgressChangeToNotify: Float = 0.01
    /// Stores the latest progress value, `delegate` was notified about.
    private var lastNotifiedProgress: Float = 0.0
    
    // MARK: Public properties
    
    /// Pointer to the delegate object. All the `WalkActivityManagerDelegate`
    /// notifications will be called on the Main thread.
    weak var delegate: WalkActivityManagerDelegate?
    
    // MARK: Public methods
    init() {
        // All the queues used for components are serial,
        // which is required by `ManagerComponent`s implementations.
        let parserQueue = DispatchQueue(label: "ParsingQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        parser = WalkActivityParser(queue: parserQueue)
        
        let analyzerQueue = DispatchQueue(label: "AnalyzingQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        analyzer = WalkActivityAnalyzer(queue: analyzerQueue)
        
        parser.delegate = self
    }
    
    /// Initialize the analysis progress.
    ///
    /// - Parameters:
    ///   - path: Path to the `csv` file with the strict format.
    ///
    /// Performs in 2 asynchronyous processes:
    ///  - Reading input the file
    ///  - Analyzing every valid walk-record + Aggreagation the records to the final dayly activity statistics
    ///
    /// Async method. Returns immediately.
    ///
    func analyze(fileAtPath path: String) {
        analyzer.clearResults()
        parser.parseFile(atPath: path)
    }
    
    /// Initialize the analysis progress.
    ///
    /// - Parameters:
    ///   - path: Path to the `csv` file with the strict format.
    ///
    /// Async method. Returns immediately.
    ///
    func exportResults() {
        guard analyzer.isCompleted else {
            DispatchQueue.main.async {
                self.delegate?.walkActivityManager(didFailToExport: self)
            }
            return
        }
        if exporter == nil {
            let exporterQueue = DispatchQueue(label: "ExportQueue", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
            exporter = WalkActivityExporter(queue: exporterQueue)
        }
        exporter?.export(results: analyzer.dailyActivityResult) { [weak self] (outputFilePath) in
            self?.notifyExported(outputFilePath: outputFilePath)
        }
    }
}

// MARK: WalkActivityParserDelegate
extension WalkActivityManager: WalkActivityParserDelegate {
    func walkActivityParser(_ parser: WalkActivityParser, didReadRecord record: WalkActivityRecord, progress: Float) {
        // We pass the newly read record to the `analyzer` via asynchronious
        //  method.
        analyzer.add(record: record)
        
        // Update the progress value. The notification logic is in `didSet`
        // method of the `progress` property
        self.progress = progress
    }
    
    func walkActivityParser(didComplete parser: WalkActivityParser) {
        // We have to inform the `analyzer` about the parsing is completed
        //  and subscribe for the analysis is completed.
        //  This implementation is required in throw the two async processes:
        //  1) Parsing file in serial queue line by line;
        //  2) Analyzing the `WalkActivityRecord` one by one asynchronously
        //   in the spearate serial queue.
        //
        // There're two possible behaviours:
        //  - The Analyzing process is "stuck" and executes slower then reading
        //   file. In this case we should be notified about the analyzing
        //   completion after the last `WalkActivityRecord` has treated.
        //  - The Analyzing `WalkActivityRecord` are faster then reading.
        //   In this case the notification will be called immediately,
        //   because the analyser's Serial Queue is empty.
        analyzer.notifyOnFinalAnalysisCompleted { [weak self] in
            self?.notifyAnalysisCompleted()
        }
    }
    
    func walkActivityParser(didFail parser: WalkActivityParser) {
        notifyAnalysisFailed()
    }
}

// MARK: - Private
private extension WalkActivityManager {
    // MARK: Notification helpers
    func notifyAnalysisProgressIfNeed() {
        guard let delegate = delegate else { return }
        
        // Defining if the notification is needed, based on:
        //  - Progress change since the last notification
        //  - `minimalProgressChangeToNotify` property
        guard abs(progress - lastNotifiedProgress) >= minimalProgressChangeToNotify else {
            return
        }
        
        // If the progress is "almost" 1.0 but the diffrence is smaller then
        //  `minimalProgressChangeToNotify`, the delegate never be notified.
        //  The block allows to round `lastNotifiedProgress` in this case.
        if abs(1.0 - progress) < minimalProgressChangeToNotify {
            lastNotifiedProgress = 1.0
        } else {
            lastNotifiedProgress = progress
        }
        
        DispatchQueue.main.async {
            delegate.walkActivityManager(self, didChangeProgress: self.lastNotifiedProgress)
        }
    }
    
    func notifyAnalysisCompleted() {
        guard let delegate = delegate else { return }
        
        DispatchQueue.main.async {
            delegate.walkActivityManager(didCompleteAnalysis: self)
        }
    }
    
    func notifyAnalysisFailed() {
        guard let delegate = delegate else { return }
        
        DispatchQueue.main.async {
            delegate.walkActivityManager(didFailToAnalyze: self)
        }
    }
    
    func notifyExported(outputFilePath: String?) {
        guard let delegate = delegate else { return }
        
        DispatchQueue.main.async {
            if let outputFilePath = outputFilePath {
                delegate.walkActivityManager(self, didCompleteExportToPath: outputFilePath)
            } else {
                delegate.walkActivityManager(didFailToExport: self)
            }
        }
    }
}

