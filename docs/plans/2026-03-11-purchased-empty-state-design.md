# 購入済みEmpty State デザイン

## 概要

購入済みセクションが空のとき、操作方法とエリアの意味を伝えるEmpty Stateを表示する。

## 表示条件

- 購入済みアイテムが0件のときだけ表示
- 1つでもアイテムが移動されたら消える（フラグ管理なし）

## UIコンポーネント

既存の `EmptyStateGuide` と同じスタイル・構造:

```
    [← スワイプアイコン]     ← バウンスアニメーション（左右方向）

  リストを右にスワイプして購入済みへ  ← メインテキスト

  ここに移動すると               ← サブテキスト
  合計金額に反映されます
```

## スタイル詳細

- **アイコン**: `Icons.swipe_left_rounded`、サイズ64
- **アイコン色**: `AppColors.secondary` (`#B5EAD7` パステルグリーン) — 未購入側のパステルピンクとの対比
- **アニメーション**: 既存のバウンスと同様だが、上下ではなく**左右方向**に揺れる（スワイプ動作を連想）
- **メインテキスト**: fontSize 16, fontWeight w500, alpha 0.6
- **サブテキスト**: fontSize 13, alpha 0.5

## 既存EmptyStateGuideの改善

- アイコンのalpha: 0.3 → **0.5** に変更（視認性改善）

## 実装場所

- 新規: `lib/screens/main/widgets/empty_state_purchased_guide.dart`
- 変更: `item_list_section.dart` の `SizedBox.shrink()` を新ウィジェットに置き換え
- 変更: `empty_state_guide.dart` のアイコンalpha改善
