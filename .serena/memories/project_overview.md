# まいカゴ - プロジェクト概要

## 目的
買いすぎ防止のための買い物リスト管理アプリ（Flutter マルチプラットフォーム）

## 技術スタック
- Flutter / Dart (SDK >=3.0.0 <4.0.0)
- Firebase (Firestore, Auth, Functions, Hosting)
- Provider パターンによる状態管理
- Node.js 18 (Cloud Functions)

## 対応プラットフォーム
iOS, Android, Web, Windows

## アーキテクチャ
Provider パターン: 画面 → Provider → Service → Firestore
- `lib/providers/data_provider.dart` - ファサードパターン（Repository/Managerに委譲）
- `lib/providers/repositories/` - CRUD操作
- `lib/providers/managers/` - キャッシュ、リアルタイム同期、共有グループ
- `lib/models/` - データモデル
- `lib/services/` - ビジネスロジック
- `lib/screens/` - UI画面

## 重要コマンド
- `flutter pub get` - 依存関係
- `flutter analyze` - 静的分析
- `flutter test` - テスト実行
- `flutter build apk --debug` - Android APK

## コード規約
- Lint: `flutter_lints`
- テーマ: `SettingsTheme.generateTheme()`
- Web対応: `kIsWeb` で分岐、横幅800px制限
