# テスト計画: #36 build()内副作用除去 + #37 エラーハンドリング統一

## テスト対象

### #37 エラーハンドリング

| テスト | 内容 | 種別 |
|--------|------|------|
| カスタム例外クラス | AppException, NotFoundError等のインスタンス化・toString・継承関係 | Unit |
| Firebase例外変換 | convertFirebaseException()の各パターン | Unit |
| SettingsPersistence | エラー時のログ出力確認（既存テストがあれば拡張） | Unit |
| AuthProvider dispose | StreamSubscriptionのcancel確認 | Unit |

### #36 パフォーマンス

| テスト | 内容 | 種別 |
|--------|------|------|
| ListEdit | パラメータ受け取り方式での動作確認 | Widget |
| AdBanner | Completerパターンでの初期化待機 | Unit |

## 既存テストへの影響

変更によりテストが壊れる可能性がある箇所:
- Exception型を直接catchしているテスト → カスタム例外への変更で影響
- ListEditのコンストラクタ変更 → パラメータ追加で既存テスト修正が必要
- AuthProviderのモック → dispose動作の変更

## 検証手順

1. `flutter analyze` — Lintエラーゼロ
2. `flutter test` — 全テスト通過
3. 手動確認（推奨）:
   - アプリ起動・ショップタブ切替のスムーズさ
   - 設定変更（テーマ・フォント）の反映
   - エラー時のメッセージ表示（オフライン等）
