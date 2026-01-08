# 実装計画 - Android UI崩れ修正

## 1. 修正の目的
Android環境において、タブメニューと画面コンテンツ、およびボトムサマリー内の要素が重なってしまうレイアウトの問題を解消します。

## 2. 変更内容

### 2.1 トップのレイアウト修正 (`lib/screens/main_screen.dart`)
- `Scaffold` の `extendBodyBehindAppBar` を `false` に変更。
- `AppBar` に `toolbarHeight: _calculateTabHeight() + 16` を追加し、タブがAppBar内に収まるようにします。
- ボディの `Padding` を `EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0)` に変更（トップパディングを削除または大幅に縮小）。
- 各セクション（未購入・購入済み）の見出しのトップパディングを調整。

### 2.2 ボトムサマリーのレイアウト修正 (`lib/screens/main/widgets/bottom_summary_widget.dart`)
- 3つのアクションボタン（予算変更、カメラで追加、アイテム追加）を保持している `Stack` を `Row` に置き換えます。
- 中央の「カメラで追加」ボタンを正確に中央配置するため、以下の構造にします：
  ```dart
  Row(
    children: [
      Expanded(child: Align(alignment: Alignment.centerLeft, child: 予算変更ボタン)),
      カメラで追加ボタン,
      Expanded(child: Align(alignment: Alignment.centerRight, child: アイテム追加ボタン)),
    ],
  )
  ```
- これにより、各ボタンが重なるリスクを排除し、かつ中央配置を維持します。

## 3. 期待される効果
- タブとコンテンツ（未購入・購入済みラベル）の間に適切な余白が確保されます。
- ボトムサマリー内のボタンと合計金額表示が重ならず、整然と配置されます。
- 画面サイズが小さいAndroid端末でもレイアウトが崩れにくくなります。
