# 設計書: Firebase Hostingキャッシュ設定・Firestoreオフライン設定

## 変更対象ファイル

### 1. `firebase.json`
- `hosting` セクション内に `headers` を追加
- rewrites の前に配置

### 2. `lib/main.dart`
- Firebase初期化成功後（L71付近）に Firestore Settings を設定
- `FirebaseFirestore.instance.settings` に永続化設定を代入

## 設計詳細

### firebase.json の変更

```json
"headers": [
  {
    "source": "**/*.@(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)",
    "headers": [
      { "key": "Cache-Control", "value": "public, max-age=31536000" }
    ]
  },
  {
    "source": "index.html",
    "headers": [
      { "key": "Cache-Control", "value": "no-cache" }
    ]
  }
]
```

### main.dart の変更

Firebase初期化成功後に以下を追加:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

## 影響範囲

- Firebase Hosting: Web版のみ影響。静的アセットのロード速度向上
- Firestore: 全プラットフォーム影響。特にWeb版でオフライン永続化が有効になる
- 既存のデータアクセス層（`data_service.dart`）への変更は不要
