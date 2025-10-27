//
//  BannerAdView.swift
//  Ocr
//
//  Created by Claude Code
//

import SwiftUI

/// バナー広告表示用のビュー
struct BannerAdView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)

            VStack {
                Text("広告エリア")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("(AdMob統合後に実際の広告を表示)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    BannerAdView()
        .frame(height: 50)
}
