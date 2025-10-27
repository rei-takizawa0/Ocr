//
//  DependencyContainer.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation

/// 依存性注入コンテナ（DIP: 依存関係を一元管理）
final class DependencyContainer {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Services (遅延初期化でメモリ効率を向上)

    private lazy var _ocrService: OCRServiceProtocol = {
        VisionOCRService()
    }()

    private lazy var _purchaseService: PurchaseServiceProtocol = {
        StoreKitPurchaseService()
    }()

    private lazy var _advertisementService: AdvertisementServiceProtocol = {
        AdvertisementService(purchaseService: purchaseService)
    }()

    private lazy var _sharingService: SharingServiceProtocol = {
        SharingService()
    }()

    // MARK: - Public Properties

    var ocrService: OCRServiceProtocol {
        _ocrService
    }

    var purchaseService: PurchaseServiceProtocol {
        _purchaseService
    }

    var advertisementService: AdvertisementServiceProtocol {
        _advertisementService
    }

    var sharingService: SharingServiceProtocol {
        _sharingService
    }

    // MARK: - Factory Methods

    func makeOCRViewModel() -> OCRViewModel {
        OCRViewModel(
            ocrService: ocrService,
            advertisementService: advertisementService,
            sharingService: sharingService
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(purchaseService: purchaseService)
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Test Support

    #if DEBUG
    /// テスト用に依存関係をリセット
    func reset() {
        _ocrService = VisionOCRService()
        _purchaseService = StoreKitPurchaseService()
        _advertisementService = AdvertisementService(purchaseService: purchaseService)
        _sharingService = SharingService()
    }
    #endif
}
