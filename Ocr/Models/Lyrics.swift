//
//  Lyrics.swift
//  Ocr
//
//  Created by takizawa rei on 2025/11/08.
//
import Foundation

// MARK: - モデル

/// OCRデータが格納されるモデル
struct Lyrics: Identifiable, Codable {
    let id: UUID
    let content: String
    let createdAt: Date

    init(id: UUID, content: String) {
        self.id = id
        self.content = content
        self.createdAt = Date()
    }

    /// DTOからFollowモデルを初期化
    init(dto: LyricsDTO) {
        self.id = dto.id
        self.content = dto.content
        self.createdAt = dto.created_at
    }

    /// DTOに変換
    func toDTO() -> LyricsDTO {
        LyricsDTO(
            id: id,
            content: content,
            created_at: createdAt
        )
    }
}

/// Supabaseとのデータ転送用のDTO
struct LyricsDTO: Codable {
    let id: UUID
    let content: String
    let created_at: Date
}
