//
//  InterstitialAdView.swift
//  Ocr
//
//  Created by Claude Code
//

import SwiftUI

/// インタースティシャル広告表示用のビュー
struct InterstitialAdView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 10) {
                    Text("広告")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("(AdMob統合後に実際の広告を表示)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)

                Spacer()

                Button(action: onDismiss) {
                    Text("閉じる")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    InterstitialAdView {
        print("Ad dismissed")
    }
}
