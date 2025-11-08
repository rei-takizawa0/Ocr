//
//  OCRViewModel.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit
import Combine
import SwiftData

/// OCR画面のViewModel（SRP: プレゼンテーションロジックのみの責任）
@MainActor
final class OCRViewModel: ObservableObject {

    // MARK: - Constants

    private static let interstitialAdThreshold = 10

    // MARK: - Published Properties

    @Published var recognizedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var shouldShowInterstitialAd: Bool = false

    // MARK: - Dependencies

    private let ocrService: VisionOCRService
    private let advertisementService: AdvertisementService
    private let sharingService: SharingService
    private let adRepository: AdCounterRepository
    private let lyricIDRepository: LyricIDRepository

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var shouldShowBanner: Bool {
        advertisementService.shouldShowBanner
    }

    // MARK: - Initialization

    init(
        ocrService: VisionOCRService,
        advertisementService: AdvertisementService,
        sharingService: SharingService,
        adRepository: AdCounterRepository,
        lyricIDRepository: LyricIDRepository
    ) {
        self.ocrService = ocrService
        self.advertisementService = advertisementService
        self.sharingService = sharingService
        self.adRepository = adRepository
        self.lyricIDRepository = lyricIDRepository
        // 購入状態の変更を監視
        advertisementService.shouldShowAds
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func recognizeText(from image: UIImage) async {
        isProcessing = true
        errorMessage = nil

        do {
            // 無料ユーザーの広告表示を処理
            if advertisementService.shouldShowBanner {
                try handleAdvertisementDisplay()
            }

            let recognized = try await ocrService.recognizeText(from: image)
            let repo = LyricsRepository()
            _ = try? await repo.save(id: lyricIDRepository.fetchID().id, content: recognized.text)
            recognizedText = recognized.text

        } catch {
            errorMessage = handleError(error)
        }

        isProcessing = false
    }

    func copyText() {
        guard !recognizedText.isEmpty else { return }
        sharingService.copyClipboard(recognizedText)
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

    private func handleAdvertisementDisplay() throws {
        let currentCount = try adRepository.getCurrentCount()

        if currentCount >= Self.interstitialAdThreshold {
            shouldShowInterstitialAd = true
            try adRepository.resetCounter()
        } else {
            try adRepository.incrementCounter()
        }
    }

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
