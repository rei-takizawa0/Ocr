//
//  AdvertisementService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import Combine

/// 広告管理サービスの実装（SRP: 広告表示ロジックのみの責任）
final class AdvertisementService: AdvertisementServiceProtocol {

    // MARK: - Properties

    private let purchaseService: PurchaseServiceProtocol
    private var executionCount: Int = 0
    private let interstitialFrequency: Int = 5
    private var cancellables = Set<AnyCancellable>()

    private let shouldShowAdsSubject = CurrentValueSubject<Bool, Never>(true)

    // MARK: - AdvertisementServiceProtocol

    var shouldShowAds: AnyPublisher<Bool, Never> {
        shouldShowAdsSubject.eraseToAnyPublisher()
    }

    var shouldShowBanner: Bool {
        return !purchaseService.isPremium
    }

    // MARK: - Initialization

    init(purchaseService: PurchaseServiceProtocol) {
        self.purchaseService = purchaseService
        observePurchaseStatus()
    }

    // MARK: - Public Methods

    func shouldShowInterstitial() -> Bool {
        guard !purchaseService.isPremium else {
            return false
        }

        if executionCount >= interstitialFrequency {
            executionCount = 0 // リセット
            return true
        }

        return false
    }

    func recordOCRExecution() {
        executionCount += 1
    }

    func loadBannerAd() async throws {
        // TODO: AdMob SDKとの統合
        // 実際の実装ではAdMobのバナー広告をロード
        guard shouldShowBanner else {
            throw AdvertisementServiceError.adNotLoaded
        }
    }

    func loadInterstitialAd() async throws {
        // TODO: AdMob SDKとの統合
        // 実際の実装ではAdMobのインタースティシャル広告をロード
        guard !purchaseService.isPremium else {
            throw AdvertisementServiceError.adNotLoaded
        }
    }

    func showInterstitialAd() async throws {
        // TODO: AdMob SDKとの統合
        // 実際の実装ではAdMobのインタースティシャル広告を表示
        guard shouldShowInterstitial() else {
            throw AdvertisementServiceError.adNotLoaded
        }
    }

    // MARK: - Private Methods

    private func observePurchaseStatus() {
        purchaseService.isPremiumPublisher
            .map { !$0 } // 課金済みなら広告を表示しない
            .sink { [weak self] shouldShow in
                self?.shouldShowAdsSubject.send(shouldShow)
            }
            .store(in: &cancellables)
    }
}
