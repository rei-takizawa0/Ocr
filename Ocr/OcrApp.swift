//
//  OcrApp.swift
//  Ocr
//
//  Created by takizawa rei on 2025/10/27.
//

import SwiftUI
import SwiftData
import os.log

@main
struct OcrApp: App {
    let container: ModelContainer
    @StateObject private var purchaseService = StoreKitPurchaseService()

    private static let logger = Logger(subsystem: "com.ocr.app", category: "App")

    init() {
        // SwiftDataコンテナを初期化
        do {
            container = try ModelContainer(for: AdCounter.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(purchaseService)
                .task {
                    // 購入履歴をバックグラウンドで復元
                    do {
                        try await purchaseService.restorePurchases()
                        Self.logger.info("Purchase history restored successfully")
                    } catch {
                        Self.logger.error("Failed to restore purchases: \(error.localizedDescription)")
                    }
                }
        }
    }
}
