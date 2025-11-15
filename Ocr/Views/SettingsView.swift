//
//  SettingsView.swift
//  Ocr
//
//  Created by Claude Code
//

import SwiftUI
internal import Auth

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) var dismiss

    @State private var isShowLogin = false

    var body: some View {
        NavigationView {
            List {
                // アカウントセクション
                accountSection

                // リンクセクション
                linksSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowLogin) {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }

    // MARK: - View Components

    private var accountSection: some View {
        Section {
            if authService.isAuthenticated {
                // ログイン中のユーザー情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ログイン中")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let email = authService.currentUser?.email {
                                Text(email)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)

                // ログアウトボタン
                Button(action: {
                    Task {
                        await authService.signOut()
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("ログアウト")
                    }
                    .foregroundColor(.red)
                }
            } else {
                // ログインしていない状態
                HStack {
                    
                    Button(action: {
                        isShowLogin = true
                    }) {
                        HStack {
                           
                                Text("ログイン")
                                    .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("アカウント")
        } footer: {
        }
    }

    private var linksSection: some View {
        Section {
            Link(destination: viewModel.xURL) {
                HStack {
                    Label("問い合わせアカウント", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.gray)
                }
            }
        } header: {
            Text("リンク")
        }
    }
}

#Preview {
    let viewModel = SettingsViewModel()
    let authService = SupabaseAuthService()

    return SettingsView(viewModel: viewModel)
        .environmentObject(authService)
}
