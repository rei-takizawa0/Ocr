import Foundation
import SwiftData

@MainActor
final class LyricIDRepository {

    // MARK: - Properties
    private let modelContext: ModelContext

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// UUID を取得または作成
    func fetchID() throws -> LyricID {
        let descriptor = FetchDescriptor<LyricID>()
        let results = try modelContext.fetch(descriptor)

        if let existing = results.first {
            return existing
        } else {
            let newID = LyricID()
            modelContext.insert(newID)
            try modelContext.save()
            return newID
        }
    }

    /// UUID を更新（必要な場合）
    func updateID(_ newID: UUID) throws {
        let entity = try fetchID()
        entity.id = newID
        try modelContext.save()
    }

    /// 現在の UUID を取得
    func getCurrentID() throws -> UUID {
        return try fetchID().id
    }
}
