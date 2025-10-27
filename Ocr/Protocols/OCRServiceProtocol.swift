//
//  OCRServiceProtocol.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit

/// OCRサービスのプロトコル（DIP: 抽象に依存）
protocol OCRServiceProtocol {
    /// 画像からテキストを認識する
    /// - Parameter image: 認識対象の画像
    /// - Returns: OCR結果
    /// - Throws: OCR処理中のエラー
    func recognizeText(from image: UIImage) async throws -> OCRResult
}

/// OCRサービスで発生するエラー
enum OCRServiceError: Error, Equatable {
    case invalidImage
    case recognitionFailed
    case noTextFound
}
