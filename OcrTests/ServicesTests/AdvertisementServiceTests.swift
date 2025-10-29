//
//  AdvertisementServiceTests.swift
//  OcrTests
//
//  Created by Claude Code
//

import XCTest
import Combine
@testable import Ocr

final class AdvertisementServiceTests: XCTestCase {

    var sut: AdvertisementService!
    var mockPurchaseService: MockPurchaseService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
        mockPurchaseService = MockPurchaseService()
        sut = AdvertisementService(purchaseService: mockPurchaseService)
    }

    override func tearDown() {
        sut = nil
        mockPurchaseService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func testShouldShowBanner_WhenNotPurchased_ShouldReturnTrue() {
        // Given: 課金していない状態
        mockPurchaseService.isPremiumValue = false

        // When & Then: バナー広告を表示すべき
        XCTAssertTrue(sut.shouldShowBanner)
    }

    func testShouldShowBanner_WhenPurchased_ShouldReturnFalse() {
        // Given: 課金済みの状態
        mockPurchaseService.isPremiumValue = true

        // When: 新しいAdvertisementServiceを作成（初期化時にpremium状態を反映）
        sut = AdvertisementService(purchaseService: mockPurchaseService)

        // Then: バナー広告を表示すべきでない
        XCTAssertFalse(sut.shouldShowBanner)
    }

    func testShouldShowAds_WhenPurchaseStatusChanges_ShouldUpdateCorrectly() {
        // Given: 課金していない状態
        mockPurchaseService.isPremiumValue = false

        let expectation = XCTestExpectation(description: "Should receive ads status update")
        var receivedValues: [Bool] = []

        sut.shouldShowAds
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: 課金状態に変更
        mockPurchaseService.isPremiumValue = true
        mockPurchaseService.isPremiumSubject.send(true)

        // Then: 正しい値が通知される
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [true, false])
    }

    func testLoadBannerAd_WhenNotPremium_ShouldNotThrowError() async {
        // Given: 課金していない状態
        mockPurchaseService.isPremiumValue = false
        sut = AdvertisementService(purchaseService: mockPurchaseService)

        // When & Then: バナー広告のロードに成功すべき
        do {
            try await sut.loadBannerAd()
        } catch {
            XCTFail("バナー広告のロードに失敗すべきではない")
        }
    }

    func testLoadBannerAd_WhenPremium_ShouldThrowError() async {
        // Given: 課金済みの状態
        mockPurchaseService.isPremiumValue = true
        sut = AdvertisementService(purchaseService: mockPurchaseService)

        // When & Then: エラーがスローされるべき
        do {
            try await sut.loadBannerAd()
            XCTFail("プレミアム状態ではエラーがスローされるべき")
        } catch {
            XCTAssertTrue(error is AdvertisementServiceError)
        }
    }

    func testLoadInterstitialAd_WhenNotPremium_ShouldNotThrowError() async {
        // Given: 課金していない状態
        mockPurchaseService.isPremiumValue = false
        sut = AdvertisementService(purchaseService: mockPurchaseService)

        // When & Then: インタースティシャル広告のロードに成功すべき
        do {
            try await sut.loadInterstitialAd()
        } catch {
            XCTFail("インタースティシャル広告のロードに失敗すべきではない")
        }
    }

    func testLoadInterstitialAd_WhenPremium_ShouldThrowError() async {
        // Given: 課金済みの状態
        mockPurchaseService.isPremiumValue = true
        sut = AdvertisementService(purchaseService: mockPurchaseService)

        // When & Then: エラーがスローされるべき
        do {
            try await sut.loadInterstitialAd()
            XCTFail("プレミアム状態ではエラーがスローされるべき")
        } catch {
            XCTAssertTrue(error is AdvertisementServiceError)
        }
    }
}
