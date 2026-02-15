# 要件定義: Issue #39 + #43

## Issue #39: Firestoreコスト最適化（不要な読み取り削除）

### 対象範囲（今回実装）
1. `updateItem` の get-then-update パターンを `set(merge: true)` に統合
2. `updateShop` の同上（FieldValue.delete() 処理は維持）
3. `deleteItem` の不要な存在確認 `get()` を削除

### スコープ外
- リアルタイムリスナーの全件取得最適化
- checkIngredientSimilarity のAPI効率化
- 寄付データの配列スケーリング
- `deleteShop` の `get()` — 共有データクリーンアップに必要

## Issue #43: コールバック注入パターンの簡素化

### 対象範囲
1. `DataProviderState` 共有状態クラスを導入
2. Repository/Manager のコンストラクタをコールバック群 → State オブジェクト1個に変更
3. DataProvider を State 経由に更新

### 受け入れ基準
- `flutter analyze` エラーなし
- `flutter test` 全テスト通過
- 外部インターフェース（DataProvider の公開API）に変更なし
