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

                // プレミアムステータスセクション
                premiumStatusSection

                // 課金セクション
                if !viewModel.isPremium {
                    purchaseSection
                }

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
            .task {
                await viewModel.fetchProducts()
            }
            .alert("復元完了", isPresented: $viewModel.showRestoreSuccess) {
                Button("OK") {}
            } message: {
                Text("購入履歴を復元しました。")
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
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

    private var premiumStatusSection: some View {
        Section {
            HStack {
                Label("プレミアム", systemImage: viewModel.isPremium ? "crown.fill" : "crown")
                    .foregroundColor(viewModel.isPremium ? .orange : .gray)

                Spacer()

                Text(viewModel.isPremium ? "有効" : "無効")
                    .foregroundColor(viewModel.isPremium ? .green : .gray)
                    .font(.subheadline)
            }
        } header: {
            Text("ステータス")
        } footer: {
            if viewModel.isPremium {
                Text("プレミアム機能をご利用いただけます。すべての広告が非表示になります。")
            }
        }
    }

    private var purchaseSection: some View {
        Section {
            // 商品リスト
            ForEach(viewModel.availableProducts) { product in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            Task {
                                await viewModel.purchase(productId: product.id)
                            }
                        }) {
                            Text(product.price)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding(.vertical, 4)
            }

            // 復元ボタン
            Button(action: {
                Task {
                    await viewModel.restorePurchases()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("購入履歴を復元")
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
            .disabled(viewModel.isLoading)
        } header: {
            Text("プレミアム購入")
        } footer: {
            Text("一度購入すると、すべての広告が非表示になります。他のデバイスで購入済みの場合は「購入履歴を復元」をタップしてください。")
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

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("読み込み中...")
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(15)
        }
    }
}

#Preview {
    let purchaseService = StoreKitPurchaseService()
    let viewModel = SettingsViewModel(purchaseService: purchaseService)
    let authService = SupabaseAuthService()

    return SettingsView(viewModel: viewModel)
        .environmentObject(authService)
}
