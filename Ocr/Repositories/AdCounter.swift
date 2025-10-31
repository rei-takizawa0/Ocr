//
//  AdCounter.swift
//  Ocr
//
//  Created by takizawa rei on 2025/10/29.
//

import SwiftData
import Foundation

/// 広告表示回数を追跡するモデル
@Model
final class AdCounter {
    var id: UUID = UUID()
    var count: Int = 0

    init(count: Int = 0) {
        self.count = count
    }
}
