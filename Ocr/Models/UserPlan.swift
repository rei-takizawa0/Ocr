//
//  UserPlan.swift
//  Ocr
//
//  Created by takizawa rei on 2025/11/13.
//

import Foundation

struct UserPlan: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let isShowAd: Bool
    let ocrLimit: Int
    let ocrUsedCount: Int

    /// DTOからFollowモデルを初期化
    init(dto: UserPlanDTO) {
        self.id = dto.id
        self.userId = dto.user_id
        self.isShowAd = dto.is_show_ad
        self.ocrLimit = dto.ocr_limit
        self.ocrUsedCount = dto.ocr_used_count
    }
    
    var remainingCount: Int {
        max(ocrLimit - ocrUsedCount, 0)
    }
}

struct UserPlanDTO: Codable {
    let id: UUID
    let user_id: UUID
    let is_show_ad: Bool
    let ocr_limit: Int
    let ocr_used_count: Int

    var remainingCount: Int {
        max(ocr_limit - ocr_used_count, 0)
    }
}
