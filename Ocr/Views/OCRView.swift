//
//  OCRView.swift
//  Ocr
//
//  Created by Claude Code
//

import SwiftUI
import PhotosUI

struct OCRView: View {
    @StateObject var viewModel: OCRViewModel
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var showingShareSheet = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // バナー広告エリア
                if viewModel.shouldShowBanner {
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                }

                ScrollView {
                    VStack(spacing: 20) {
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
            .navigationTitle("OCR")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary) { image in
                    processImage(image)
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera) { image in
                    processImage(image)
                }
            }
            .fullScreenCover(isPresented: $viewModel.shouldShowInterstitialAd) {
                InterstitialAdView {
                    viewModel.dismissInterstitialAd()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: DependencyContainer.shared.makeSettingsViewModel())
            }
        }
    }

    // MARK: - View Components

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
            await viewModel.recognizeText(from: image)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
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

#Preview {
    let ocrService = VisionOCRService()
    let purchaseService = StoreKitPurchaseService()
    let adService = AdvertisementService(purchaseService: purchaseService)
    let sharingService = SharingService()
    let viewModel = OCRViewModel(
        ocrService: ocrService,
        advertisementService: adService,
        sharingService: sharingService
    )

    return OCRView(viewModel: viewModel)
}
