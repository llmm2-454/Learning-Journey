//
//  Item.swift
//  LearningJourney
//
//  Created by lama farhan on 01/06/1448 AH.
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
