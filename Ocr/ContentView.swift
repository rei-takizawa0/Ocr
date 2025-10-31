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
    @EnvironmentObject private var purchaseService: StoreKitPurchaseService

    var body: some View {
        OCRView(purchaseService: purchaseService, modelContext: modelContext)
    }
}

#Preview {
    ContentView()
}
