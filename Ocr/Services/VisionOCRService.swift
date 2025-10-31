import Foundation
import UIKit
import Vision
import ImageIO
import CoreImage

enum OCRServiceError: Error, Equatable {
    case invalidImage
    case recognitionFailed
    case noTextFound
}

final class VisionOCRService {

    // MARK: - Public Methods

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let preprocessedImage = preprocessLyricsImage(image),
              let cgImage = preprocessedImage.cgImage else {
            throw OCRServiceError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        let request = createTextRecognitionRequest()
        configureRequest(request)

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                guard let observations = request.results, !observations.isEmpty else {
                    continuation.resume(throwing: OCRServiceError.noTextFound)
                    return
                }

                let recognizedText = self.extractLyricsText(from: observations)

                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRServiceError.noTextFound)
                } else {
                    let confidence = self.calculateAverageConfidence(from: observations)
                    let result = OCRResult(
                        text: recognizedText,
                        confidence: confidence,
                        processedImage: preprocessedImage
                    )
                    continuation.resume(returning: result)
                }

            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Private Methods

    private func createTextRecognitionRequest() -> VNRecognizeTextRequest {
        VNRecognizeTextRequest()
    }

    /// 歌詞向けに最適化された設定
    private func configureRequest(_ request: VNRecognizeTextRequest) {
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        request.recognitionLanguages = ["ja", "en"]
        request.minimumTextHeight = 0.001
        request.revision = VNRecognizeTextRequestRevision3
    }

    /// 歌詞画像の前処理（コントラスト強化 + 二値化 + シャープ化）
    private func preprocessLyricsImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()

        // 明るさとコントラスト調整
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorFilter.setValue(1.1, forKey: kCIInputContrastKey)
        colorFilter.setValue(0.05, forKey: kCIInputBrightnessKey)

        // グレースケール化
        let grayFilter = CIFilter(name: "CIPhotoEffectMono")!
        grayFilter.setValue(colorFilter.outputImage, forKey: kCIInputImageKey)

        // 軽いシャープ化で細文字を強調
        let sharpen = CIFilter(name: "CISharpenLuminance")!
        sharpen.setValue(grayFilter.outputImage, forKey: kCIInputImageKey)
        sharpen.setValue(0.6, forKey: kCIInputSharpnessKey)

        guard let output = sharpen.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    /// 歌詞向け — 改行・順序を維持して整形
    /// 歌詞向け — 改行位置を再現して出力
    private func extractLyricsText(from observations: [VNRecognizedTextObservation]) -> String {
        // 各観測結果を (y位置, x位置, テキスト) のペアで保持
        var lines: [(y: CGFloat, x: CGFloat, text: String)] = []

        for obs in observations {
            guard let candidate = obs.topCandidates(1).first else { continue }
            let box = obs.boundingBox
            lines.append((y: box.origin.y, x: box.origin.x, text: candidate.string))
        }

        // Y軸（上→下）でソート、同一行内ではX軸（左→右）
        lines.sort {
            if abs($0.y - $1.y) < 0.02 {
                return $0.x < $1.x
            } else {
                return $0.y > $1.y
            }
        }

        // 改行を復元
        var resultLines: [String] = []
        var currentLine: String = ""
        var previousY: CGFloat?

        for (y, _, text) in lines {
            if let prevY = previousY {
                // 行間距離が大きければ改行扱い（0.02〜0.04 は経験上ちょうどよい閾値）
                if abs(prevY - y) > 0.03 {
                    resultLines.append(currentLine.trimmingCharacters(in: .whitespaces))
                    currentLine = text
                } else {
                    currentLine += " " + text
                }
            } else {
                currentLine = text
            }
            previousY = y
        }

        // 最終行追加
        if !currentLine.isEmpty {
            resultLines.append(currentLine.trimmingCharacters(in: .whitespaces))
        }

        // 改行を維持して結合
        return resultLines.joined(separator: "\n")
    }

    private func calculateAverageConfidence(from observations: [VNRecognizedTextObservation]) -> Float {
        let confidences = observations.compactMap { $0.topCandidates(1).first?.confidence }
        guard !confidences.isEmpty else { return 0.0 }
        return confidences.reduce(0, +) / Float(confidences.count)
    }
}

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
