import Foundation
import UIKit
import Vision
import CoreImage
import Accelerate

enum OCRServiceError: Error, Equatable {
    case invalidImage
    case recognitionFailed
    case noTextFound
}

/// Vision frameworkを使用した高精度OCRサービス
final class VisionOCRService {

    // MARK: - Constants

    /// 信頼度の閾値：この値以下の認識結果は□で置き換える
    private static let confidenceThreshold: Float = 0.3

    /// 画像の最大解像度（ピクセル）- より高解像度で処理
    private static let maxImageDimension: CGFloat = 4096

    // MARK: - Public Methods

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        // 1. 画像を高解像度にアップスケール
        guard let highResImage = upscaleImage(image),
              let preprocessedImage = preprocessImageForOCR(highResImage),
              let cgImage = preprocessedImage.cgImage else {
            throw OCRServiceError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        let request = createOptimizedTextRecognitionRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])

                guard let observations = request.results, !observations.isEmpty else {
                    continuation.resume(throwing: OCRServiceError.noTextFound)
                    return
                }

                let recognizedText = extractLyricsTextWithConfidence(from: observations)

                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRServiceError.noTextFound)
                } else {
                    let confidence = calculateAverageConfidence(from: observations)
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

    /// Visionリクエストを最適化設定で作成
    private func createOptimizedTextRecognitionRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()

        // 最高精度モードに設定
        request.recognitionLevel = .accurate

        // 言語補正を有効化
        request.usesLanguageCorrection = true

        // 日本語と英語を優先的に認識
        request.recognitionLanguages = ["ja-JP", "en-US"]

        // 自動言語検出を有効化
        request.automaticallyDetectsLanguage = true

        // 最小テキスト高さを設定（小さい文字も検出）
        request.minimumTextHeight = 0.005

        // 最新のリビジョンを使用
        request.revision = VNRecognizeTextRequestRevision3

        // カスタム単語を設定（必要に応じて）
        request.customWords = []

        return request
    }

    /// 画像を高解像度にアップスケール
    private func upscaleImage(_ image: UIImage) -> UIImage? {
        let targetSize = calculateOptimalSize(for: image.size)

        // 高品質な描画設定
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        // 補間品質を最高に設定
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        context.interpolationQuality = .high

        image.draw(in: CGRect(origin: .zero, size: targetSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 最適なサイズを計算
    private func calculateOptimalSize(for size: CGSize) -> CGSize {
        let maxDimension = max(size.width, size.height)

        // 既に十分大きい場合はそのまま
        if maxDimension >= Self.maxImageDimension {
            return size
        }

        // アスペクト比を維持しながら拡大
        let scale = Self.maxImageDimension / maxDimension
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    /// 高度な画像前処理（ノイズ除去 + 適応的二値化 + シャープ化）
    private func preprocessImageForOCR(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext(options: [.useSoftwareRenderer: false])

        // 1. ノイズ除去
        let noiseReduction = CIFilter(name: "CINoiseReduction")!
        noiseReduction.setValue(ciImage, forKey: kCIInputImageKey)
        noiseReduction.setValue(0.02, forKey: "inputNoiseLevel")
        noiseReduction.setValue(0.4, forKey: "inputSharpness")

        // 2. コントラストと明るさの自動調整
        let autoEnhance = CIFilter(name: "CIColorControls")!
        autoEnhance.setValue(noiseReduction.outputImage, forKey: kCIInputImageKey)
        autoEnhance.setValue(1.3, forKey: kCIInputContrastKey)
        autoEnhance.setValue(0.1, forKey: kCIInputBrightnessKey)
        autoEnhance.setValue(0.0, forKey: kCIInputSaturationKey) // グレースケール化

        // 3. ガンマ補正で明暗を調整
        let gammaAdjust = CIFilter(name: "CIGammaAdjust")!
        gammaAdjust.setValue(autoEnhance.outputImage, forKey: kCIInputImageKey)
        gammaAdjust.setValue(0.75, forKey: "inputPower")

        // 4. アンシャープマスクで文字を鮮明に
        let unsharpMask = CIFilter(name: "CIUnsharpMask")!
        unsharpMask.setValue(gammaAdjust.outputImage, forKey: kCIInputImageKey)
        unsharpMask.setValue(2.5, forKey: kCIInputRadiusKey)
        unsharpMask.setValue(0.8, forKey: kCIInputIntensityKey)

        // 5. トーンカーブで白黒をはっきりさせる
        let toneCurve = CIFilter(name: "CIToneCurve")!
        toneCurve.setValue(unsharpMask.outputImage, forKey: kCIInputImageKey)
        toneCurve.setValue(CIVector(x: 0, y: 0.1), forKey: "inputPoint0")
        toneCurve.setValue(CIVector(x: 0.25, y: 0.2), forKey: "inputPoint1")
        toneCurve.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
        toneCurve.setValue(CIVector(x: 0.75, y: 0.8), forKey: "inputPoint3")
        toneCurve.setValue(CIVector(x: 1, y: 0.95), forKey: "inputPoint4")

        guard let outputImage = toneCurve.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    /// 歌詞テキストを信頼度付きで抽出し、低信頼度の文字を□に置き換え
    private func extractLyricsTextWithConfidence(from observations: [VNRecognizedTextObservation]) -> String {
        struct TextElement {
            let y: CGFloat
            let x: CGFloat
            let text: String
            let confidence: Float
        }

        var elements: [TextElement] = []

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }

            let box = observation.boundingBox
            let processedText: String

            // 信頼度が閾値以下の場合は□に置き換え
            if candidate.confidence < Self.confidenceThreshold {
                processedText = String(repeating: "□", count: max(1, candidate.string.count))
            } else {
                processedText = candidate.string
            }

            elements.append(TextElement(
                y: box.origin.y,
                x: box.origin.x,
                text: processedText,
                confidence: candidate.confidence
            ))
        }

        // Y座標でソート（上から下へ）、同一行内ではX座標（左から右へ）
        elements.sort { e1, e2 in
            if abs(e1.y - e2.y) < 0.015 {
                return e1.x < e2.x
            } else {
                return e1.y > e2.y
            }
        }

        // 各テキスト要素を改行で区切って出力
        var resultLines: [String] = []
        var previousY: CGFloat?

        for element in elements {
            let trimmedText = element.text.trimmingCharacters(in: .whitespaces)

            if let prevY = previousY {
                // Y座標の差が大きければ空行を追加（段落の区切り）
                if abs(prevY - element.y) > 0.05 {
                    resultLines.append("") // 空行を追加
                }
            }

            // テキストが空でない場合のみ追加
            if !trimmedText.isEmpty {
                resultLines.append(trimmedText)
            }

            previousY = element.y
        }

        return resultLines.joined(separator: "\n")
    }

    /// 平均信頼度を計算
    private func calculateAverageConfidence(from observations: [VNRecognizedTextObservation]) -> Float {
        let confidences = observations.compactMap { $0.topCandidates(1).first?.confidence }
        guard !confidences.isEmpty else { return 0.0 }
        return confidences.reduce(0, +) / Float(confidences.count)
    }
}

// MARK: - Extensions

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
