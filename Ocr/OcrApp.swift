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
    @StateObject private var authService = SupabaseAuthService()

    private static let logger = Logger(subsystem: "com.ocr.app", category: "App")

    init() {
        // SwiftDataコンテナを初期化
        do {
            container = try ModelContainer(for: AdCounter.self, LyricID.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(authService)
        }
    }
}
