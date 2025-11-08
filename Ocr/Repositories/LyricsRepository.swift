//
//  LyricsRepository.swift
//  Ocr
//
//  Created by takizawa rei on 2025/11/08.
//

import Foundation

final class LyricsRepository {
    private let client = SupabaseClientProvider.shared.client
    /// OCR文字列を保存
    func save(id:UUID,content: String) async throws {
        let lyric = Lyric(
            id: id,
            content: content,
            created_at: Date()
        )
        
        let dto = lyric.toDTO()
        
        try await client
            .from("lyrics")
            .insert(dto)
            .execute()
    }
}
