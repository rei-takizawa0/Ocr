//
//  StoreKitPurchaseService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import StoreKit
import Combine

/// StoreKitを使用した課金サービスの実装（SRP: 課金処理のみの責任）
final class StoreKitPurchaseService: PurchaseServiceProtocol {

    // MARK: - Properties

    private let productIds = ["com.ocr.premium.removeads"]
    private var products: [Product] = []
    private var purchasedProductIds = Set<String>()

    private let isPremiumSubject = CurrentValueSubject<Bool, Never>(false)
    private var updateListenerTask: Task<Void, Never>?

    // MARK: - PurchaseServiceProtocol

    var isPremium: Bool {
        isPremiumSubject.value
    }

    var isPremiumPublisher: AnyPublisher<Bool, Never> {
        isPremiumSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await updatePurchaseStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    func fetchProducts() async throws -> [PurchaseProduct] {
        do {
            let storeProducts = try await Product.products(for: productIds)
            self.products = storeProducts

            return storeProducts.map { product in
                PurchaseProduct(
                    id: product.id,
                    displayName: product.displayName,
                    description: product.description,
                    price: product.displayPrice
                )
            }
        } catch {
            throw PurchaseServiceError.productNotFound
        }
    }

    func purchase(productId: String) async throws {
        guard let product = products.first(where: { $0.id == productId }) else {
            throw PurchaseServiceError.productNotFound
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchaseStatus()

            case .userCancelled:
                throw PurchaseServiceError.userCancelled

            case .pending:
                break

            @unknown default:
                throw PurchaseServiceError.purchaseFailed
            }
        } catch {
            throw PurchaseServiceError.purchaseFailed
        }
    }

    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
        } catch {
            throw PurchaseServiceError.restoreFailed
        }
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let transaction = try? self?.checkVerified(result) else {
                    continue
                }

                await transaction.finish()
                await self?.updatePurchaseStatus()
            }
        }
    }

    private func updatePurchaseStatus() async {
        var purchasedIds = Set<String>()

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            if transaction.revocationDate == nil {
                purchasedIds.insert(transaction.productID)
            }
        }

        self.purchasedProductIds = purchasedIds
        let hasPremium = !purchasedIds.isEmpty

        await MainActor.run {
            self.isPremiumSubject.send(hasPremium)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseServiceError.purchaseFailed
        case .verified(let safe):
            return safe
        }
    }
}
