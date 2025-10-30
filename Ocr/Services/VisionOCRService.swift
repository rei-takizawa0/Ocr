//
//  VisionOCRService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit
import Vision
import ImageIO

/// OCRサービスで発生するエラー
enum OCRServiceError: Error, Equatable {
    case invalidImage
    case recognitionFailed
    case noTextFound
}

/// Vision frameworkを使用したOCRサービスの実装（SRP: OCR処理のみの責任）
final class VisionOCRService {

    // MARK: - Public Methods

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }

        // 画像の向きを考慮したオプション
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let requestHandler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: orientation,
            options: [:]
        )
        let request = createTextRecognitionRequest()

        return try await withCheckedThrowingContinuation { continuation in
            var result: OCRResult?
            var error: Error?

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true // 精度向上のため言語補正を有効化
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.automaticallyDetectsLanguage = true
            request.minimumTextHeight = 0.0 // すべてのサイズのテキストを認識
            request.revision = VNRecognizeTextRequestRevision3 // 最新のリビジョンを使用

            do {
                try requestHandler.perform([request])

                if let observations = request.results, !observations.isEmpty {
                    let recognizedText = extractText(from: observations)

                    if recognizedText.isEmpty {
                        error = OCRServiceError.noTextFound
                    } else {
                        let confidence = calculateAverageConfidence(from: observations)
                        result = OCRResult(
                            text: recognizedText,
                            confidence: confidence,
                            processedImage: image
                        )
                    }
                } else {
                    error = OCRServiceError.noTextFound
                }
            } catch {
            }

            if let result = result {
                continuation.resume(returning: result)
            } else if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(throwing: OCRServiceError.recognitionFailed)
            }
        }
    }

    // MARK: - Private Methods

    private func createTextRecognitionRequest() -> VNRecognizeTextRequest {
        return VNRecognizeTextRequest()
    }

    /// 認識結果からテキストを抽出（精度優先）
    private func extractText(from observations: [VNRecognizedTextObservation]) -> String {
        var lines: [(text: String, y: CGFloat)] = []

        for observation in observations {
            // 複数の候補から最も信頼度の高いものを選択
            guard let topCandidate = observation.topCandidates(1).first else {
                continue
            }

            let boundingBox = observation.boundingBox
            let yPosition = boundingBox.origin.y

            lines.append((text: topCandidate.string, y: yPosition))
        }

        // Y座標でソート（上から下へ）
        lines.sort { $0.y > $1.y }

        // テキストを結合（改行のみ保持）
        return lines.map { $0.text }.joined(separator: "\n")
    }

    /// 平均信頼度を計算
    private func calculateAverageConfidence(from observations: [VNRecognizedTextObservation]) -> Float {
        let confidences = observations.compactMap { observation -> Float? in
            return observation.topCandidates(1).first?.confidence
        }

        guard !confidences.isEmpty else {
            return 0.0
        }

        let sum = confidences.reduce(0, +)
        return sum / Float(confidences.count)
    }
}

// MARK: - UIImage.Orientation Extension

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
