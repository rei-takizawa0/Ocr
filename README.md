# OCR App

Vision frameworkを使用した高精度OCRアプリケーション

## 機能

### OCR機能
- カメラまたはフォトライブラリから画像を選択してOCR処理
- 空白や改行を正確に保持したテキスト認識
- テキスト間の間隔を計算して、適切な空白数を挿入

### 共有機能
- 認識したテキストのコピー
- AirDrop、メールなどでの共有

### 広告機能
- 5回に1回インタースティシャル広告を表示
- 常時ヘッダーにバナー広告を表示
- 課金済みユーザーには広告を一切表示しない

### 設定画面
- プレミアム購入（一度の課金で広告を削除）
- 購入履歴の復元機能
- 利用規約、プライバシーポリシー、サポートへのリンク
- アプリバージョン表示

## アーキテクチャ

このプロジェクトは **SOLID原則** と **テスト駆動開発（TDD）** に基づいて設計されています。

### SOLID原則の適用

#### 1. Single Responsibility Principle (SRP)
各クラスは単一の責任を持ちます：
- `VisionOCRService`: OCR処理のみを担当
- `AdvertisementService`: 広告表示ロジックのみを担当
- `StoreKitPurchaseService`: 課金処理のみを担当
- `SharingService`: テキスト共有のみを担当
- `OCRViewModel`: プレゼンテーションロジックのみを担当

#### 2. Open/Closed Principle (OCP)
プロトコルを使用することで、拡張に対して開き、変更に対して閉じています：
- 新しいOCRエンジンを追加する場合、`OCRServiceProtocol`を実装するだけ
- 新しい広告SDKに変更する場合、`AdvertisementServiceProtocol`を実装するだけ

#### 3. Liskov Substitution Principle (LSP)
全てのサービスはプロトコルに準拠し、実装を置き換え可能です：
- テスト時にはモック実装を使用
- 本番環境では実際の実装を使用

#### 4. Interface Segregation Principle (ISP)
各プロトコルは必要最小限のメソッドのみを定義：
- `OCRServiceProtocol`: `recognizeText`のみ
- `SharingServiceProtocol`: 共有関連メソッドのみ

#### 5. Dependency Inversion Principle (DIP)
高レベルモジュールは抽象（プロトコル）に依存：
- `OCRViewModel`は具体的なサービスではなく、プロトコルに依存
- `DependencyContainer`で依存関係を一元管理

## プロジェクト構造

```
Ocr/
├── Models/
│   └── OCRResult.swift              # OCR結果のモデル
├── Protocols/
│   ├── OCRServiceProtocol.swift
│   ├── AdvertisementServiceProtocol.swift
│   ├── PurchaseServiceProtocol.swift
│   └── SharingServiceProtocol.swift
├── Services/
│   ├── VisionOCRService.swift       # Vision frameworkを使用したOCR実装
│   ├── AdvertisementService.swift
│   ├── StoreKitPurchaseService.swift
│   └── SharingService.swift
├── ViewModels/
│   ├── OCRViewModel.swift           # OCR画面のViewModel
│   └── SettingsViewModel.swift      # 設定画面のViewModel
├── Views/
│   ├── OCRView.swift                # メインのOCR画面
│   ├── SettingsView.swift           # 設定画面
│   ├── BannerAdView.swift           # バナー広告表示
│   └── InterstitialAdView.swift    # インタースティシャル広告表示
└── DI/
    └── DependencyContainer.swift    # 依存性注入コンテナ

OcrTests/
├── ServicesTests/
│   ├── OCRServiceTests.swift
│   ├── AdvertisementServiceTests.swift
│   ├── PurchaseServiceTests.swift
│   └── SharingServiceTests.swift
├── ViewModelsTests/
│   ├── OCRViewModelTests.swift
│   └── SettingsViewModelTests.swift
└── Mocks/
    └── MockPurchaseService.swift
```

## テスト駆動開発（TDD）

ケント・ベックのTDDアプローチに従い、以下の手順で開発しました：

1. **Red**: テストを書く（失敗する）
2. **Green**: テストをパスする最小限のコードを書く
3. **Refactor**: コードをリファクタリング

### テストカバレッジ

- OCRServiceのテスト: 空白保持、改行保持、エラーハンドリング
- AdvertisementServiceのテスト: 広告表示ロジック、課金状態による制御
- PurchaseServiceのテスト: 課金処理、購入履歴の復元
- SharingServiceのテスト: クリップボードコピー、特殊文字の保持
- OCRViewModelのテスト: OCR処理のビジネスロジック、状態管理
- SettingsViewModelのテスト: 課金処理、エラーハンドリング

## 技術スタック

- **UI**: SwiftUI
- **OCR**: Vision framework
- **課金**: StoreKit 2
- **広告**: Google AdMob（統合予定）
- **アーキテクチャ**: MVVM + Protocol-Oriented Programming
- **テスト**: XCTest

## セットアップ

### 必要な設定

1. **Info.plist**に以下を追加:
```xml
<key>NSCameraUsageDescription</key>
<string>写真を撮影してテキストを認識するためにカメラへのアクセスが必要です。</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>フォトライブラリから画像を選択してテキストを認識するためにアクセスが必要です。</string>
```

2. **StoreKit Configuration**を作成:
   - Product ID: `com.ocr.premium.removeads`
   - Type: Non-Consumable

3. **AdMob統合**（今後）:
   - Google AdMob SDKをインストール
   - `BannerAdView`と`InterstitialAdView`を実装

## テストの実行

```bash
# すべてのテストを実行
xcodebuild test -scheme Ocr -destination 'platform=iOS Simulator,name=iPhone 15'

# または Xcode で
# Cmd + U
```

## ビルドと実行

```bash
# ビルド
xcodebuild -scheme Ocr -destination 'platform=iOS Simulator,name=iPhone 15'

# または Xcode で
# Cmd + R
```

## 今後の改善点

1. **AdMob統合**: 実際の広告SDKを統合
2. **パフォーマンス最適化**: 大きな画像の処理速度向上
3. **オフライン対応**: ネットワークなしでも動作
4. **多言語対応**: 日本語以外の言語をサポート
5. **バッチ処理**: 複数画像の一括処理

## ライセンス

MIT License

## 作成者

Created with Claude Code
# Ocr
