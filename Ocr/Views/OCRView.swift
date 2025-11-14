//
//  OCRView.swift
//  Ocr
//
//  Created by Claude Code
//

import SwiftUI
import PhotosUI
import SwiftData

struct OCRView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseService: StoreKitPurchaseService
    @EnvironmentObject private var authService: SupabaseAuthService

    @StateObject private var viewModel: OCRViewModel

    init(purchaseService: StoreKitPurchaseService, modelContext: ModelContext, authService: SupabaseAuthService) {
        let adRepository = AdCounterRepository(modelContext: modelContext)
        let lyricIDRepository = LyricIDRepository(modelContext: modelContext)
        let advertisementService = AdvertisementService(purchaseService: purchaseService)
        let userPlanRepository = UserPlanRepository()

        _viewModel = StateObject(wrappedValue: OCRViewModel(
            ocrService: VisionOCRService(),
            advertisementService: advertisementService,
            sharingService: SharingService(),
            adRepository: adRepository,
            lyricIDRepository: lyricIDRepository,
            userPlanRepository: userPlanRepository,
            authService: authService
        ))
    }

    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var showingShareSheet = false
    @State private var showingSettings = false
    @State private var showingURLManagement = false

    // プレミアムOCR機能
    @State private var isPremiumOCREnabled = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // バナー広告エリア（課金済みなら非表示）
                if viewModel.shouldShowBanner {
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                }

                ScrollView {
                    VStack(spacing: 20) {
                        // プレミアムOCRトグル
                        premiumOCRToggle

                        // 画像選択ボタン
                        imageSelectionButtons

                        // 選択された画像
                        if let image = selectedImage {
                                imagePreview(image)
                        }

                        // 認識されたテキスト
                        if !viewModel.recognizedText.isEmpty {
                            recognizedTextSection
                        }

                        // エラーメッセージ
                        if let error = viewModel.errorMessage {
                            errorView(error)
                        }

                        // 処理中インジケータ
                        if viewModel.isProcessing {
                            ProgressView("テキストを認識中...")
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingURLManagement = true
                    }) {
                        Image(systemName: "link.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary) { image in
                    processImage(image)
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera) { image in
                    processImage(image)
                }
            }
            .fullScreenCover(isPresented: $viewModel.shouldShowInterstitialAd) {
                InterstitialAdView {
                    viewModel.dismissInterstitialAd()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: SettingsViewModel(purchaseService: purchaseService))
            }
            .sheet(isPresented: $showingURLManagement) {
                LyricURLView(modelContext: modelContext)
            }
        }
    }

    // MARK: - View Components

    private var premiumOCRToggle: some View {
        VStack(spacing: 12) {
            Button(action: {
                if !authService.isAuthenticated {
                    // ログインが必要な場合
                    viewModel.errorMessage = "高機能OCRを使用するにはログインが必要です"
                    return
                }

                if viewModel.premiumOCRRemainingCount > 0 {
                    isPremiumOCREnabled.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isPremiumOCREnabled ? "star.fill" : "star")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isPremiumOCREnabled ? "高機能OCR有効" : "高機能OCR")
                            .font(.headline)

                        if authService.isAuthenticated {
                            Text("残り\(viewModel.premiumOCRRemainingCount)回")
                                .font(.caption)
                                .foregroundColor(isPremiumOCREnabled ? .white.opacity(0.9) : .primary.opacity(0.7))
                        } else {
                            Text("ログインが必要です")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if isPremiumOCREnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isPremiumOCREnabled
                            ? [Color.orange, Color.yellow]
                            : [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(isPremiumOCREnabled ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPremiumOCREnabled ? Color.orange : Color.clear, lineWidth: 2)
                )
            }
            .disabled(!authService.isAuthenticated || viewModel.premiumOCRRemainingCount == 0)
            .opacity(!authService.isAuthenticated || viewModel.premiumOCRRemainingCount == 0 ? 0.5 : 1.0)

            if isPremiumOCREnabled {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("次の撮影で高機能OCRが適用されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .task {
            // ビュー表示時にプラン情報を取得
            if authService.isAuthenticated {
                await viewModel.fetchUserPlan()
            }
        }
    }

    private var imageSelectionButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                isShowingCamera = true
            }) {
                    Label("カメラ", systemImage: "camera")
                .frame(maxWidth: .infinity)
                .padding()
                    .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button(action: {
                isShowingImagePicker = true
            }) {
                    Label("ライブラリ", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
                .padding()
                    .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }

    private func imagePreview(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 300)
            .cornerRadius(10)
            .shadow(radius: 5)
    }

    private var recognizedTextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("認識されたテキスト")
                .font(.headline)

            Text(viewModel.recognizedText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            // 共有ボタン
            HStack(spacing: 15) {
                Button(action: {
                    viewModel.copyText()
                }) {
                    Label("コピー", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    showingShareSheet = true
                }) {
                    Label("共有", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(text: viewModel.recognizedText)
        }
    }

    private func errorView(_ message: String) -> some View {
        Text(message)
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
    }

    // MARK: - Helper Methods

    private func processImage(_ image: UIImage) {
        Task {
            let usePremiumOCR = isPremiumOCREnabled

            // プレミアムOCRを実行後はフラグをオフにする
            if isPremiumOCREnabled {
                isPremiumOCREnabled = false
            }

            await viewModel.recognizeText(from: image, usePremiumOCR: usePremiumOCR)
        }
    }
}


// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
