//
//  Item.swift
//  BookMemoir
//
//  Created by Jasmine Ng. on 8/5/25.
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
