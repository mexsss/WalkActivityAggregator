//
//  WalkActivityRecord.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 11.04.2021.
//

import Foundation

struct WalkActivityRecord {
    
    // MARK: Public properties
    /// Begin of the walk activity record
    let startDate: Date
    
    /// End of the walk activity record
    let endDate: Date
    
    /// Duration. Calculates in init()
    let duration: TimeInterval
    
    // MARK: Instance methods
    /// Creates a `WalkActivityRecord` object
    ///
    /// - Parameters:
    ///   - startDate: Date and time of start
    ///   - endDate: Date and time of end
    /// - Returns: `nil` if `endDate` is lower or equal then `startData`,
    /// otherwise the `WalkActivityRecord` object.
    init?(startDate: Date, endDate: Date) {
        guard startDate <= endDate else {
            return nil
        }
        self.startDate = startDate
        self.endDate = endDate
        duration = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
    }
    
    var description: String {
        return "<WalkActivityRecord>. StartDate: \(startDate), EndDate: \(endDate)"
    }
    
    /// Defines and hourId of the start. The value equals the number of a hour
    /// since 1970.
    ///
    var startHourId: Int {
        return (Int)(startDate.timeIntervalSince1970) / 3600
    }
    
    /// Defines and hourId of the end. The value equals the number of a hour
    /// since 1970.
    ///
    var endHourId: Int {
        return (Int)(endDate.timeIntervalSince1970) / 3600
    }
    
    /// Returns `true` if the `startHourId` and `endHourId` are the same.
    ///
    var isTheSameHour: Bool {
        return startHourId == endHourId
    }
    
    /// Splits the record by hours.
    ///
    /// This is a helper property allows to split the `WalkActivityRecord`
    /// which covers more then 1 hour. For example:
    ///  - 00:55:20 - 01:12:48 turns into two Records: 00:55:20 - 00:59:59
    ///   and 01:00:00 - 01:12:48
    ///  - 15:40:06 - 17:03:15 turns into two Records: 15:40:06 - 15:59:59,
    ///   16:00:00 - 16:59:59 and 17:00:00 - 17:03:15
    ///
    /// If the record are fit in 1 hour (XX:00:00 - XX:59:59), the result
    ///  array will contains 1 element (the whole current record).
    ///
    var recordsByHours: [WalkActivityRecord] {
        guard !isTheSameHour else {
            return [self]
        }
        var result = [WalkActivityRecord]()
        // Based on:
        //  > (например, с часу до двух ( [13:00:00 - 13:59:59] ), с двух до трех ([14:00:00 - 14:59:59]) и т.д.)
        let nextHourTimeInterval = (TimeInterval)(startHourId + 1) * 3600.0
        let newStartDate = Date(timeIntervalSince1970: nextHourTimeInterval)
        let newEndDate = Date(timeIntervalSince1970: nextHourTimeInterval - 0.1)
        result.append(WalkActivityRecord(startDate: startDate, endDate: newEndDate)!)
        let newRecord = WalkActivityRecord(startDate: newStartDate, endDate: endDate)!
        result.append(contentsOf: newRecord.recordsByHours)
        
        return result
    }
}

// MARK: Helpers methods
extension WalkActivityRecord {
    
    /// Max interval between two walk records in case the are count as
    /// single episode.
    ///
    private static let maxPauseBetweenEpisodes: TimeInterval = 18.0
    
    /// Combines two Records by taking the earliest start and latest
    /// end.
    ///
    static func combineEpisodes(_ r1: WalkActivityRecord, _ r2: WalkActivityRecord) -> WalkActivityRecord {
        let start = min(r1.startDate, r2.startDate)
        let end = max(r1.endDate, r2.endDate)
        return WalkActivityRecord(startDate: start, endDate: end)!
    }
    
    /// Compare two Records to define if there're the same episodes.
    ///
    /// Two Records are the same episode if:
    ///  - They are intersecting each other;
    ///  - The pause between them are less then `maxPauseBetweenEpisodes`.
    ///
    static func isTheSameEpisode(_ r1: WalkActivityRecord, _ r2: WalkActivityRecord) -> Bool {
        
        guard !areIntersecting(r1, r2) else {
            return true
        }
        let pauseInterval = r2.startDate.timeIntervalSince1970 - r1.endDate.timeIntervalSince1970
        if pauseInterval <= maxPauseBetweenEpisodes {
            return true
        }
        return false
    }
    
    /// Check if the two Records are intersecting each other.
    ///
    static func areIntersecting(_ r1: WalkActivityRecord, _ r2: WalkActivityRecord) -> Bool {
        if r2.startDate < r1.endDate {
            return true
        }
        return false
    }
    
    /// Sort two Records ascending by `startDate`.
    ///
    static func sort(_ r1: WalkActivityRecord, _ r2: WalkActivityRecord) -> (before: WalkActivityRecord, after: WalkActivityRecord) {
        if r1.startDate <= r2.startDate {
            return (r1, r2)
        } else {
            return (r2, r1)
        }
    }
}

