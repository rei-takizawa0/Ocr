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

        // When & Then: バナー広告を表示すべきでない
        XCTAssertFalse(sut.shouldShowBanner)
    }

    func testShouldShowInterstitial_OnFifthExecution_ShouldReturnTrue() {
        // Given: 課金していない状態
        mockPurchaseService.isPremiumValue = false

        // When: 4回実行
        for _ in 0..<4 {
            sut.recordOCRExecution()
            XCTAssertFalse(sut.shouldShowInterstitial())
        }

        // Then: 5回目で広告を表示すべき
        sut.recordOCRExecution()
        XCTAssertTrue(sut.shouldShowInterstitial())
    }

    func testShouldShowInterstitial_WhenPurchased_ShouldReturnFalse() {
        // Given: 課金済みの状態
        mockPurchaseService.isPremiumValue = true

        // When: 5回実行
        for _ in 0..<5 {
            sut.recordOCRExecution()
        }

        // Then: 広告を表示すべきでない
        XCTAssertFalse(sut.shouldShowInterstitial())
    }

    func testRecordOCRExecution_ShouldIncrementCounter() {
        // Given: 初期状態
        mockPurchaseService.isPremiumValue = false

        // When: 3回実行
        for _ in 0..<3 {
            sut.recordOCRExecution()
        }

        // Then: カウンターが正しく増加している
        XCTAssertFalse(sut.shouldShowInterstitial())

        // When: さらに2回実行（合計5回）
        sut.recordOCRExecution()
        sut.recordOCRExecution()

        // Then: 5回目で広告を表示すべき
        XCTAssertTrue(sut.shouldShowInterstitial())
    }

    func testShouldShowInterstitial_AfterShowing_ShouldResetCounter() {
        // Given: 課金していない状態で5回実行
        mockPurchaseService.isPremiumValue = false
        for _ in 0..<5 {
            sut.recordOCRExecution()
        }
        XCTAssertTrue(sut.shouldShowInterstitial())

        // When: 広告を表示した後
        _ = sut.shouldShowInterstitial() // カウンターをリセット

        // Then: 次の実行では広告を表示すべきでない
        sut.recordOCRExecution()
        XCTAssertFalse(sut.shouldShowInterstitial())
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
}
