# 要件定義

**Issue**: #137
**作成日**: 2026-03-14
**ラベル**: testing, refactor

## ユーザーストーリー
ユーザー「課金したのに反映されない / ログインできない、というバグが怖い」
アプリ「課金・認証の核心ロジックにテストがあり、リグレッションを防止できる」

開発者「SharedGroup という命名が共有タブ機能と混同されて分かりにくい」
アプリ「SharedTab* に統一されており、コードの意図が明確」

## 要件一覧

### 必須要件
- [ ] A1: OneTimePurchaseService / PurchasePersistence / TrialManager のユニットテスト
- [ ] A2: AuthService / AuthProvider のユニットテスト
- [ ] A3-1: SharedGroupService + テストの削除（未使用コード）
- [ ] A3-2: SharedGroup* → SharedTab* の命名リファクタ（Dartコード全体）
- [ ] A3-3: Firestore フィールド名のマイグレーション対応（デュアルリード）
- [ ] A3-4: SharedTabManager のテスト追加（削除分のカバレッジ移行）

### オプション要件
- [ ] Firestore 旧フィールド削除（デュアルリード期間終了後）
- [ ] Firestore セキュリティルールに共有タブフィールドの検証追加

## 受け入れ基準
- [ ] `flutter test` が全パス
- [ ] `flutter analyze` がエラーなし
- [ ] 課金フロー（購入・復元・体験期間）のテストケースが網羅されている
- [ ] 認証フロー（ログイン・ログアウト・ゲストモード）のテストケースが網羅されている
- [ ] コードベースに `SharedGroup` の命名が残っていない（Firestore デュアルリードの fromJson 除く）
- [ ] 既存ユーザーの Firestore データが正常に読み込める（デュアルリード）
