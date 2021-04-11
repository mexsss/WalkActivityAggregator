//
//  WalkDayActivity.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 11.04.2021.
//

import Foundation


/// Holds the per-day statistics while aggregating `WalkActivityRecord`.
///
class WalkDayActivity {
    /// Number of Balance Points for the day
    ///
    var balancePoints: Int = 0
    
    /// Number of Balance Day for the day
    ///
    var balanceDay: Int {
        return balancePoints * 10
    }
    
    /// The date this `WalkDayActivity` refers to
    ///
    let day: Date
    
    /// Create a `WalkDayActivity` with the initial values
    ///
    /// - Parameters:
    ///   - day: May has any time since 00:00:00 to 23:59:59
    ///   - points: Initial `points` value
    ///
    init(for day: Date, points: Int) {
        self.day = day
        self.balancePoints = points
    }
}

