//
//  DateExpanded.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 13.04.2021.
//

import Foundation

extension Date {
    static private let RFC3339Format = "yyyy-MM-dd HH:mm:ss"
    static let dateFormatterFRC3339: DateFormatter = {
        let result = DateFormatter()
        result.timeZone = TimeZone(secondsFromGMT: 0)
        result.locale = Locale(identifier: "en_US_POSIX")
        result.dateFormat = RFC3339Format
        return result
    }()
    
    static private let dayTimeFormat = "yyyy-MM-dd_HH.mm.ss"
    static let dateFormatterDayTimeFormat: DateFormatter = {
        let result = DateFormatter()
        result.timeZone = TimeZone(secondsFromGMT: 0)
        result.locale = Locale(identifier: "en_US_POSIX")
        result.dateFormat = dayTimeFormat
        return result
    }()
    
    static private let DayCustomFormat = "yyyy-MM-dd"
    static let dateFormatterDayCustom: DateFormatter = {
        let result = DateFormatter()
        result.timeZone = TimeZone(secondsFromGMT: 0)
        result.locale = Locale(identifier: "en_US_POSIX")
        result.dateFormat = DayCustomFormat
        return result
    }()
    
    static func dateFromRFC3339String(_ source: String) -> Date? {
        return Date.dateFormatterFRC3339.date(from: source)
    }
    
    var dayCustomString: String {
        return Date.dateFormatterDayCustom.string(from: self)
    }
    
    var dayTimeString: String {
        return Date.dateFormatterDayTimeFormat.string(from: self)
    }
}

