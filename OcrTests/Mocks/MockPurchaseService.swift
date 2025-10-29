//
//  MockPurchaseService.swift
//  OcrTests
//
//  Created by Claude Code
//

import Foundation
import Combine
@testable import Ocr

/// StoreKitPurchaseServiceと同じインターフェースを持つテスト用モック
final class MockPurchaseService {

    var isPremiumValue: Bool = false
    let isPremiumSubject = CurrentValueSubject<Bool, Never>(false)

    var isPremium: Bool {
        isPremiumValue
    }

    var isPremiumPublisher: AnyPublisher<Bool, Never> {
        isPremiumSubject.eraseToAnyPublisher()
    }

    var fetchProductsCalled = false
    var purchaseCalled = false
    var restorePurchasesCalled = false
    var mockProducts: [PurchaseProduct] = []
    var shouldThrowError = false

    func fetchProducts() async throws -> [PurchaseProduct] {
        fetchProductsCalled = true
        if shouldThrowError {
            throw PurchaseServiceError.productNotFound
        }
        return mockProducts
    }

    func purchase(productId: String) async throws {
        purchaseCalled = true
        if shouldThrowError {
            throw PurchaseServiceError.purchaseFailed
        }
        isPremiumValue = true
        isPremiumSubject.send(true)
    }

    func restorePurchases() async throws {
        restorePurchasesCalled = true
        if shouldThrowError {
            throw PurchaseServiceError.restoreFailed
        }
    }
}
