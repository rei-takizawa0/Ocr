//
//  SettingsViewModel.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import Combine

/// 設定画面のViewModel（SRP: 設定関連のプレゼンテーションロジックのみの責任）
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isPremium: Bool = false
    @Published var availableProducts: [PurchaseProduct] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showRestoreSuccess: Bool = false

    // MARK: - Dependencies

    private let purchaseService: StoreKitPurchaseService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - URLs

    let xURL = URL(string: "https://example.com/terms")!

    // MARK: - Initialization

    init(purchaseService: StoreKitPurchaseService) {
        self.purchaseService = purchaseService
        observePurchaseStatus()
        self.isPremium = purchaseService.isPremium
    }

    // MARK: - Public Methods

    func fetchProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let products = try await purchaseService.fetchProducts()
            availableProducts = products
        } catch {
            errorMessage = handleError(error)
        }

        isLoading = false
    }

    func purchase(productId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await purchaseService.purchase(productId: productId)
            // 購入成功
        } catch {
            errorMessage = handlePurchaseError(error)
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        showRestoreSuccess = false

        do {
            try await purchaseService.restorePurchases()
            showRestoreSuccess = true
        } catch {
            errorMessage = "購入履歴の復元に失敗しました。購入済みの場合は、しばらく待ってから再度お試しください。"
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func observePurchaseStatus() {
        purchaseService.isPremiumPublisher
            .sink { [weak self] isPremium in
                self?.isPremium = isPremium
            }
            .store(in: &cancellables)
    }

    private func handleError(_ error: Error) -> String {
        if let purchaseError = error as? PurchaseServiceError {
            switch purchaseError {
            case .productNotFound:
                return "商品が見つかりませんでした。"
            case .purchaseFailed:
                return "購入に失敗しました。"
            case .userCancelled:
                return "" // ユーザーがキャンセルした場合はメッセージを表示しない
            case .restoreFailed:
                return "復元に失敗しました。"
            }
        }
        return "エラーが発生しました: \(error.localizedDescription)"
    }

    private func handlePurchaseError(_ error: Error) -> String {
        if let purchaseError = error as? PurchaseServiceError {
            switch purchaseError {
            case .userCancelled:
                return "" // ユーザーがキャンセルした場合はメッセージを表示しない
            default:
                return handleError(error)
            }
        }
        return handleError(error)
    }
}
