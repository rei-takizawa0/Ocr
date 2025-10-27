//
//  PurchaseServiceProtocol.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import Combine

/// 購入可能な商品
struct PurchaseProduct: Identifiable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let price: String
}

/// 課金サービスのプロトコル（DIP: 抽象に依存）
protocol PurchaseServiceProtocol {
    /// プレミアム機能が有効かどうか
    var isPremium: Bool { get }

    /// プレミアム状態の変更を通知するPublisher
    var isPremiumPublisher: AnyPublisher<Bool, Never> { get }

    /// 利用可能な商品を取得
    func fetchProducts() async throws -> [PurchaseProduct]

    /// 商品を購入
    func purchase(productId: String) async throws

    /// 購入履歴を復元
    func restorePurchases() async throws
}

/// 課金サービスで発生するエラー
enum PurchaseServiceError: Error, Equatable {
    case productNotFound
    case purchaseFailed
    case userCancelled
    case restoreFailed
}
