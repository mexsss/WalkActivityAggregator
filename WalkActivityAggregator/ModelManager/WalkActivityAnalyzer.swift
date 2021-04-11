//
//  WalkActivityAnalyzer.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 11.04.2021.
//

import Foundation

/// The wrapper class to encapsulate the analyzing process:
/// - Aggregating the `WalkActivityRecord` into per-hour statistics;
/// - Aggragating per-hour statistics into per-day statistics.
///
class WalkActivityAnalyzer: ManagerComponent {
    
    // MARK: Private properties
    
    /// Aggregates the per-hour statistics.
    ///
    /// All the `WalkActivityRecord` should be stored inside `WalkHourActivity`
    /// and collected in `hourActivity` dictionary. A dictionary approach
    /// allows to extract the hour-activity the quick way. As the key of
    /// dictionary uses the `hourId` - it represents hour's number since 1970.
    /// See the calculation in `WalkActivityRecord.startHourId`.
    ///
    private var hourActivity = [Int: WalkHourActivity]()
    
    // MARK: Public properties
    
    /// Aggregates the per-day statistics.
    ///
    /// All the `WalkHourActivity` should be aggreageted inside
    /// `WalkDayActivity` and collected in `dailyActivityResult` dictionary.
    /// A dictionary approach allows to extract the day-activity with the
    /// quick way. As the key of dictionary uses the `dayId` - it represents
    /// day's number since 1970.
    /// See the calculation in `WalkHourActivity.dayId(for:)`.
    ///
    private(set) var dailyActivityResult = [Int: WalkDayActivity]()
    
    /// Indicates the completion is completed. Bases on required call of
    /// `notifyOnFinalAnalysisCompleted`.
    ///
    private(set) var isCompleted = false
    
    /// Clear all the cached results and prepears to the next analysis.
    ///
    func clearResults() {
        queue.async {
            self.dailyActivityResult.removeAll()
            self.hourActivity.removeAll()
            self.isCompleted = false
        }
    }
    
    /// Applies the new record to the statistics.
    ///
    /// - Parameters:
    ///   - record: The new `WalkActivityRecord` to be treated in user's
    ///   activity. If the record is covering a few hours of walk, it
    ///   will be splitted into several `WalkActivityRecord` and treated
    ///   separately.
    ///
    /// Every passing `WalkActivityRecord` will be added to the queue and
    /// applied consecutively.
    ///
    /// Async method. Returns immediately.
    ///
    func add(record rawRecord: WalkActivityRecord) {
        queue.async {
            if rawRecord.isTheSameHour {
                self.analyze(record: rawRecord)
            } else {
                for recordEnum in rawRecord.recordsByHours {
                    self.analyze(record: recordEnum)
                }
            }
        }
    }
    
    /// Required method. **Has to be executed** as soon as Parsing process is
    ///  completed. After that `WalkActivityAnalyzer` shouldn't receive any
    ///  `WalkActivityRecord` using `add(record:)` method, until the current
    ///  state will be cancelled by calling `clearResults()`.
    ///
    ///
    /// - Parameters:
    ///   - completion: The completion handler will be called after the
    ///   last `WalkActivityRecord` in processing queue will be treated.
    ///
    /// Async method. Returns immediately.
    ///
    func notifyOnFinalAnalysisCompleted(completion: @escaping () -> Void) {
        queue.async(flags: .barrier) {
            self.isCompleted = true
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

// MARK: - Private
private extension WalkActivityAnalyzer {
    
    /// Aggregates `WalkActivityRecord` into per-hour statistics.
    ///
    /// - Parameters:
    ///   - record: The record to be applied to the statistics.
    ///
    /// All the internal methods supposed to be executed on the Component's
    /// queue.
    ///
    func analyze(record: WalkActivityRecord) {
        let hour = record.startHourId
        
        // Initialize `WalkHourActivity` in the collection
        let hourRecord: WalkHourActivity
        if let current = hourActivity[hour] {
            hourRecord = current
        } else {
            hourRecord = WalkHourActivity()
            hourActivity[hour] = hourRecord
        }
        
        // Apply new `WalkActivityRecord`
        hourRecord.updateWalkEpisodes(byRecord: record)
        // Recalculate
        if let difference = hourRecord.updateHourPoints() {
            // If the new `WalkActivityRecord` affects the balance points
            //  during `WalkHourActivity`, it needs to update the correspondent
            //  day
            updateBalanceDay(hourRecord: hourRecord, hour: hour, byPoints: difference)
        }
    }
    
    /// Aggregates `WalkHourActivity` into per-day statistics.
    ///
    /// - Parameters:
    ///   - hourRecord: The hour statistics.
    ///   - hour: The hourId for the `WalkHourActivity`.
    ///   - byPoints: The difference between the value of Balance Points in
    ///   the correspondent hour before the applying the last
    ///   `WalkActivityRecord`. This property helps optimization: we don't
    ///   need to recalulate the whole Balance Points for the day, just change
    ///   by the passed difference.
    ///
    /// All the internal methods supposed to be executed on the Component's
    /// queue.
    ///
    func updateBalanceDay(hourRecord: WalkHourActivity, hour: Int, byPoints: Int) {
        // Calculate the dayId for dictionary.
        let dayId = WalkHourActivity.dayId(for: hour)
        
        if let day = dailyActivityResult[dayId] {
            // Update the balancePoints using passed difference.
            day.balancePoints = day.balancePoints + byPoints
        } else {
            // Create new entry of `WalkDayActivity` for a new day in
            //  collection.
            if let walkRecord = hourRecord.records.first {
                dailyActivityResult[dayId] = WalkDayActivity(for: walkRecord.startDate, points: hourRecord.balancePoints)
            }
        }
    }
}
