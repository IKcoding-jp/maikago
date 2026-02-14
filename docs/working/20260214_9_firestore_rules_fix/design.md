# 設計書

## 実装方針

### 変更対象ファイル
- `firestore.rules` - セキュリティルール修正

### familyInvites修正案

**Before:**
```
allow read, write: if request.auth != null && (
  resource.data.createdBy == request.auth.uid ||
  true
);
```

**After（案A: トークンベース）:**
```
// 作成者は全操作可能
allow read, write: if request.auth != null &&
  resource.data.createdBy == request.auth.uid;

// トークンを知っているユーザーは読み取り可能
allow read: if request.auth != null;

// 招待の承認（statusの更新）は認証ユーザーのみ
allow update: if request.auth != null &&
  request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'acceptedBy', 'updatedAt']);
```

### anonymous修正案

**Before:**
```
allow read, write: if true;
```

**After:**
```
// 認証済みユーザーのみ（匿名認証を含む）
allow read, write: if request.auth != null;
```

## 影響範囲
- 匿名ユーザー機能: Firebase Anonymous Authを使用している場合は影響なし。未使用の場合はクライアント側で匿名認証を追加する必要あり
- 招待フロー: クライアント側の招待承認ロジックがルール変更に対応する必要あり
