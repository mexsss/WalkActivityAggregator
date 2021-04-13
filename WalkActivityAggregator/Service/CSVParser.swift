//
//  CSVParser.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import Foundation

/// Wrapper to incapsulate CSV parsing row by row using `TextFileReader`.
///
public class CSVParser {
    private(set) var fileReader: TextFileReader?
    let columnsDelimiter: String
    var headerLinesNumber: Int = 1
    
    private let quoteDelimiter = "\""
    
    init(path: String, linesDelimiter: String, columnsDelimiter: String, encoding: String.Encoding) {
        self.fileReader = TextFileReader(atPath: path, encoding: encoding, delimiter: linesDelimiter)
        self.columnsDelimiter = columnsDelimiter
    }
    
    /// Sync parse the next line of file and return row's column values
    /// as String.
    ///
    func parse(completion: @escaping (_ recordValues: [String]?) -> Void) {
        guard let fileReader = fileReader else {
            return
        }
        var headerLinesToSkip = max(0, headerLinesNumber)
        for lineEnum in fileReader {
            guard headerLinesToSkip == 0 else {
                headerLinesToSkip -= 1
                continue
            }
            
            let result = parseLine(lineEnum)
            completion(result)
        }
        completion(nil)
    }
    
    /// Cancels parsing.
    ///
    func cancelParsing() {
        fileReader?.cancelReading()
    }
    
    /// Parsing status based on the status of `TextFileReader`.
    ///
    var status: TextFileReader.Status {
        guard let fileReader = fileReader else {
            return .cancelled
        }
        return fileReader.status
    }
}

// MARK: - Private
private extension CSVParser {
    func parseLine(_ sourceLine: String) -> [String]? {
        guard !sourceLine.isEmpty else {
            return [""]
        }
        var result = [String]()
        if sourceLine.range(of: quoteDelimiter) != nil {
            var scanningString = sourceLine
            var scanner = Scanner(string: scanningString)
            var columnValue: String?
            while !scanner.string.isEmpty {
                if scanner.string.hasPrefix(quoteDelimiter) {
                    _ = scanner.scanString(quoteDelimiter)
                    columnValue = scanner.scanUpToString(quoteDelimiter)
                    _ = scanner.scanString(quoteDelimiter)
                } else {
                    columnValue = scanner.scanUpToString(columnsDelimiter)
                }
                if let columnValue = columnValue {
                    result.append(columnValue)
                }
                
                if scanner.currentIndex < scanner.string.endIndex {
                    let nextIndex = scanner.string.index(after: scanner.currentIndex)
                    scanningString = String(scanner.string[nextIndex...])
                } else {
                    scanningString = ""
                }
                scanner = Scanner(string: scanningString)
            }
        } else {
            result = sourceLine.components(separatedBy: columnsDelimiter)
        }
        return result
    }
}

