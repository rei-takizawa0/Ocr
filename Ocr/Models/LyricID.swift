//
//  LyricID.swift
//  Ocr
//
//  Created by takizawa rei on 2025/11/08.
//

import SwiftData
import Foundation

@Model
final class LyricID {
    @Attribute(.unique) var id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}
