//
//  ManagerComponent.swift
//  WalkActivityAggregator
//
//  Created by Maxim Shvetsov on 11.04.2021.
//

import Foundation

/// Base component-class, specifies the component's queue.
///
class ManagerComponent {
    let queue: DispatchQueue
    
    /// Creates a `ManagerComponent` object with required configuration
    /// options.
    ///
    /// - Parameters:
    ///   - queue: Instance of !SERIAL! `DispatchQueue`
    init(queue: DispatchQueue) {
        self.queue = queue
    }
}
