//
//  WalkActivityExporter.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import Foundation

/// The wrapper class to encapsulate the extracting results process:
/// - File format
/// - Asynchronious file writing
///
class WalkActivityExporter: ManagerComponent {
    
    // MARK: File format defines
    private let OutputFileHeader = "day,balance_points,balance_day"
    private let OutputFileLinesDelimiter = "\r\n"
    private let OutputFileColumnsDelimiter = ","
    private let OutputFileEncoding = String.Encoding.utf8
    
    // MARK: File name defines
    private let OutputFileName = "mobile_test_output"
    private let OutputFileExtension = "csv"
    
    // MARK: Public methods
    
    /// Initialize the export progress.
    ///
    /// - Parameters:
    ///   - results: The analysis result, presented in dictionary. The key
    ///   of the dictionary is a day's hash, which helps to sort the
    ///   `WalkDayActivity`s quicker.
    ///   - completion: Completion block will be executed after the preparing
    ///   file-data and saving are completed. The `path` is the absolute path
    ///   of the file in file system.
    ///
    /// Performs in 2 steps async:
    ///  - Preparing file-data based on analysis results;
    ///  - Save file-data on the file system. The file saves in Cache
    ///  directory.
    ///
    /// Async method. Returns immediately.
    ///
    func export(results: [Int: WalkDayActivity], completion: @escaping (_ path: String?) -> Void) {
        let notifyBlock = { (_ path: String?) in
            DispatchQueue.main.async {
                completion(path)
            }
        }
        guard let path = filePath() else {
            notifyBlock(nil)
            return
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Before saving the file data the activity statistics should be
            // prepared by sorting `WalkDayActivity` by ascending date.
            // The optimal way to do this is using the dayId, which is the key
            // of the input dictionary.
            var sortedDayActivities = [WalkDayActivity]()
            for dayIdEnum in results.keys.sorted() {
                guard let dayActivity = results[dayIdEnum] else { continue }
                sortedDayActivities.append(dayActivity)
            }
            
            // The file-data to export
            let resultString = self.csvFormattedString(for: sortedDayActivities)
            
            // Save file in storage
            if self.writeString(resultString, withPath: path) {
                notifyBlock(path)
            } else {
                notifyBlock(nil)
            }
        }
    }
}

// MARK: - Private
private extension WalkActivityExporter {
    // MARK: File helpers
    func filePath() -> String? {
        guard let cacheRootPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        return cacheRootPath + "/" + fileName()
    }
    
    func fileName() -> String {
        var result = OutputFileName
        let dateString = Date().dayTimeString
        result += "_\(dateString)."
        result += OutputFileExtension
        return result
    }
    
    /// Returns the formatted CSV-string
    ///
    func csvFormattedString(for results: [WalkDayActivity]) -> String {
        var resultString = OutputFileHeader
        for dayResult in results {
            resultString += OutputFileLinesDelimiter
            resultString += "\(dayResult.day.dayCustomString)"
            resultString += OutputFileColumnsDelimiter
            resultString += "\(dayResult.balancePoints)"
            resultString += OutputFileColumnsDelimiter
            resultString += "\(dayResult.balanceDay)%"
        }
        return resultString
    }
    
    /// Save the provided `contentString` synchronously
    ///
    func writeString(_ contentString: String, withPath path: String) -> Bool {
        do {
            try contentString.write(toFile: path, atomically: true, encoding: OutputFileEncoding)
        } catch {
            return false
        }
        
        return true
    }
}

