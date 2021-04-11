//
//  WalkHourActivity.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 11.04.2021.
//

import Foundation

/// Contains helpers to aggregate `WalkActivityRecord` and holds
/// per-hour statistics.
///
class WalkHourActivity {
    
    /// Minimal duration of walk episode to accept 1 balance point per hour.
    ///
    private let minimalWalkEpisodeDuration: TimeInterval = 180.0
    
    /// Minimal interval between two walk episodes (first and the last in an
    /// hour) to accept 2 balance points per hour.
    ///
    private let minimalIntervalBetweenWalkEpisodes: TimeInterval = 2280.0
    
    /// All the separate "episodes of walk" during the hour
    ///
    private(set) var records = [WalkActivityRecord]()
    
    /// Contains the last calculated value of Balance Points
    /// After adding a `WalkActivityRecord` via `updateWalkEpisodes` method
    /// this property has to be recalulated by calling `updateHourPoints()`.
    private var _balancePoints: Int = 0
    private(set) var balancePoints: Int {
        get {
            return _balancePoints
        }
        set {
            // According the Terms of reference, has to be from 0 to 2.
            guard newValue <= 2 else { return }
            
            _balancePoints = newValue
        }
    }
    
    /// Adds new record to the hour statistics, bases on a requirements in the
    /// Terms of reference.
    ///
    /// - Parameters:
    ///   - byRecord: New record will be added to the per-hour statistics
    ///
    func updateWalkEpisodes(byRecord record: WalkActivityRecord) {
        var result = [WalkActivityRecord]()
        var waitingRecord: WalkActivityRecord = record
        
        // We have to recalculate all the Records after the adding of new one
        // Because in case if 2 Records are too close to each other (less then
        // 18 seconds - see `WalkActivityRecord.isTheSameEpisode` for more
        // details) they should be combined in single "Walk-Episodes".
        for index in 0..<records.count {
            // Every two `WalkActivityRecord` should be sorted before compare
            let sorted = WalkActivityRecord.sort(waitingRecord, records[index])
            
            // Check if two `WalkActivityRecord` are:
            //  - too close to each other
            //  - intersects each other
            if WalkActivityRecord.isTheSameEpisode(sorted.before, sorted.after) {
                // Combine these two records
                let combined = WalkActivityRecord.combineEpisodes(sorted.before, sorted.after)
                waitingRecord = combined
            } else {
                // Leave the current record as is
                result.append(records[index])
            }
        }
        // Add new Record to the collection
        result.append(waitingRecord)
        
        // Sort to optimize next search
        result.sort(by: { $0.startDate < $1.startDate })
        
        // Save updated collection of Records
        records = result
    }
    
    /// Recalculates Balance Points for the hour, bases on a requirements in
    /// the Terms of reference.
    ///
    /// - Returns: `nil` if there's no changes in hour statistics or the
    /// difference between new and old values. If the new value is larger then
    /// the old one, the result will be possitive.
    ///
    func updateHourPoints() -> Int? {
        var first: WalkActivityRecord?
        var last: WalkActivityRecord?
        
        // Find the first and the last episodes
        for record in records {
            guard record.duration >= minimalWalkEpisodeDuration else {
                continue
            }
            
            if first == nil {
                first = record
            } else {
                last = record
            }
        }
        
        // Calculate balance points based on number of interval and the
        // interval between each other.
        var result = 0
        if let first = first {
            result = 1
            if let last = last {
                let distance = last.startDate.timeIntervalSince1970 - first.startDate.timeIntervalSince1970
                if distance >= minimalIntervalBetweenWalkEpisodes {
                    result = 2
                }
            }
               
        }
        
        // If no changes, return `nil`
        guard result != balancePoints else {
            return nil
        }
        // Calculate difference
        let oldValue = balancePoints
        balancePoints = result
        return balancePoints - oldValue
    }
    
    static func dayId(for hourId: Int) -> Int {
        return hourId / 24
    }
}
