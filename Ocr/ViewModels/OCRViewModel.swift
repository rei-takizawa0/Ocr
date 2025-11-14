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
internal import Auth

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
    @Published var userPlan: UserPlan?
    @Published var premiumOCRRemainingCount: Int = 0

    // MARK: - Dependencies

    private let ocrService: VisionOCRService
    private let advertisementService: AdvertisementService
    private let sharingService: SharingService
    private let adRepository: AdCounterRepository
    private let lyricIDRepository: LyricIDRepository
    private let userPlanRepository: UserPlanRepository
    private let authService: SupabaseAuthService

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
        lyricIDRepository: LyricIDRepository,
        userPlanRepository: UserPlanRepository,
        authService: SupabaseAuthService
    ) {
        self.ocrService = ocrService
        self.advertisementService = advertisementService
        self.sharingService = sharingService
        self.adRepository = adRepository
        self.lyricIDRepository = lyricIDRepository
        self.userPlanRepository = userPlanRepository
        self.authService = authService

        // 購入状態の変更を監視
        advertisementService.shouldShowAds
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // 認証状態の変更を監視してプラン情報を更新
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    Task { @MainActor in
                        await self?.fetchUserPlan()
                    }
                } else {
                    self?.userPlan = nil
                    self?.premiumOCRRemainingCount = 0
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// ユーザープラン情報を取得
    func fetchUserPlan() async {
        guard authService.isAuthenticated,
              let userId = authService.currentUser?.id else {
            userPlan = nil
            premiumOCRRemainingCount = 0
            return
        }

        do {
            let plan = try await userPlanRepository.getPlan(userId: userId)
            userPlan = plan
            premiumOCRRemainingCount = plan.remainingCount
        } catch {
        }
    }

    /// 高機能OCRを使用してテキストを認識
    func recognizeText(from image: UIImage, usePremiumOCR: Bool = false) async {
        isProcessing = true
        errorMessage = nil

        do {
            // プレミアムOCRを使用する場合の回数チェック
            if usePremiumOCR {
                guard authService.isAuthenticated,
                      let userId = authService.currentUser?.id else {
                    errorMessage = "高機能OCRを使用できません"
                    isProcessing = false
                    return
                }

                // 最新のプラン情報を取得
                await fetchUserPlan()

                guard let plan = userPlan, plan.remainingCount > 0 else {
                    errorMessage = "高機能OCRの残り回数が0です"
                    isProcessing = false
                    return
                }
            }

            // 無料ユーザーの広告表示を処理
            if advertisementService.shouldShowBanner {
                try handleAdvertisementDisplay()
            }

            let recognized = try await ocrService.recognizeText(from: image)
            let repo = LyricsRepository()
            _ = try? await repo.save(id: lyricIDRepository.getCurrentID(), content: recognized.text)
            recognizedText = recognized.text

            // プレミアムOCRを使用した場合、使用回数を更新
            if usePremiumOCR,
               let userId = authService.currentUser?.id,
               let currentPlan = userPlan {
                let newCount = currentPlan.ocrUsedCount + 1
                try await userPlanRepository.incrementOCRCount(userId: userId, newOcrCount: newCount)
                // プラン情報を再取得
                await fetchUserPlan()
            }

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
        return "エラーが発生しました"
    }
}
