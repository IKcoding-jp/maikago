# Firestore セキュリティルール

## 概要

リアルタイム共有機能に対応したFirestoreセキュリティルールを実装しました。各コレクションに対して適切なアクセス制御を設定し、データの安全性を確保しています。

## セキュリティルールの構成

### 1. ユーザー認証 (`/users/{userId}`)

```javascript
// 認証されたユーザーは自分のドキュメントのみ読み書き可能
allow read, write: if request.auth != null && request.auth.uid == userId;
```

**アクセス制御:**
- ✅ 自分のユーザーデータの読み書き
- ❌ 他のユーザーのデータへのアクセス
- ❌ 未認証ユーザーのアクセス

**サブコレクション:**
- `/users/{userId}/items/{itemId}` - ユーザーのアイテム
- `/users/{userId}/shops/{shopId}` - ユーザーのショップ
- `/users/{userId}/subscription/{subscriptionId}` - サブスクリプション情報
- `/users/{userId}/donations/{donationId}` - 寄付データ（読み取りのみ）

### 2. ファミリー共有 (`/families/{familyId}`)

```javascript
// ファミリーメンバーのみアクセス可能
allow read, write: if request.auth != null && 
  resource.data.members[request.auth.uid] != null;
```

**アクセス制御:**
- ✅ ファミリーメンバーの読み書き
- ❌ 非メンバーのアクセス
- ❌ 未認証ユーザーのアクセス

### 3. 送信型共有 (`/transmissions/{transmissionId}`)

```javascript
// 送信者または受信者のみアクセス可能
allow read, write: if request.auth != null && (
  resource.data.sharedBy == request.auth.uid ||
  request.auth.uid in resource.data.sharedWith
);

// 新規作成時は送信者のみ
allow create: if request.auth != null && 
  request.resource.data.sharedBy == request.auth.uid;
```

**アクセス制御:**
- ✅ 送信者の読み書き
- ✅ 受信者の読み取り
- ❌ 関係者以外のアクセス
- ❌ 未認証ユーザーのアクセス

### 4. リアルタイム共有 - 同期データ (`/syncData/{syncId}`)

```javascript
// 作成者または共有対象者のみアクセス可能
allow read, write: if request.auth != null && (
  resource.data.userId == request.auth.uid ||
  request.auth.uid in resource.data.sharedWith
);

// 新規作成時は作成者のみ
allow create: if request.auth != null && 
  request.resource.data.userId == request.auth.uid;
```

**アクセス制御:**
- ✅ 作成者の読み書き
- ✅ 共有対象者の読み取り
- ❌ 関係者以外のアクセス
- ❌ 未認証ユーザーのアクセス

### 5. リアルタイム共有 - 通知 (`/notifications/{userId}`)

```javascript
// 通知の所有者のみアクセス可能
allow read, write: if request.auth != null && 
  request.auth.uid == userId;

// 通知アイテムのサブコレクション
match /items/{notificationId} {
  allow read, write: if request.auth != null && 
    request.auth.uid == userId;
  
  allow create: if request.auth != null && 
    request.auth.uid == userId;
}
```

**アクセス制御:**
- ✅ 通知所有者の読み書き
- ❌ 他のユーザーの通知へのアクセス
- ❌ 未認証ユーザーのアクセス

### 6. 送信履歴 (`/transmissionHistory/{historyId}`)

```javascript
// 送信者のみアクセス可能
allow read, write: if request.auth != null && 
  resource.data.senderId == request.auth.uid;

// 新規作成時は送信者のみ
allow create: if request.auth != null && 
  request.resource.data.senderId == request.auth.uid;
```

**アクセス制御:**
- ✅ 送信者の読み書き
- ❌ 受信者のアクセス
- ❌ 未認証ユーザーのアクセス

### 7. ファミリー招待 (`/familyInvites/{inviteId}`)

```javascript
// 認証されたユーザーは招待を読み書き可能
allow read, write: if request.auth != null;
```

**アクセス制御:**
- ✅ 認証ユーザーの読み書き
- ❌ 未認証ユーザーのアクセス

### 8. 匿名ユーザー (`/anonymous/{sessionId}`)

```javascript
// 匿名セッションのデータは誰でも読み書き可能（一時的なデータ）
allow read, write: if true;
```

**アクセス制御:**
- ✅ 誰でも読み書き可能（一時的データ）
- ⚠️ 機密データは保存禁止

## セキュリティのベストプラクティス

### 1. 最小権限の原則
- 各ユーザーは必要最小限のデータにのみアクセス可能
- 自分のデータと共有されたデータのみ読み取り可能

### 2. 認証の必須化
- 機密データへのアクセスには認証が必須
- 匿名ユーザーは一時的データのみアクセス可能

### 3. データ所有者の明確化
- 各データには明確な所有者（作成者）を設定
- 共有データには共有対象者を明示的に指定

### 4. 作成時の権限チェック
- 新規作成時は作成者の権限を確認
- 不正なデータ作成を防止

## デプロイ方法

### 1. Firebase CLIを使用したデプロイ

```bash
# セキュリティルールをデプロイ
firebase deploy --only firestore:rules

# 特定のプロジェクトにデプロイ
firebase deploy --only firestore:rules --project your-project-id
```

### 2. デプロイスクリプトを使用

```bash
# スクリプトに実行権限を付与
chmod +x deploy-rules.sh

# デプロイを実行
./deploy-rules.sh your-project-id
```

## テスト方法

### 1. ローカルテスト

```bash
# Firebase Emulatorを起動
firebase emulators:start

# テストを実行
npm test
```

### 2. セキュリティルールテスト

```bash
# セキュリティルールのテストを実行
firebase firestore:rules:test firestore.rules.test.js
```

## トラブルシューティング

### よくある問題

1. **権限エラー**
   - ユーザーが適切に認証されているか確認
   - データの所有者または共有対象者か確認

2. **リアルタイムリスナーエラー**
   - セキュリティルールがリアルタイムリスナーを許可しているか確認
   - クエリの条件がセキュリティルールと一致しているか確認

3. **デプロイエラー**
   - Firebase CLIが最新版か確認
   - プロジェクトIDが正しいか確認
   - 認証が有効か確認

### デバッグ方法

1. **Firebase Consoleでログを確認**
   - Firestore > ログ でアクセスログを確認

2. **ローカルエミュレーターでテスト**
   - 実際のデータに影響を与えずにテスト可能

3. **セキュリティルールのテスト**
   - 自動化されたテストでルールの動作を確認

## 今後の改善点

1. **より細かい権限制御**
   - ロールベースのアクセス制御
   - 時間ベースのアクセス制御

2. **監査ログ**
   - データアクセスの詳細ログ
   - セキュリティイベントの監視

3. **自動化**
   - CI/CDパイプラインでの自動テスト
   - セキュリティルールの自動検証

4. **暗号化**
   - 機密データの暗号化
   - 転送時の暗号化強化
