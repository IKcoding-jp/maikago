# 要件定義: Firebase Hostingキャッシュ設定・Firestoreオフライン設定

## Issue
- **番号**: #49
- **タイトル**: [Low/Config] Firebase Hostingキャッシュ設定・Firestoreオフライン設定
- **ラベル**: chore

## 要件

### 1. Firebase Hostingキャッシュヘッダー設定
- **対象ファイル**: `firebase.json`
- 静的アセット（JS, CSS, 画像等）に長期キャッシュヘッダーを設定
  - `Cache-Control: public, max-age=31536000`（1年）
- `index.html` にはキャッシュ無効ヘッダーを設定
  - `Cache-Control: no-cache`
- Flutter Webビルドはハッシュ付きファイル名を生成するため、長期キャッシュは安全

### 2. Firestoreオフラインキャッシュの明示的設定
- **対象ファイル**: `lib/main.dart`（Firebase初期化部分）
- Firestore Settingsで永続化を明示的に有効化
- Web版ではデフォルトで永続化が無効のため、明示的に有効化が必要

## 受け入れ基準
- [ ] `firebase.json` にキャッシュヘッダーが正しく設定されている
- [ ] Firestore初期化時にpersistence設定が明示的に行われている
- [ ] 既存機能に影響がないこと
- [ ] `flutter analyze` が通ること
- [ ] `flutter test` が通ること
