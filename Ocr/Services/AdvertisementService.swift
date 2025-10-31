//
//  AdvertisementService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import Combine

/// 広告タイプ
enum AdType {
    case banner
    case interstitial
}

/// 広告サービスで発生するエラー
enum AdvertisementServiceError: Error {
    case adNotLoaded
    case adLoadFailed
    case adPresentationFailed
}

/// 広告管理サービスの実装（SRP: 広告表示ロジックのみの責任）
final class AdvertisementService {

    // MARK: - Properties

    private let purchaseService: StoreKitPurchaseService
    private var cancellables = Set<AnyCancellable>()

    private let shouldShowAdsSubject = CurrentValueSubject<Bool, Never>(true)

    // MARK: - Public Properties

    var shouldShowAds: AnyPublisher<Bool, Never> {
        shouldShowAdsSubject.eraseToAnyPublisher()
    }

    var shouldShowBanner: Bool {
        return !purchaseService.isPremium
    }

    // MARK: - Initialization

    init(purchaseService: StoreKitPurchaseService) {
        self.purchaseService = purchaseService
        observePurchaseStatus()
    }

    // MARK: - Public Methods

    func loadBannerAd() async throws {
        // TODO: AdMob SDKとの統合
        // 実際の実装ではAdMobを使用してバナー広告をロード
        guard shouldShowBanner else {
            throw AdvertisementServiceError.adNotLoaded
        }
    }

    func loadInterstitialAd() async throws {
        // TODO: AdMob SDKとの統合
        // 実際の実装ではAdMobを使用してインタースティシャル広告をロード
        guard !purchaseService.isPremium else {
            throw AdvertisementServiceError.adNotLoaded
        }
    }

    // MARK: - Private Methods

    private func observePurchaseStatus() {
        purchaseService.isPremiumPublisher
            .map { !$0 } // プレミアム購入済みの場合は広告を表示しない
            .sink { [weak self] shouldShow in
                self?.shouldShowAdsSubject.send(shouldShow)
            }
            .store(in: &cancellables)
    }
}
