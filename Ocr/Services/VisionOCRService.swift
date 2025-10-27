//
//  VisionOCRService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit
import Vision

/// Vision frameworkを使用したOCRサービスの実装（SRP: OCR処理のみの責任）
final class VisionOCRService: OCRServiceProtocol {

    // MARK: - OCRServiceProtocol

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = createTextRecognitionRequest()

        return try await withCheckedThrowingContinuation { continuation in
            var result: OCRResult?
            var error: Error?

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false // 空白を保持するため言語補正を無効化
            request.recognitionLanguages = ["ja-JP", "en-US"]

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

    /// 認識結果からテキストを抽出（空白を保持）
    private func extractText(from observations: [VNRecognizedTextObservation]) -> String {
        var lines: [(text: String, x: CGFloat, y: CGFloat, width: CGFloat)] = []

        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else {
                continue
            }

            let boundingBox = observation.boundingBox
            let yPosition = boundingBox.origin.y
            let xPosition = boundingBox.origin.x
            let width = boundingBox.width

            lines.append((text: topCandidate.string, x: xPosition, y: yPosition, width: width))
        }

        // Y座標でソート（上から下へ）
        lines.sort { $0.y > $1.y }

        // 同じ行のテキストをグループ化
        var groupedLines: [[(text: String, x: CGFloat, width: CGFloat)]] = []
        var currentGroup: [(text: String, x: CGFloat, width: CGFloat)] = []
        var lastY: CGFloat?
        let lineThreshold: CGFloat = 0.02 // 同じ行と判定する閾値

        for line in lines {
            if let lastY = lastY, abs(line.y - lastY) > lineThreshold {
                if !currentGroup.isEmpty {
                    groupedLines.append(currentGroup)
                    currentGroup = []
                }
            }
            currentGroup.append((text: line.text, x: line.x, width: line.width))
            lastY = line.y
        }

        if !currentGroup.isEmpty {
            groupedLines.append(currentGroup)
        }

        // 各行内でX座標でソートし、適切な空白を挿入
        var resultLines: [String] = []

        for group in groupedLines {
            let sortedGroup = group.sorted { $0.x < $1.x }
            var lineText = ""
            var lastEndX: CGFloat = 0

            for (index, item) in sortedGroup.enumerated() {
                if index > 0 {
                    // 前のテキストの終了位置と現在のテキストの開始位置の間隔を計算
                    let gap = item.x - lastEndX

                    // gap が一定以上なら空白を追加（文字幅の半分以上なら空白と判定）
                    if gap > 0.01 { // 閾値は調整可能
                        let spaceCount = max(1, Int(gap / 0.015)) // 空白の数を計算
                        lineText += String(repeating: " ", count: spaceCount)
                    } else {
                        lineText += " " // 最低でも1つの空白
                    }
                }

                lineText += item.text
                lastEndX = item.x + item.width
            }

            resultLines.append(lineText)
        }

        return resultLines.joined(separator: "\n")
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
