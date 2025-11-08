//
//  SupabaseClient.swift
//  Ocr
//
//  Created by takizawa rei on 2025/11/08.
//

import Foundation
import Supabase

final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()
    let client: SupabaseClient

    private init() {
        let domain = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""

        let fullUrlString = "https://" + domain

        guard let url = URL(string: fullUrlString) else {
            fatalError("SUPABASE_URL が無効です")
        }

        guard !anonKey.isEmpty else {
            fatalError("SUPABASE_ANON_KEY が設定されていません")
        }

        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
