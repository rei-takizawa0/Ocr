//
//  SettingsViewModel.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import Combine

/// 設定画面のViewModel（SRP: 設定関連のプレゼンテーションロジックのみの責任）
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showRestoreSuccess: Bool = false

    // MARK: - Dependencies

    private var cancellables = Set<AnyCancellable>()

    // MARK: - URLs

    let xURL = URL(string: "https://example.com/terms")!
}
