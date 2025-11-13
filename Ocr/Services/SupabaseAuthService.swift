//
//  SupabaseAuthService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import Combine
import Supabase

@MainActor
final class SupabaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private let client: SupabaseClient

    init() {
        self.client = SupabaseClientProvider.shared.client
        Task {
            await checkCurrentSession()
        }
    }

    // MARK: - Session Management

    func checkCurrentSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        errorMessage = nil

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            isAuthenticated = true
        } catch {
            errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
            isAuthenticated = false
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        errorMessage = nil

        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "ログアウトに失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async {
        errorMessage = nil

        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = "パスワードリセットに失敗しました: \(error.localizedDescription)"
        }
    }
}
