//
//  AdvertisementServiceProtocol.swift
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

/// 広告サービスのプロトコル（DIP: 抽象に依存）
protocol AdvertisementServiceProtocol {
    /// 広告を表示すべきかどうか
    var shouldShowAds: AnyPublisher<Bool, Never> { get }

    /// バナー広告を表示すべきか
    var shouldShowBanner: Bool { get }

    /// インタースティシャル広告を表示すべきか
    func shouldShowInterstitial() -> Bool

    /// OCR処理が実行されたことを記録
    func recordOCRExecution()

    /// バナー広告をロード
    func loadBannerAd() async throws

    /// インタースティシャル広告をロード
    func loadInterstitialAd() async throws

    /// インタースティシャル広告を表示
    func showInterstitialAd() async throws
}

/// 広告サービスで発生するエラー
enum AdvertisementServiceError: Error {
    case adNotLoaded
    case adLoadFailed
    case adPresentationFailed
}
