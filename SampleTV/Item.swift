//
//  Item.swift
//  SampleTV
//
//  Created by aakpro on 2026-11-23.
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
