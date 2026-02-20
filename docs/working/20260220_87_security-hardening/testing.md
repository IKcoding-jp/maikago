# テスト計画: セキュリティ強化

Issue: #87
作成日: 2026-02-20

## 自動テスト

### flutter analyze
- [ ] Lintエラーなし

### flutter test
- [ ] 全既存テスト通過
- [ ] env.dart の新しいString.fromEnvironment()方式がテストで正常動作

## 手動テスト

### CR-1: env.json廃止

#### TC-CR-001: --dart-define でのビルド確認
1. `flutter build web --dart-define=FIREBASE_API_KEY=xxx ...` でビルド
2. `build/web/assets/` に `env.json` が含まれていないことを確認
3. Web版が正常に起動すること

#### TC-CR-002: ローカル開発でのビルド確認
1. `flutter run` で起動（env.json なし）
2. AdMob テスト用IDが使用されること
3. Firebase 接続が正常であること（ネイティブは google-services.json で動作）

#### TC-CR-003: CI/CDパイプライン確認
1. GitHub Actions でのWebデプロイが成功すること
2. `--dart-define` での値注入が正常に動作すること

### HI-1: anonymousコレクション UID紐づけ

#### TC-HI-001: 匿名ユーザーのデータアクセス
1. 匿名認証でログイン
2. スキップ機能でアイテムを追加
3. 自分のデータのみ読み書きできることを確認
4. 別ユーザーのセッションIDでのアクセスが拒否されることを確認

### HI-2: families createルール

#### TC-HI-002: ファミリー作成のバリデーション
1. 正常なファミリー作成（ownerId=自分のUID）が成功すること
2. ownerIdなしのファミリー作成が拒否されること
3. ownerId≠自分のUIDのファミリー作成が拒否されること

### HI-3: Cloud Functions v2移行

#### TC-HI-003: analyzeImage
1. カメラで商品を撮影→OCR+AI解析が正常動作
2. 認証なしでのアクセスが拒否されること

#### TC-HI-004: parseRecipe
1. レシピテキスト入力→材料抽出が正常動作

#### TC-HI-005: その他Functions
1. dissolveFamily, summarizeProductName, checkIngredientSimilarity が正常動作

### MD-1: スキーマバリデーション

#### TC-MD-001: フィールドバリデーション
1. 正常なデータでのCRUD操作が成功すること
2. 不正なフィールド型でのwriteが拒否されること

### MD-2: レート制限

#### TC-MD-002: analyzeImageレート制限
1. 連続5回の呼び出しが成功すること
2. 6回目がレート制限で拒否されること

### MD-4: sharedWith変更制限

#### TC-MD-003: transmissions権限
1. 送信者がsharedWithを変更できること
2. 受信者がsharedWithを変更できないこと
3. 受信者が読み取りのみ可能なこと

### MD-5: donationsルール

#### TC-MD-004: 寄付データの書き込み
1. 寄付後にデータがFirestoreに正常保存されること
2. 他ユーザーの寄付データにアクセスできないこと

### LO-2: レシピテキスト長さ制限

#### TC-LO-001: テキスト長制限
1. 5000文字以下のテキストが正常処理されること
2. 5000文字超のテキストがエラーで拒否されること

## セキュリティ確認

- [ ] env.json がビルド成果物に含まれていないこと
- [ ] APIキーがクライアントコードに含まれていないこと
- [ ] Firestoreルールが正しく適用されていること
- [ ] Cloud Functionsで Secret Manager が正常動作すること
