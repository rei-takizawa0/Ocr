//
//  AdCounterRepository.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// 広告カウンターの永続化を管理するリポジトリ
@MainActor
final class AdCounterRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 広告カウンターを取得または作成
    func fetchOrCreateCounter() throws -> AdCounter {
        let descriptor = FetchDescriptor<AdCounter>()
        let counters = try modelContext.fetch(descriptor)

        if let existingCounter = counters.first {
            return existingCounter
        } else {
            let newCounter = AdCounter(count: 0)
            modelContext.insert(newCounter)
            try modelContext.save()
            return newCounter
        }
    }

    /// 広告カウンターをインクリメント
    func incrementCounter() throws {
        let counter = try fetchOrCreateCounter()
        counter.count += 1
        try modelContext.save()
    }

    /// 広告カウンターを1にリセット
    func resetCounter() throws {
        let counter = try fetchOrCreateCounter()
        counter.count = 1
        try modelContext.save()
    }

    /// 現在のカウントを取得
    func getCurrentCount() throws -> Int {
        let counter = try fetchOrCreateCounter()
        return counter.count
    }
}
