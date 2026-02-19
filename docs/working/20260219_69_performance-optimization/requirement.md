# 要件定義

**Issue**: #69
**作成日**: 2026-02-19
**ラベル**: performance

## ユーザーストーリー

ユーザー「アイテムを追加・編集するたびに画面がカクつくのが気になる。スクロールもスムーズにしたい」
アプリ「データ変更時に必要最小限のWidgetだけが再描画され、スムーズな操作体験を提供する」

## 要件一覧

### 必須要件
- [ ] メイン画面のリビルド範囲を最小化する（Consumer2 → Selector分割）
- [ ] build()内の副作用を除去する（TabController再作成、ソート処理）
- [ ] context.selectを導入し、必要なプロパティのみ監視する
- [ ] FutureBuilderに保存済みFutureを渡す

### オプション要件
- [ ] Firestoreクエリの効率化（WriteBatch導入）
- [ ] 不要なConsumer/listen:trueの除去
- [ ] ThemeData生成のキャッシュ化
- [ ] cacheExtentの最適化

## 受け入れ基準
- [ ] メイン画面でアイテム追加/削除時に、AppBarやDrawerがリビルドされない
- [ ] flutter analyze がパスする
- [ ] 既存テストが全てパスする
- [ ] 設定画面での操作がスムーズになる（ThemeData重複生成の解消）
- [ ] 目に見えるリグレッションがない
