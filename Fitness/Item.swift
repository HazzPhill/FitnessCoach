//
//  Item.swift
//  Fitness
//
//  Created by Harry Phillips on 03/02/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
