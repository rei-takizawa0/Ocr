//
//  PremiumOCRService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit

/// プレミアムOCRサービス
final class PremiumOCRService {

    private let apiURL = URL(string: "https://ocr-backend.rei971222.workers.dev/api/ocr")!

    // デバッグ用：モックモードを有効化（サーバー実装完了後はfalseに）
    private let useMockResponse = false

    // MARK: - Public Methods

    /// 高機能OCRでテキストを認識
    func recognizeText(from image: UIImage, userId: UUID) async throws -> OCRResult {
        print("🔵 [PremiumOCR] 開始 - userId: \(userId.uuidString)")

               // モックモード（デバッグ用）
        if useMockResponse {
            print("🟡 [PremiumOCR] モックモード: テストデータを返します")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
            return OCRResult(
                text: "【モックデータ】高機能OCRで認識されたテキストです。\nサーバー実装後は実際のOCR結果が返されます。",
                confidence: 1.0,
                processedImage: image
            )
        }
        
        // 画像をBase64エンコード
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("🔴 [PremiumOCR] エラー: 画像のエンコードに失敗")
            throw OCRServiceError.invalidImage
        }

        print("🔵 [PremiumOCR] 画像サイズ: \(imageData.count) bytes")

        let base64String = imageData.base64EncodedString()
        print("🔵 [PremiumOCR] Base64エンコード完了 - 長さ: \(base64String.count)")

        // リクエストボディを作成
        let requestBody: [String: String] = [
            "userId": userId.uuidString,
            "imageBase64": base64String
        ]

        // URLRequestを作成
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.timeoutInterval = 60 // タイムアウト60秒

        print("🔵 [PremiumOCR] リクエスト送信: \(apiURL.absoluteString)")
        print("🔵 [PremiumOCR] リクエストボディサイズ: \(request.httpBody?.count ?? 0) bytes")

        // APIリクエストを送信
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            print("🔵 [PremiumOCR] レスポンス受信 - サイズ: \(data.count) bytes")

            // レスポンスをチェック
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔴 [PremiumOCR] エラー: HTTPレスポンスではありません")
                throw OCRServiceError.recognitionFailed
            }

            print("🔵 [PremiumOCR] HTTPステータスコード: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                if let responseText = String(data: data, encoding: .utf8) {
                    print("🔴 [PremiumOCR] エラーレスポンス: \(responseText)")
                }
                print("🔴 [PremiumOCR] エラー: ステータスコード \(httpResponse.statusCode)")
                throw OCRServiceError.recognitionFailed
            }

            // レスポンスをパース
            let responseText = try parseResponse(data)
            print("🟢 [PremiumOCR] 認識成功 - テキスト長: \(responseText.count)")
            print("🔵 [PremiumOCR] 認識テキスト: \(responseText.prefix(100))...")

            guard !responseText.isEmpty else {
                print("🔴 [PremiumOCR] エラー: 認識されたテキストが空です")
                throw OCRServiceError.noTextFound
            }

            // OCRResultを返す（高機能OCRなので信頼度は1.0）
            return OCRResult(
                text: responseText,
                confidence: 1.0,
                processedImage: image
            )
        } catch let error as OCRServiceError {
            print("🔴 [PremiumOCR] OCRServiceError: \(error)")
            throw error
        } catch {
            print("🔴 [PremiumOCR] ネットワークエラー: \(error.localizedDescription)")
            throw OCRServiceError.recognitionFailed
        }
    }

    // MARK: - Private Methods

    private func parseResponse(_ data: Data) throws -> String {
        print("🔵 [PremiumOCR] レスポンスパース開始")

        // レスポンスが単純な文字列の場合
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            print("🔵 [PremiumOCR] UTF-8テキスト変換成功")
            print("🔵 [PremiumOCR] レスポンステキスト: \(text.prefix(200))")

            // JSONレスポンスの場合も考慮
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔵 [PremiumOCR] JSONパース成功")
                print("🔵 [PremiumOCR] JSONキー: \(json.keys)")

                if let resultText = json["text"] as? String {
                    print("🟢 [PremiumOCR] JSONから\"text\"フィールド取得成功")
                    return resultText
                } else {
                    print("🟡 [PremiumOCR] JSONに\"text\"フィールドがありません")
                }
            } else {
                print("🔵 [PremiumOCR] JSONではない、プレーンテキストとして処理")
            }

            // プレーンテキストの場合
            return text
        }

        print("🔴 [PremiumOCR] レスポンスパースに失敗")
        throw OCRServiceError.recognitionFailed
    }
}
