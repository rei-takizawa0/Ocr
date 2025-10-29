//
//  ads.swift
//  Ocr
//
//  Created by takizawa rei on 2025/10/29.
//

import SwiftData
import Foundation

@Model
final class Ads{
    var id: UUID = UUID()
    var count: Int = 0
    
    init(count: Int = 0) {
        self.count = count
    }
}
