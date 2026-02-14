# 実装計画: 共有タブの視覚的グループ化

## Goal Description
共有機能を持つタブ（`Shop`）について、同じ共有グループに属するタブ同士を視覚的に結合し、一つの大きなグループとして認識できるようにUIを変更します。
具体的には、隣接するタブの角の丸み（BorderRadius）とマージンを調整し、`(( A )( B ))` のような連結された見た目を実現します。

## User Review Required
- **デザイン変更**: タブの形状が大きく変わります。特に共有タブは「カプセル型」から「連結ボタン型」に変化します。

## Proposed Changes

### UI Components

#### [MODIFY] [main_screen.dart](file:///d:/Dev/maikago/lib/screens/main_screen.dart)

`AppBar` 内の `ListView.builder` におけるタブ描画処理を変更します。

1.  **隣接チェック**:
    - 現在のインデックス (`index`) の前後のショップを取得します。
    - `sharedGroupId` が一致するかどうかを判定します。
    - 判定フラグを作成:
        - `isFirstInGroup`: グループの先頭（左端）
        - `isLastInGroup`: グループの末尾（右端）
        - `isMiddleInGroup`: グループの中間
        - `isSingleInGroup`: グループに属しているが単独（前後に同じグループなし）

2.  **スタイル適用**:
    - **BorderRadius**:
        - `isFirstInGroup`: 左側のみ丸く (`BorderRadius.horizontal(left: Radius.circular(20))`)
        - `isLastInGroup`: 右側のみ丸く (`BorderRadius.horizontal(right: Radius.circular(20))`)
        - `isMiddleInGroup`: 丸みなし (`BorderRadius.zero`)
        - その他: 全体に丸み (`BorderRadius.circular(20)`)
    - **Margin**:
        - グループ内の右端以外（`isFirstInGroup` または `isMiddleInGroup`）: `margin: EdgeInsets.zero` または `EdgeInsets.only(right: 1)` （境界線調整のため）
        - その他: `margin: EdgeInsets.only(right: 8)`

4.  **UI Cleanup**:
    - **Shared Mark Selection**: `TabEditDialog` 内の共有マーク選択UI（アイコン一覧）を削除します。

3.  **Border調整**:
    - 隣接部分のボーダーが二重にならないように調整が必要な場合は、左側のボーダーを消す等の対応を検討しますが、今回はシンプルに隙間をなくすアプローチから始めます。

## Verification Plan

### Manual Verification
- `MainScreen` でタブアイテムの表示を確認。
    - 共有グループに属さないタブが従来通り表示されること。
    - 同じ共有グループのタブが2つ以上並んだ際、連結して表示されること。
    - グループの左端、右端が適切に丸められていること。
    - グループ間のマージンは維持されていること。
