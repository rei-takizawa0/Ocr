//
//  ContentView.swift
//  Ocr
//
//  Created by takizawa rei on 2025/10/27.
//

import SwiftUI

struct ContentView: View {
    let container = DependencyContainer.shared

    var body: some View {
        OCRView(viewModel: container.makeOCRViewModel())
    }
}

#Preview {
    ContentView()
}
