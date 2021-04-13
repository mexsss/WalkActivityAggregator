//
//  TextFileReader.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import Foundation

/// Wrapper to incapsulate text file reading by parts using delimiter.
///
public class TextFileReader {
    
    // MARK: Subtypes
    enum Status {
        case ready
        case reading(Float)
        case completed
        case cancelled
    }
    
    // MARK: Default parameters
    private static let EncodingDefault: String.Encoding = .utf8
    private static let DelimiterDefault: String = "\n"
    private static let BufferSizeDefault: Int = 128
    
    // MARK: Private properties
    private let fileHandler: FileHandle
    private var bufferData: Data
    private let delimiterData: Data
    private let fileSize: UInt64
    private var readPartSize: UInt64
    
    // MARK: Public properties
    public let filePath: String
    public let encoding: String.Encoding
    public let bufferSize: Int
    public let delimiter: String
    
    private(set) var status: Status
    
    // MARK: - TextFileReader
    init?(atPath path: String,
          encoding: String.Encoding = TextFileReader.EncodingDefault,
          delimiter: String = TextFileReader.DelimiterDefault,
          bufferSize: Int = TextFileReader.BufferSizeDefault) {
        guard bufferSize > 0 else {
            return nil
        }
        guard let fileHandler = FileHandle(forReadingAtPath: path),
              let delimiterData = delimiter.data(using: encoding) else {
            return nil
        }
        self.filePath = path
        self.encoding = encoding
        self.bufferSize = bufferSize
        self.delimiter = delimiter
        self.fileSize = TextFileReader.fileSize(for: path)
        self.readPartSize = 0
        
        self.fileHandler = fileHandler
        self.delimiterData = delimiterData
        self.bufferData = Data()//(capacity: bufferSize)
        self.status = .ready
    }
    
    deinit {
        closeFile()
    }
    
    /// Reads the next line of file or returns `nil` if the file read til the
    /// end.
    ///
    func read() -> String? {
        // Treat status to avoid incorrect writing after completion or
        //  cancelling.
        guard status != .cancelled &&
                status != .completed else {
            return nil
        }

        // Read file by `bufferSize` until the `delimiterData` found.
        var range = bufferData.range(of: delimiterData, options: [])
        while range == nil {
            let nextDataBlock = fileHandler.readData(ofLength: bufferSize)
            readPartSize += UInt64(bufferSize)
            status = .reading(progressValue)
            
            guard !nextDataBlock.isEmpty else {
                status = .completed
                if bufferData.count > 0 {
                    let string = String(data: bufferData, encoding: encoding)

                    bufferData.removeAll()
                    return string
                }
                return nil
            }

            bufferData.append(nextDataBlock)
            range = bufferData.range(of: delimiterData, options: [])
        }

        guard let delimiterRange = range else {
            return nil
        }
        
        // Extract read part of file without delimiter
        let data = bufferData.subdata(in: 0..<delimiterRange.startIndex)
        let string = String(data: data, encoding: encoding)
        
        // Remove read part from buffer
        bufferData.replaceSubrange(0..<delimiterRange.endIndex, with: Data())
        
        return string
    }
    
    func cancelReading() {
        status = .cancelled
        closeFile()
    }
}

// MARK: - Sequence
extension TextFileReader: Sequence {
    public func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.read()
        }
    }
}

// MARK: - Private
private extension TextFileReader {
    
    func closeFile() {
        fileHandler.closeFile()
    }
    
    static func fileSize(for path: String) -> UInt64 {
        guard let attr = try? FileManager.default.attributesOfItem(atPath: path) else {
            return 0
        }
        return attr[.size] as? UInt64 ?? 0
    }
    
    var progressValue: Float {
        guard fileSize > 0 else {
            return 0.0
        }
        guard readPartSize < fileSize else {
            return 1.0
        }
        return Float(readPartSize) / Float(fileSize)
    }
}

// MARK: - Equatable
extension TextFileReader.Status: Equatable {
    static let minimalValuableProgress: Float = 0.01
    static func ==(_ lv: TextFileReader.Status, _ rv: TextFileReader.Status) -> Bool {
        switch (lv, rv) {
        case (.ready, .ready),
             (.cancelled, .cancelled),
             (.completed, .completed):
            return true
        case (.reading(let lp), .reading(let rp)):
            if abs(lp - rp) < minimalValuableProgress {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }
}

