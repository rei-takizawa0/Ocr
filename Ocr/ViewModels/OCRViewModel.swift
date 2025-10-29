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

    // MARK: - Published Properties

    @Published var recognizedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var shouldShowInterstitialAd: Bool = false

    // MARK: - Dependencies

    var modelContext: ModelContext?
    private let ocrService: VisionOCRService
    private let advertisementService: AdvertisementService
    private let sharingService: SharingService

    private var cancellables = Set<AnyCancellable>()
    private var ads: Ads
    private var showInterstitialAd:Bool
    // MARK: - Computed Properties

    var shouldShowBanner: Bool {
        advertisementService.shouldShowBanner
    }

    // MARK: - Initialization

    init(
        ocrService: VisionOCRService,
        advertisementService: AdvertisementService,
        sharingService: SharingService,
        showInterstitialAd: Bool
    ) {
        self.ocrService = ocrService
        self.advertisementService = advertisementService
        self.sharingService = sharingService
        let request = FetchDescriptor<Ads>()
        self.showInterstitialAd = showInterstitialAd
        if let existingAds = try? self.modelContext?.fetch(request).first {
            self.ads = existingAds
        }
        else
        {
            let newAds = Ads(count: 0)
            modelContext?.insert(newAds)
            self.ads = newAds
        }
    }

    // MARK: - Public Methods
    func addCount() async {
        await MainActor.run {
            ads.count += 1
            do {
                try modelContext?.save()
            } catch {
                print("Ads 保存エラー: \(error)")
            }
        }
    }
    
    func resetCount() async {
        await MainActor.run {
            ads.count = 1
            do {
                try modelContext?.save()
            } catch {
                print("Ads 保存エラー: \(error)")
            }
        }
    }

    func recognizeText(from image: UIImage) async {
        isProcessing = true
        errorMessage = nil

        do {
            let InterstitialCount = 10
            if ads.count > InterstitialCount {
                shouldShowInterstitialAd = true
                await resetCount()
            }
            else
            {
                await addCount()
            }
            
            let result = try await ocrService.recognizeText(from: image)
            recognizedText = result.text

            // OCR実行を記録

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
