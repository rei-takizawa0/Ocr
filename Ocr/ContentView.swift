//
//  ContentView.swift
//  Ocr
//
//  Created by takizawa rei on 2025/10/27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: SupabaseAuthService

    var body: some View {
        OCRView(modelContext: modelContext, authService: authService)
    }
}

#Preview {
    ContentView()
}
