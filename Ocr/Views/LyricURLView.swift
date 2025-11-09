//
//  LyricURLView.swift
//  Ocr
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

/// 歌詞URL表示・共有View
struct LyricURLView: View {

    // MARK: - Properties

    @StateObject private var viewModel: LyricURLViewModel
    @State private var viewController: UIViewController?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: LyricURLViewModel(modelContext: modelContext))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                descriptionSection
                urlDisplaySection
                actionButtonsSection

                Spacer()
            }
            .padding()
            .navigationTitle("URL管理")
            .background(ViewControllerResolver { self.viewController = $0 })
            .overlay(alignment: .top) {
                if viewModel.showSuccessMessage {
                    successToast
                }
            }
            .alert("エラー", isPresented: $viewModel.showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.loadCurrentURL()
            }
        }
    }

    // MARK: - View Components

    private var descriptionSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            VStack(spacing: 2) {
                Text("読み込んだテキストを一覧で表示するURLです。")
                Text("URLをコピーしてPC等でアクセスしてください。")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var urlDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("現在のURL", systemImage: "globe")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(viewModel.currentURL)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // URLをコピー
            Button {
                viewModel.copyURL()
            } label: {
                Label("URLをコピー", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            // URLを共有
            Button {
                if let vc = viewController {
                    viewModel.shareURL(from: vc)
                }
            } label: {
                Label("URLを共有", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Divider()
                .padding(.vertical, 8)

            // 新しくIDを発番
            Button {
                viewModel.regenerateID()
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Label("ページを変更", systemImage: "arrow.clockwise")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)

            Text("※ ページを変更すると、以前のデータは削除されます")
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
    }

    private var successToast: some View {
        Text(viewModel.successMessage)
            .font(.body)
            .foregroundColor(.white)
            .padding()
            .background(
                Capsule()
                    .fill(Color.green)
                    .shadow(radius: 4)
            )
            .padding()
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: viewModel.showSuccessMessage)
    }
}

// MARK: - ViewControllerResolver

/// UIViewControllerを取得するためのヘルパー
private struct ViewControllerResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            self.onResolve(viewController)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
