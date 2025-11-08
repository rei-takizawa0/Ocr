//
//  LyricURLViewModel.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import Combine
import UIKit

/// 歌詞URL管理のViewModel
@MainActor
final class LyricURLViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentURL: String = ""
    @Published var isLoading: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let sharingService: SharingService
    private let baseURL: String = "https://your-domain.com"

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        sharingService: SharingService = SharingService(),
        baseURL: String? = nil
    ) {
        self.modelContext = modelContext
        self.sharingService = sharingService
    }

    // MARK: - Public Methods

    /// 現在のURLを読み込み
    func loadCurrentURL() {
        do {
            let lyricIDRepo = LyricIDRepository(modelContext: modelContext)
            let currentID = try lyricIDRepo.getCurrentID()
            currentURL = "\(baseURL)/\(currentID.uuidString.lowercased())"
        } catch {
            errorMessage = "URLの取得に失敗しました"
            showErrorAlert = true
        }
    }

    /// URLをコピー
    func copyURL() {
        sharingService.copyClipboard(currentURL)
    }

    /// URLを共有
    func shareURL(from viewController: UIViewController) {
        Task {
            await sharingService.share(currentURL, from: viewController, sourceView: nil)
        }
    }

    /// IDを再発番
    func regenerateID() {
        isLoading = true

        Task { @MainActor in
            do {
                // 現在のIDを取得
                let lyricIDRepo = LyricIDRepository(modelContext: modelContext)
                let currentID = try lyricIDRepo.getCurrentID()

                // 紐づく歌詞データを削除
                let lyricsRepo = LyricsRepository()
                try await lyricsRepo.delete(id: currentID)

                // 新しいIDを生成
                let newID = UUID()
                try lyricIDRepo.updateID(newID)

                // URLを更新（メインスレッドで確実に実行）
                currentURL = "\(baseURL)/\(newID.uuidString.lowercased())"

            } catch {
                errorMessage = "ID再発番に失敗しました"
                showErrorAlert = true
            }

            isLoading = false
        }
    }
}
