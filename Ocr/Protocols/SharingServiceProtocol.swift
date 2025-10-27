//
//  SharingServiceProtocol.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit

/// 共有タイプ
enum SharingType {
    case copy
    case airdrop
    case email
    case share // その他の共有オプション
}

/// 共有サービスのプロトコル（DIP: 抽象に依存）
protocol SharingServiceProtocol {
    /// テキストをクリップボードにコピー
    func copyToClipboard(_ text: String)

    /// AirDropでテキストを共有
    func shareViaAirDrop(_ text: String, from viewController: UIViewController) async

    /// メールでテキストを送信
    func shareViaEmail(_ text: String, from viewController: UIViewController) async throws

    /// 汎用的な共有シート表示
    func share(_ text: String, from viewController: UIViewController, sourceView: UIView?) async
}

/// 共有サービスで発生するエラー
enum SharingServiceError: Error {
    case mailNotAvailable
    case sharingFailed
}
