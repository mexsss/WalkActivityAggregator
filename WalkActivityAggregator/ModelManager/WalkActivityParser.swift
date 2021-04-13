//
//  WalkActivityParser.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import Foundation

/// Delegate protocol for `WalkActivityParser`. Allows to handle the
/// parsing progress.
///
protocol WalkActivityParserDelegate: class {
    /// Notifies about the parsing progress change.
    ///
    /// - Parameters:
    ///   - parser: Instance of `WalkActivityParser` performing the action
    ///   - record: The `WalkActivityRecord` object, recognized during the
    ///   parsing iteration.
    ///   - progress: The actual progress value from 0.0 to 1.0 for the
    ///   current iteration.
    func walkActivityParser(_ parser: WalkActivityParser, didReadRecord record: WalkActivityRecord, progress: Float)
    
    /// Notifies about the parsing completed.
    ///
    /// - Parameters:
    ///   - parser: Instance of `WalkActivityParser` performing the action
    func walkActivityParser(didComplete parser: WalkActivityParser)
    
    /// Notifies about the parsing failed.
    ///
    /// - Parameters:
    ///   - parser: Instance of `WalkActivityParser` performing the action
    func walkActivityParser(didFail parser: WalkActivityParser)
}

/// The wrapper class to encapsulate the parsing process:
/// - File format
/// - Asynchronious file reading
///
class WalkActivityParser: ManagerComponent {
    private(set) var csvParser: CSVParser?
    
    /// Pointer to the delegate object. All the `WalkActivityParserDelegate`
    /// notifications will be called on the Main thread.
    weak var delegate: WalkActivityParserDelegate?
    
    // MARK: File format parameters
    private let InputFileLinesDelimiter = "\r\n"
    private let InputFileColumnsDelimiter = ","
    private let InputFileEncoding = String.Encoding.utf8
    
    // MARK: Public methods
    
    /// Initialize the parsing progress.
    ///
    /// - Parameters:
    ///   - path: Path to the `csv` file with the strict format.
    ///
    /// Every time the parsing initilizes, the new FileHandle to the file
    ///  will be created.
    /// If there's the executing parse, it will be cancelled before the new
    ///  one performs.
    ///
    /// Async method. Returns immediately.
    ///
    func parseFile(atPath path: String) {
        cancelParsing()
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let csvParser = CSVParser(path: path, linesDelimiter: self.InputFileLinesDelimiter, columnsDelimiter: self.InputFileColumnsDelimiter, encoding: self.InputFileEncoding)
            self.csvParser = csvParser
            
            guard csvParser.fileReader != nil else {
                self.notifyReadingFailed()
                return
            }
            
            csvParser.parse { [weak self] (recordValues) in
                if let recordValues = recordValues {
                    self?.treatRecordValue(recordValues)
                } else {
                    self?.treatCompletion()
                }
            }
        }
    }
    
    /// Cancels the parsing progress.
    ///
    func cancelParsing() {
        if let csvParser = csvParser {
            csvParser.cancelParsing()
            self.csvParser = nil
        }
    }
}

// MARK: - Private
private extension WalkActivityParser {
    
    // MARK: Changing states helpers
    
    /// Recognizes the `WalkActivityRecord` from the newly read row.
    ///
    /// - Parameters:
    ///   - recordValues: The content of the row, splitted into array
    ///     of `String`s.
    func treatRecordValue(_ recordValues: [String]) {
        guard recordValues.count == 10 else { return }
        
        let startString = recordValues[6]
        let endString = recordValues[7]
        guard let startDate = Date.dateFromRFC3339String(startString),
           let endDate = Date.dateFromRFC3339String(endString) else {
            return
        }
        if let newRecord = WalkActivityRecord(startDate: startDate, endDate: endDate) {
            notifyNewRecordDidRead(newRecord)
        }
    }
    
    /// Completes the parsing process.
    ///
    func treatCompletion() {
        notifyReadingCompleted()
    }
    
    // MARK: Notification helpers
    func notifyNewRecordDidRead(_ record: WalkActivityRecord) {
        guard let delegate = delegate else { return }
        guard let csvParser = csvParser else { return }
        
        // Extracting the actual progress value from the `CSVParser`.
        var progress: Float = 0.0
        switch csvParser.status {
        case .reading(let progressValue):
            progress = progressValue
        default:
            break
        }
        
        DispatchQueue.main.async {
            delegate.walkActivityParser(self, didReadRecord: record, progress: progress)
        }
    }
    
    func notifyReadingCompleted() {
        guard let delegate = delegate else { return }
        
        DispatchQueue.main.async {
            delegate.walkActivityParser(didComplete: self)
        }
    }
    
    func notifyReadingFailed() {
        guard let delegate = delegate else { return }
        
        DispatchQueue.main.async {
            delegate.walkActivityParser(didFail: self)
        }
    }
}

