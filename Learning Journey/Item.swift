//
//  Item.swift
//  Learning Journey
//
//  Created by lama farhan on 29/05/1448 AH.
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
