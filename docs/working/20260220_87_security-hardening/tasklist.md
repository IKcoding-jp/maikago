# タスクリスト: セキュリティ強化

Issue: #87
作成日: 2026-02-20
**ステータス**: 作業中

---

## Phase 1: Critical — env.json廃止 (CR-1)

- [ ] 1.1 `lib/env.dart` を `String.fromEnvironment()` ベースに書き換え
  - `rootBundle.loadString()` を削除
  - `load()` メソッドを非同期→同期に変更（または不要にする）
  - 各getterを `const String.fromEnvironment()` に変更
- [ ] 1.2 `pubspec.yaml` から `- env.json` アセット定義を削除
- [ ] 1.3 `lib/main.dart` から `Env.load()` 呼び出しを削除
- [ ] 1.4 `lib/firebase_options.dart` を `--dart-define` 対応に更新
- [ ] 1.5 `.github/workflows/firebase-hosting-merge.yml` を `--dart-define` に移行
- [ ] 1.6 テストの `env.json` 依存を解消

## Phase 2: High — Firestoreルール改善 (HI-1, HI-2)

- [ ] 2.1 `firestore.rules` anonymousコレクションにUID紐づけ追加
  - クライアントコードでsessionId=auth.uidを確認
- [ ] 2.2 `firestore.rules` families createルールにownerId必須化+バリデーション
- [ ] 2.3 変更したルールのデプロイスクリプトの確認

## Phase 3: High — Cloud Functions v2移行 (HI-3)

- [ ] 3.1 `functions/package.json` の依存更新（firebase-functions v2対応）
- [ ] 3.2 `analyzeImage` をv2 API + defineSecret()に移行
- [ ] 3.3 `dissolveFamily` をv2 APIに移行
- [ ] 3.4 `testConnection` をv2 APIに移行
- [ ] 3.5 `parseRecipe` をv2 APIに移行
- [ ] 3.6 `summarizeProductName` をv2 APIに移行
- [ ] 3.7 `checkIngredientSimilarity` をv2 APIに移行
- [ ] 3.8 Firestore triggers (`applyFamilyPlanToGroup`, `handleFamilyPlanExpiration`)をv2 APIに移行
- [ ] 3.9 Scheduled function (`checkFamilyPlanExpirations`)をv2 APIに移行

## Phase 4: Medium — Firestoreルール強化 (MD-1, MD-4, MD-5)

- [ ] 4.1 familiesコレクションにスキーマバリデーション追加
- [ ] 4.2 transmissionsコレクション: sharedWith変更を送信者のみに制限
- [ ] 4.3 syncDataコレクション: sharedWith変更を送信者のみに制限
- [ ] 4.4 donationsルールの整合性修正（クライアント書き込み許可 or CF経由に変更）
- [ ] 4.5 その他コレクションにスキーマバリデーション追加

## Phase 5: Medium — Cloud Functions追加機能 (MD-2, MD-3)

- [ ] 5.1 analyzeImageにレート制限追加
- [ ] 5.2 体験期間（Trial）検証のサーバーサイド移行
  - Cloud Function APIの追加
  - Firestoreルールでtrial_historyの直接書き込み制限

## Phase 6: Low — 追加改善 (LO-1, LO-2, LO-3)

- [ ] 6.1 flutter_secure_storageの導入検討と実装
- [ ] 6.2 レシピ入力テキストの長さ制限追加（クライアント+サーバー）
- [ ] 6.3 notifications作成ルールの改善
