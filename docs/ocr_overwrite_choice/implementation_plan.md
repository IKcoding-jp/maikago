# 実装計画：OCR読み取り結果の既存商品上書き選択機能

OCRで読み取った商品を保存する際、既存リスト内の同一商品を検知し、ユーザーが「上書き」か「新規追加」かを個別に選択できるようにします。

## ユーザーレビューが必要な項目
> [!IMPORTANT]
> 「既存のリストを最新にする」モードの動作を変更します。これまでは「対象リストの商品をすべて削除して入れ替える」動作でしたが、今後は「既存の商品を維持しつつ、マッチしたものは更新、新しいものは追加」するマージ動作に変更します。

## 修正内容

### 1. `OcrResultConfirmScreen` へのマッチング機能追加 [MODIFY]
[ocr_result_confirm_screen.dart](file:///d:/Dev/maikago/lib/screens/ocr_result_confirm_screen.dart)

- **状態管理の追加**:
  - `Map<int, ListItem?> _matchedItems`: OCRアイテムのインデックスから、マッチした既存項目へのマッピング。
  - `Set<int> _itemsToOverwrite`: ユーザーが上書きを選択したアイテムのインデックス。
- **マッチングロジック**:
  - `SaveMode` が変更された際、または対象ショップが選択された際に、`_items` と `targetShop.items` を比較。
  - 基本は名前の完全一致、または `ProductNameSummarizerService` の簡易正規化を用いた名前一致。
- **UI: アイテムカードの強化**:
  - マッチした項目がある場合、「既存商品が見つかりました: [商品名]」と表示。
  - 「既存の商品を更新する」トグルスイッチを追加。

### 2. 保存処理の刷新 [MODIFY]
[ocr_result_confirm_screen.dart](file:///d:/Dev/maikago/lib/screens/ocr_result_confirm_screen.dart)

- **`_saveAsNew` の修正**:
  - 現在のショップ（タブ）内の商品と比較し、上書き選択時は `updateItem`、そうでない場合は `addItem` を実行。
- **`_saveAsUpdate` / `_replaceShopItems` の修正**:
  - `_replaceShopItems` は「削除してから追加」ではなく、ループ内でマッチングを考慮して `updateItem` または `addItem` を行う方式に変更。
  - これにより、スキャンされなかった既存の商品が削除されずに残るようになります（マージ動作）。

### 3. データプロバイダーの利用 [MODIFY]
[data_provider.dart](file:///d:/Dev/maikago/lib/providers/data_provider.dart)

- `updateItem` メソッドが既存であることを確認し、必要に応じて利用します。

## 検証プラン

### 手動確認
1. アプリを起動し、既存の買い物リストに「牛乳」など適当な商品を追加。
2. カメラで「牛乳」の価格を撮影。
3. 確認画面で「既存の商品が見つかりました: 牛乳」が表示されることを確認。
4. 「更新する」をオンにして保存し、買い物リストの牛乳の価格が更新されることを確認。
5. 「更新する」をオフにして保存し、買い物リストに牛乳が2つ並ぶことを確認。
6. 「既存のリストを最新にする」モードでも同様のマージ動作が行われることを確認。
