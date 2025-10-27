//
//  OCRViewModel.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit
import Combine

/// OCR画面のViewModel（SRP: プレゼンテーションロジックのみの責任）
@MainActor
final class OCRViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var recognizedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var shouldShowInterstitialAd: Bool = false

    // MARK: - Dependencies (DIP: 抽象に依存)

    private let ocrService: OCRServiceProtocol
    private let advertisementService: AdvertisementServiceProtocol
    private let sharingService: SharingServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var shouldShowBanner: Bool {
        advertisementService.shouldShowBanner
    }

    // MARK: - Initialization

    init(
        ocrService: OCRServiceProtocol,
        advertisementService: AdvertisementServiceProtocol,
        sharingService: SharingServiceProtocol
    ) {
        self.ocrService = ocrService
        self.advertisementService = advertisementService
        self.sharingService = sharingService
    }

    // MARK: - Public Methods

    func recognizeText(from image: UIImage) async {
        isProcessing = true
        errorMessage = nil

        do {
            let result = try await ocrService.recognizeText(from: image)
            recognizedText = result.text

            // OCR実行を記録
            advertisementService.recordOCRExecution()

            // インタースティシャル広告を表示すべきかチェック
            if advertisementService.shouldShowInterstitial() {
                shouldShowInterstitialAd = true
            }
        } catch {
            errorMessage = handleError(error)
        }

        isProcessing = false
    }

    func copyText() {
        guard !recognizedText.isEmpty else { return }
        sharingService.copyToClipboard(recognizedText)
    }

    func shareText(from viewController: UIViewController, sourceView: UIView?) async {
        guard !recognizedText.isEmpty else { return }
        await sharingService.share(recognizedText, from: viewController, sourceView: sourceView)
    }

    func shareViaEmail(from viewController: UIViewController) async {
        guard !recognizedText.isEmpty else { return }
        do {
            try await sharingService.shareViaEmail(recognizedText, from: viewController)
        } catch {
            errorMessage = "メールを送信できません。メールアプリが設定されているか確認してください。"
        }
    }

    func dismissInterstitialAd() {
        shouldShowInterstitialAd = false
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) -> String {
        if let ocrError = error as? OCRServiceError {
            switch ocrError {
            case .invalidImage:
                return "画像が無効です。別の画像を選択してください。"
            case .recognitionFailed:
                return "テキスト認識に失敗しました。もう一度お試しください。"
            case .noTextFound:
                return "テキストが見つかりませんでした。別の画像を選択してください。"
            }
        }
        return "エラーが発生しました: \(error.localizedDescription)"
    }
}
