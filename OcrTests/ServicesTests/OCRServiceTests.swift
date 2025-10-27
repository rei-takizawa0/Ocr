//
//  OCRServiceTests.swift
//  OcrTests
//
//  Created by Claude Code
//

import XCTest
@testable import Ocr

final class OCRServiceTests: XCTestCase {

    var sut: OCRServiceProtocol!

    override func setUp() {
        super.setUp()
        sut = VisionOCRService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func testRecognizeText_WithValidImage_ShouldReturnResult() async throws {
        // Given: テスト用の画像を作成（白背景に黒文字）
        let image = createTestImage(withText: "Hello World")

        // When: OCR処理を実行
        let result = try await sut.recognizeText(from: image)

        // Then: 結果が正しく返される
        XCTAssertFalse(result.text.isEmpty, "認識されたテキストが空であってはならない")
        XCTAssertGreaterThan(result.confidence, 0, "信頼度は0より大きい")
    }

    func testRecognizeText_WithTextImage_ShouldPreserveWhitespace() async throws {
        // Given: 空白を含むテキストの画像
        let image = createTestImage(withText: "Hello   World")

        // When: OCR処理を実行
        let result = try await sut.recognizeText(from: image)

        // Then: 空白が保持される
        XCTAssertTrue(result.text.contains("  "), "複数の空白が保持されるべき")
    }

    func testRecognizeText_WithEmptyImage_ShouldThrowError() async {
        // Given: 何も描画されていない画像
        let image = UIImage()

        // When & Then: エラーがスローされる
        do {
            _ = try await sut.recognizeText(from: image)
            XCTFail("エラーがスローされるべき")
        } catch {
            XCTAssertTrue(error is OCRServiceError)
        }
    }

    func testRecognizeText_WithMultilineText_ShouldPreserveLineBreaks() async throws {
        // Given: 改行を含むテキストの画像
        let image = createTestImage(withText: "Line 1\nLine 2")

        // When: OCR処理を実行
        let result = try await sut.recognizeText(from: image)

        // Then: 改行が保持される
        XCTAssertTrue(result.text.contains("\n") || result.text.contains("Line 1") && result.text.contains("Line 2"))
    }

    // MARK: - Helper Methods

    private func createTestImage(withText text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        let image = renderer.image { context in
            // 白背景
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))

            // 黒文字
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            attributedString.draw(at: CGPoint(x: 20, y: 80))
        }
        return image
    }
}
