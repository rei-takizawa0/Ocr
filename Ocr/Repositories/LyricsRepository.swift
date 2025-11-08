//
//  LyricsRepository.swift
//  Ocr
//
//  Created by takizawa rei on 2025/11/08.
//

import Foundation
import Supabase

final class LyricsRepository {
    private let client = SupabaseClientProvider.shared.client
    /// OCR文字列を保存
    func save(id:UUID,content: String) async throws {
        let lyric = Lyrics(
            id: id,
            content: content
        )
        
        let dto = lyric.toDTO()
        
        try await client
            .from("lyrics")
            .insert(dto)
            .execute()
    }
    
    /// 指定IDと一致するOCR文字列を全て削除
    func delete(id: UUID) async throws {
           try await client
               .from("lyrics")
               .delete()
               .eq("id", value: id.uuidString)
               .execute()
    }
}
