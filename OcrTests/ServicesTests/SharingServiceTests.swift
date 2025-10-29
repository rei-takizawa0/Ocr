//
//  SharingServiceTests.swift
//  OcrTests
//
//  Created by Claude Code
//

import XCTest
import UIKit
@testable import Ocr

final class SharingServiceTests: XCTestCase {

    var sut: SharingService!

    override func setUp() {
        super.setUp()
        sut = SharingService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func testCopyClipboard_WithText_ShouldCopyTextToClipboard() {
        // Given: テキスト
        let text = "Test text for copying"

        // When: クリップボードにコピー
        sut.copyClipboard(text)

        // Then: クリップボードにテキストが保存される
        let copiedText = UIPasteboard.general.string
        XCTAssertEqual(copiedText, text)
    }

    func testCopyClipboard_WithEmptyText_ShouldCopyEmptyString() {
        // Given: 空のテキスト
        let text = ""

        // When: クリップボードにコピー
        sut.copyClipboard(text)

        // Then: クリップボードに空文字列が保存される
        let copiedText = UIPasteboard.general.string
        XCTAssertEqual(copiedText, text)
    }

    func testCopyClipboard_WithWhitespace_ShouldPreserveWhitespace() {
        // Given: 空白を含むテキスト
        let text = "Line 1\n  Line 2\t\tLine 3"

        // When: クリップボードにコピー
        sut.copyClipboard(text)

        // Then: 空白が保持される
        let copiedText = UIPasteboard.general.string
        XCTAssertEqual(copiedText, text)
        XCTAssertTrue(copiedText?.contains("\n") ?? false)
        XCTAssertTrue(copiedText?.contains("\t") ?? false)
    }

    func testCopyClipboard_WithSpecialCharacters_ShouldCopyCorrectly() {
        // Given: 特殊文字を含むテキスト
        let text = "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"

        // When: クリップボードにコピー
        sut.copyClipboard(text)

        // Then: 特殊文字が正しくコピーされる
        let copiedText = UIPasteboard.general.string
        XCTAssertEqual(copiedText, text)
    }

    func testCopyClipboard_WithUnicodeCharacters_ShouldCopyCorrectly() {
        // Given: Unicode文字を含むテキスト
        let text = "日本語のテキスト 😀 🎉"

        // When: クリップボードにコピー
        sut.copyClipboard(text)

        // Then: Unicode文字が正しくコピーされる
        let copiedText = UIPasteboard.general.string
        XCTAssertEqual(copiedText, text)
    }

    // Note: UIViewController依存のメソッドは統合テストまたはUIテストで検証
    // shareViaAirDrop, shareViaEmail, shareメソッドは実際のUIに依存するため
    // ここでは単体テストではなく、モックを使用したテストを行う
}
