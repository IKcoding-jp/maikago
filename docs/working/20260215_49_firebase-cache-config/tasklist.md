# タスクリスト: Firebase Hostingキャッシュ設定・Firestoreオフライン設定

**ステータス**: 進行中
**開始日**: 2026-02-15

## フェーズ1: Firebase Hostingキャッシュヘッダー設定

- [ ] `firebase.json` に `headers` セクションを追加
  - 静的アセット用: `Cache-Control: public, max-age=31536000`
  - `index.html` 用: `Cache-Control: no-cache`

## フェーズ2: Firestoreオフラインキャッシュ設定

- [ ] `lib/main.dart` のFirebase初期化後に Firestore Settings を追加
  - `persistenceEnabled: true`
  - `cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED`

## フェーズ3: 検証

- [ ] `flutter analyze` 通過
- [ ] `flutter test` 通過
