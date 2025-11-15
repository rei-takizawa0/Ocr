//
//  UserPlanRepository.swift
//  Ocr
//
//  Created by takizawa rei on 2025/11/14.
//

import Foundation
import Supabase

final class UserPlanRepository {
    private let client = SupabaseClientProvider.shared.client
    /// 現在のプランを取得
    func getPlan(userId:UUID) async throws -> UserPlan {
        let plan:UserPlanDTO = try await client
            .from("user_plans")
            .select("id, user_id, is_show_ad, ocr_limit, ocr_used_count")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        return UserPlan(dto: plan)
    }
    
    /// OCR使用回数を更新
    func incrementOCRCount(userId: UUID, newOcrCount: Int) async throws {
        try await client
            .from("user_plans")
            .update(["ocr_used_count": newOcrCount])
            .eq("user_id", value: userId)
            .execute()
    }
}
