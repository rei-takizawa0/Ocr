//
//  LoginView.swift
//  Ocr
//
//  Created by Claude Code
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingPasswordReset = false

    // 新規登録用のWebサイトURL（実際のURLに変更してください）
    private let signUpURL = URL(string: "https://your-website.com/signup")!

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // ロゴ・タイトル
                    VStack(spacing: 10) {

                        Text("Poe")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("ログイン")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // ログインフォーム
                    VStack(spacing: 20) {
                        // メールアドレス
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextField("example@email.com", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }

                        // パスワード
                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            SecureField("パスワード", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.password)
                        }

                        // エラーメッセージ
                        if let error = authService.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }

                        // ログイン/登録ボタン
                        Button(action: {
                            handleAuthentication()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("ログイン")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)

                        // パスワードリセット
                        Button(action: {
                            showingPasswordReset = true
                        }) {
                            Text("パスワードを忘れた場合")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }

                        // 新規登録リンク
                        Divider()
                            .padding(.vertical, 10)

                        VStack(spacing: 8) {
                            Text("アカウントをお持ちでないですか？")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Link(destination: signUpURL) {
                                HStack {
                                    Text("Webで新規登録")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetView()
                    .environmentObject(authService)
            }
        }
    }

    // MARK: - Helper Methods

    private func handleAuthentication() {
        isLoading = true

        Task {
            await authService.signIn(email: email, password: password)
            isLoading = false

            // ログイン成功時に画面を閉じる
            if authService.isAuthenticated {
                dismiss()
            }
        }
    }
}

// MARK: - Password Reset View

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: SupabaseAuthService

    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("パスワードリセット")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                Text("登録されているメールアドレスを入力してください。パスワードリセット用のリンクを送信します。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("メールアドレス")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("example@email.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal, 30)

                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                }

                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("リセットリンクを送信しました")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                }

                Button(action: {
                    handlePasswordReset()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("送信")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || email.isEmpty)
                .padding(.horizontal, 30)

                Spacer()
            }
            .navigationTitle("パスワードリセット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func handlePasswordReset() {
        isLoading = true
        authService.errorMessage = nil

        Task {
            await authService.resetPassword(email: email)
            isLoading = false

            if authService.errorMessage == nil {
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SupabaseAuthService())
}
