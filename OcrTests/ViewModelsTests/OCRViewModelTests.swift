//
//  OCRViewModelTests.swift
//  OcrTests
//
//  Created by Claude Code
//

import XCTest
import Combine
@testable import Ocr

final class OCRViewModelTests: XCTestCase {

    var sut: OCRViewModel!
    var mockOCRService: MockOCRService!
    var mockAdService: MockAdvertisementService!
    var mockPurchaseService: MockPurchaseService!
    var mockSharingService: MockSharingService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
        mockOCRService = MockOCRService()
        mockPurchaseService = MockPurchaseService()
        mockAdService = MockAdvertisementService(purchaseService: mockPurchaseService)
        mockSharingService = MockSharingService()

        sut = OCRViewModel(
            ocrService: mockOCRService,
            advertisementService: mockAdService,
            sharingService: mockSharingService
        )
    }

    override func tearDown() {
        sut = nil
        mockOCRService = nil
        mockAdService = nil
        mockPurchaseService = nil
        mockSharingService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func testRecognizeText_WithValidImage_ShouldUpdateRecognizedText() async {
        // Given: 有効な画像
        let image = createTestImage()
        let expectedText = "Test Text"
        mockOCRService.mockResult = OCRResult(text: expectedText, confidence: 0.95)

        // When: OCR処理を実行
        await sut.recognizeText(from: image)

        // Then: 認識されたテキストが更新される
        XCTAssertEqual(sut.recognizedText, expectedText)
        XCTAssertFalse(sut.isProcessing)
        XCTAssertNil(sut.errorMessage)
    }

    func testRecognizeText_WithError_ShouldShowErrorMessage() async {
        // Given: エラーを返すサービス
        let image = createTestImage()
        mockOCRService.shouldThrowError = true

        // When: OCR処理を実行
        await sut.recognizeText(from: image)

        // Then: エラーメッセージが表示される
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.recognizedText.isEmpty)
        XCTAssertFalse(sut.isProcessing)
    }

    func testRecognizeText_ShouldRecordExecution() async {
        // Given: 有効な画像
        let image = createTestImage()
        mockOCRService.mockResult = OCRResult(text: "Test", confidence: 0.95)

        // When: OCR処理を実行
        await sut.recognizeText(from: image)

        // Then: 実行回数が記録される
        XCTAssertTrue(mockAdService.recordOCRExecutionCalled)
    }

    func testCopyText_ShouldCallSharingService() {
        // Given: 認識されたテキスト
        sut.recognizedText = "Text to copy"

        // When: コピーを実行
        sut.copyText()

        // Then: 共有サービスが呼ばれる
        XCTAssertTrue(mockSharingService.copyToClipboardCalled)
    }

    func testShouldShowBanner_WhenNotPremium_ShouldReturnTrue() {
        // Given: プレミアムではない状態
        mockPurchaseService.isPremiumValue = false

        // When & Then: バナーを表示すべき
        XCTAssertTrue(mockAdService.shouldShowBanner)
    }

    func testShouldShowInterstitial_OnFifthExecution_ShouldReturnTrue() async {
        // Given: 4回実行済み
        let image = createTestImage()
        mockOCRService.mockResult = OCRResult(text: "Test", confidence: 0.95)

        for _ in 0..<4 {
            await sut.recognizeText(from: image)
        }

        // When: 5回目を実行
        await sut.recognizeText(from: image)

        // Then: インタースティシャル広告を表示すべき
        XCTAssertTrue(mockAdService.shouldShowInterstitial())
    }

    // MARK: - Helper Methods

    private func createTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }
}

// MARK: - Mock Services

final class MockOCRService: OCRServiceProtocol {
    var mockResult: OCRResult?
    var shouldThrowError = false

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        if shouldThrowError {
            throw OCRServiceError.recognitionFailed
        }
        return mockResult ?? OCRResult(text: "", confidence: 0)
    }
}

final class MockAdvertisementService: AdvertisementServiceProtocol {
    private let purchaseService: PurchaseServiceProtocol
    private var executionCount = 0
    var recordOCRExecutionCalled = false

    init(purchaseService: PurchaseServiceProtocol) {
        self.purchaseService = purchaseService
    }

    var shouldShowAds: AnyPublisher<Bool, Never> {
        Just(!purchaseService.isPremium).eraseToAnyPublisher()
    }

    var shouldShowBanner: Bool {
        !purchaseService.isPremium
    }

    func shouldShowInterstitial() -> Bool {
        if executionCount >= 5 {
            executionCount = 0
            return !purchaseService.isPremium
        }
        return false
    }

    func recordOCRExecution() {
        executionCount += 1
        recordOCRExecutionCalled = true
    }

    func loadBannerAd() async throws {}
    func loadInterstitialAd() async throws {}
    func showInterstitialAd() async throws {}
}

final class MockSharingService: SharingServiceProtocol {
    var copyToClipboardCalled = false

    func copyClipboard(_ text: String) {
        copyToClipboardCalled = true
    }

    func shareViaAirDrop(_ text: String, from viewController: UIViewController) async {}
    func shareViaEmail(_ text: String, from viewController: UIViewController) async throws {}
    func share(_ text: String, from viewController: UIViewController, sourceView: UIView?) async {}
}
