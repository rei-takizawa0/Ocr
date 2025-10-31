//
//  OCRResult.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit

/// OCR認識結果を表すモデル
struct OCRResult: Equatable {
    let text: String
    let confidence: Float
    let processedImage: UIImage?
    let timestamp: Date

    init(text: String, confidence: Float, processedImage: UIImage? = nil, timestamp: Date = Date()) {
        self.text = text
        self.confidence = confidence
        self.processedImage = processedImage
        self.timestamp = timestamp
    }

    static func == (lhs: OCRResult, rhs: OCRResult) -> Bool {
        return lhs.text == rhs.text &&
               lhs.confidence == rhs.confidence &&
               lhs.timestamp == rhs.timestamp
    }
}
