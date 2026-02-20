# タスクリスト: セキュリティ強化

Issue: #87
作成日: 2026-02-20
**ステータス**: 完了
**完了日**: 2026-02-20

---

## Phase 1: Critical — env.json廃止 (CR-1)

- [x] 1.1 `lib/env.dart` を `--dart-define`優先 + `env.json`フォールバックのハイブリッド方式に変更
- [x] 1.5 `.github/workflows/firebase-hosting-merge.yml` を `--dart-define` に移行
- 1.2〜1.4, 1.6: ハイブリッド方式採用のため不要（env.jsonはローカル開発用フォールバックとして継続使用）

## Phase 2: High — Firestoreルール改善 (HI-1, HI-2)

- [x] 2.1 `firestore.rules` anonymousコレクションにUID紐づけ追加
- [x] 2.2 `firestore.rules` families createルールにownerId必須化+バリデーション
- [x] 2.3 変更したルールのデプロイスクリプトの確認

## Phase 3: High — Cloud Functions v2移行 (HI-3)

- [x] 3.1 `functions/package.json` の依存更新（firebase-functions v2対応）
- [x] 3.2 `analyzeImage` をv2 API + defineSecret()に移行
- [x] 3.3 `dissolveFamily` をv2 APIに移行
- [x] 3.4 `testConnection` をv2 APIに移行
- [x] 3.5 `parseRecipe` をv2 APIに移行
- [x] 3.6 `summarizeProductName` をv2 APIに移行
- [x] 3.7 `checkIngredientSimilarity` をv2 APIに移行
- [x] 3.8 Firestore triggers をv2 APIに移行
- [x] 3.9 Scheduled function をv2 APIに移行

## Phase 4: Medium — Firestoreルール強化 (MD-1, MD-4, MD-5)

- [x] 4.1 familiesコレクションにスキーマバリデーション追加
- [x] 4.2 transmissionsコレクション: sharedWith変更を送信者のみに制限
- [x] 4.3 syncDataコレクション: sharedWith変更を送信者のみに制限
- [x] 4.4 donationsルールの整合性修正（クライアント書き込み許可に変更）
- [x] 4.5 rateLimitsコレクション追加

## Phase 5: Medium — Cloud Functions追加機能 (MD-2, MD-3)

- [x] 5.1 全Cloud Functionsにレート制限追加（Firestoreベース、5回/分、50回/日）
- 5.2 体験期間（Trial）検証のサーバーサイド移行 → 将来のIssueとして検討

## Phase 6: Low — 追加改善 (LO-1, LO-2, LO-3)

- [x] 6.1 flutter_secure_storageの導入検討（コメントとして記録）
- [x] 6.2 レシピ入力テキストの長さ制限追加（クライアント+サーバー）
- [x] 6.3 notifications作成ルールの改善（family_dissolvedにownerId検証追加）
