# 設計書: セキュリティ強化

Issue: #87
作成日: 2026-02-20

## CR-1: env.json廃止 → --dart-define一本化

### 現在のアーキテクチャ
```
env.json (Flutter asset)
  ↓ rootBundle.loadString()
lib/env.dart (Env class)
  ↓
lib/firebase_options.dart (Web Firebase config)
lib/services/ad/ (AdMob IDs)
```

### 変更後のアーキテクチャ
```
--dart-define (ビルド時注入)
  ↓ String.fromEnvironment()
lib/env.dart (Env class) — compile-time constants に変更
  ↓
lib/firebase_options.dart (変更なし - Envを参照)
lib/services/ad/ (変更なし - Envを参照)
```

### 変更内容
1. **`lib/env.dart`**: `rootBundle.loadString()` を廃止し、`String.fromEnvironment()` に変更
2. **`pubspec.yaml`**: `- env.json` をアセットから削除
3. **`lib/main.dart`**: `Env.load()` 呼び出しを削除（compile-time constantsのため不要）
4. **CI/CD (GitHub Actions)**: `echo '${{ secrets.ENV_JSON }}' > env.json` → `--dart-define` フラグに変更
5. **`env.json`**: ファイル自体は残す（ローカル開発用参考）が、アセットとしてはバンドルしない

### env.json → --dart-define マッピング
| env.json キー | --dart-define 名 |
|---|---|
| ADMOB_APP_OPEN_AD_UNIT_ID | ADMOB_APP_OPEN_AD_UNIT_ID |
| ADMOB_BANNER_AD_UNIT_ID | ADMOB_BANNER_AD_UNIT_ID |
| ADMOB_INTERSTITIAL_AD_UNIT_ID | ADMOB_INTERSTITIAL_AD_UNIT_ID |
| FIREBASE_API_KEY | FIREBASE_API_KEY |
| FIREBASE_APP_ID | FIREBASE_APP_ID |
| FIREBASE_MESSAGING_SENDER_ID | FIREBASE_MESSAGING_SENDER_ID |
| FIREBASE_PROJECT_ID | FIREBASE_PROJECT_ID |
| FIREBASE_AUTH_DOMAIN | FIREBASE_AUTH_DOMAIN |
| FIREBASE_STORAGE_BUCKET | FIREBASE_STORAGE_BUCKET |
| FIREBASE_MEASUREMENT_ID | FIREBASE_MEASUREMENT_ID |
| GOOGLE_WEB_CLIENT_ID | GOOGLE_WEB_CLIENT_ID |

## HI-1: anonymousコレクション UID紐づけ

### 変更前
```
match /anonymous/{sessionId} {
  allow read, write: if request.auth != null;
}
```

### 変更後
```
match /anonymous/{sessionId} {
  allow read, write: if request.auth != null && request.auth.uid == sessionId;

  match /items/{itemId} {
    allow read, write: if request.auth != null && request.auth.uid == sessionId;
  }
  match /shops/{shopId} {
    allow read, write: if request.auth != null && request.auth.uid == sessionId;
  }
}
```

### 注意点
- 匿名ユーザーの `sessionId` が `auth.uid` と一致する前提
- クライアントコードを確認し、sessionIdにauth.uidを使用していることを検証する必要がある

## HI-2: families createルール バリデーション

### 変更前
```
allow create: if request.auth != null;
```

### 変更後
```
allow create: if request.auth != null &&
  request.resource.data.keys().hasAll(['ownerId', 'members']) &&
  request.resource.data.ownerId == request.auth.uid;
```

## HI-3: Firebase Functions v2移行

### 変更内容
1. `firebase-functions` パッケージを v2 API に更新
2. `functions.https.onCall` → `onCall` (v2)
3. `functions.runWith()` → v2 options
4. `process.env.OPENAI_API_KEY` → `defineSecret('OPENAI_API_KEY')`
5. Firestore triggers: `functions.firestore.document()` → `onDocumentCreated` / `onDocumentUpdated`

### 例: analyzeImage
```js
// Before
exports.analyzeImage = functions.runWith({ memory: '512MB' }).https.onCall(async (data, context) => { ... });

// After
const { onCall } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const openaiApiKey = defineSecret('OPENAI_API_KEY');

exports.analyzeImage = onCall({ memory: '512MiB', secrets: [openaiApiKey] }, async (request) => {
  // request.auth instead of context.auth
  // request.data instead of data
});
```

## MD-1: スキーマバリデーション

### 対象コレクション
- `users/{userId}` — 基本フィールド
- `families/{familyId}` — ownerId(string), members(list), isActive(bool)
- `transmissions/{transmissionId}` — sharedBy(string), sharedWith(list)
- `syncData/{syncId}` — userId(string), sharedWith(list)

### バリデーション例
```
allow create: if request.auth != null &&
  request.resource.data.ownerId is string &&
  request.resource.data.ownerId.size() > 0 &&
  request.resource.data.ownerId.size() < 128;
```

## MD-2: analyzeImage レート制限

### 設計
- Firestoreに `rateLimits/{userId}` コレクションを追加
- 1分あたり5回、1日あたり50回の制限
- Cloud Function内でカウントチェック

## MD-3: Trial検証のサーバーサイド移行

### 現状
- `one_time_purchase_service.dart` でクライアントサイドの体験期間管理
- SharedPreferences + Firestore に `trial_history` を保存

### 変更方針
- Firestoreの `trial_history` データを正とし、サーバーサイドで検証
- Cloud Functionsで体験期間の開始/終了を管理するAPIを追加
- Firestoreルールで `trial_history` の直接書き込みを制限

## MD-4: sharedWithフィールドの変更制限

### 変更前（transmissions）
```
allow read, write: if request.auth != null && (
  resource.data.sharedBy == request.auth.uid ||
  request.auth.uid in resource.data.sharedWith
);
```

### 変更後
```
// 送信者: 全操作可能
allow read, update, delete: if request.auth != null &&
  resource.data.sharedBy == request.auth.uid;

// 受信者: 読み取りのみ + sharedWith以外のフィールド更新
allow read: if request.auth != null &&
  request.auth.uid in resource.data.sharedWith;
allow update: if request.auth != null &&
  request.auth.uid in resource.data.sharedWith &&
  !request.resource.data.diff(resource.data).affectedKeys().hasAny(['sharedWith', 'sharedBy']);
```

### syncDataも同様の変更を適用

## MD-5: donationsルールの整合性修正

### 現状の不整合
- ルール: `allow write: if false;` → クライアント書き込み禁止
- `donation_service.dart`: `_saveToFirestore()` でクライアントから書き込み

### 修正方針
- donation_service.dart を修正し、Firestore への直接書き込みを廃止
- 代わりに Cloud Function 経由で書き込み
- または ルールを `allow write: if request.auth != null && request.auth.uid == userId;` に変更

### 推奨: ルール側を修正（クライアント書き込み許可）
理由: 寄付データはユーザー自身のサブコレクション配下にあり、自分のデータのみ書き込む設計のため

## LO-1: flutter_secure_storage検討

### 判断
- `flutter_secure_storage` パッケージを依存に追加
- `SharedPreferences` から `FlutterSecureStorage` へ移行
- プレミアム状態、体験期間情報を暗号化保存

## LO-2: レシピ入力テキスト長さ制限

### 変更箇所
1. `functions/index.js` の `parseRecipe`: recipeText の文字数上限チェック（5000文字）
2. `lib/services/recipe_parser_service.dart`: クライアント側でも事前チェック

## LO-3: notifications作成ルール改善

### 変更前
```
allow create: if request.auth != null &&
  (... || (request.resource.data.type == 'family_dissolved' && request.auth.uid != userId));
```

### 変更後
family_dissolved通知の作成時にファミリーオーナーであることを確認する。
ただし、Firestoreルールでは別コレクションの参照ができないため、
Cloud Functions経由での通知作成を推奨。

現実的な対応:
- `request.resource.data.ownerId == request.auth.uid` フィールドを通知データに追加し、送信者情報を記録
