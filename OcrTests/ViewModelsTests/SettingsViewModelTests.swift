//
//  SettingsViewModelTests.swift
//  OcrTests
//
//  Created by Claude Code
//

import XCTest
import Combine
@testable import Ocr

final class SettingsViewModelTests: XCTestCase {

    var sut: SettingsViewModel!
    var mockPurchaseService: MockPurchaseService!
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()
        cancellables = []
        mockPurchaseService = MockPurchaseService()
        sut = SettingsViewModel(purchaseService: mockPurchaseService)
    }

    override func tearDown() {
        sut = nil
        mockPurchaseService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    @MainActor
    func testIsPremium_WhenNotPurchased_ShouldReturnFalse() {
        // Given: 課金していない状態
        mockPurchaseService.isPremiumValue = false

        // When & Then: プレミアムではない
        XCTAssertFalse(sut.isPremium)
    }

    @MainActor
    func testIsPremium_WhenPurchased_ShouldReturnTrue() {
        // Given: 課金済みの状態
        mockPurchaseService.isPremiumValue = true
        mockPurchaseService.isPremiumSubject.send(true)

        // When & Then: プレミアムである
        let expectation = XCTestExpectation(description: "Premium status updated")

        sut.$isPremium
            .dropFirst()
            .sink { isPremium in
                XCTAssertTrue(isPremium)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    @MainActor
    func testFetchProducts_ShouldLoadProducts() async {
        // Given: 利用可能な商品
        mockPurchaseService.mockProducts = [
            PurchaseProduct(
                id: "com.ocr.premium.removeads",
                displayName: "広告削除",
                description: "すべての広告を削除します",
                price: "¥370"
            )
        ]

        // When: 商品を取得
        await sut.fetchProducts()

        // Then: 商品がロードされる
        XCTAssertEqual(sut.availableProducts.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    @MainActor
    func testPurchase_WithValidProduct_ShouldUpdatePremiumStatus() async {
        // Given: 商品をロード
        mockPurchaseService.mockProducts = [
            PurchaseProduct(
                id: "com.ocr.premium.removeads",
                displayName: "広告削除",
                description: "すべての広告を削除します",
                price: "¥370"
            )
        ]
        await sut.fetchProducts()

        // When: 商品を購入
        await sut.purchase(productId: "com.ocr.premium.removeads")

        // Then: 購入が成功し、エラーがない
        XCTAssertTrue(mockPurchaseService.purchaseCalled)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func testPurchase_WithError_ShouldShowErrorMessage() async {
        // Given: エラーを返すサービス
        mockPurchaseService.shouldThrowError = true

        // When: 購入を試みる
        await sut.purchase(productId: "invalid")

        // Then: エラーメッセージが表示される
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func testRestorePurchases_ShouldCallService() async {
        // When: 購入履歴を復元
        await sut.restorePurchases()

        // Then: サービスが呼ばれる
        XCTAssertTrue(mockPurchaseService.restorePurchasesCalled)
        XCTAssertNil(sut.errorMessage)
    }

    @MainActor
    func testRestorePurchases_WithError_ShouldShowErrorMessage() async {
        // Given: エラーを返すサービス
        mockPurchaseService.shouldThrowError = true

        // When: 購入履歴を復元
        await sut.restorePurchases()

        // Then: エラーメッセージが表示される
        XCTAssertNotNil(sut.errorMessage)
    }

    @MainActor
    func testGetAppVersion_ShouldReturnVersion() {
        // When: アプリバージョンを取得
        let version = sut.appVersion

        // Then: バージョン情報が返される
        XCTAssertFalse(version.isEmpty)
    }
}
