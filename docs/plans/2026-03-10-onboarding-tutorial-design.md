# 初回チュートリアル（コーチマーク + 空状態ガイド）デザイン

## 概要

新規ユーザーが初回起動時にアプリの基本操作を直感的に理解できるよう、2つの仕組みを導入する。

1. **コーチマーク** — ウェルカムダイアログ完了直後に、メイン画面上でUIをハイライトしながら4ステップで案内
2. **空状態ガイド** — アイテムが0個のとき、未購入リスト領域にCTAを常時表示

## コーチマーク

### 実装方式

自前実装（`Overlay` + `CustomPainter`）。パッケージ不使用。

フルオーバーレイ方式：半透明背景にターゲットの穴を抜き、吹き出しで説明を表示。

### コンポーネント構成

```
CoachMarkOverlay (StatefulWidget)
├── _CoachMarkPainter (CustomPainter) — 半透明背景 + ターゲット穴抜き
├── _CoachMarkTooltip (Widget) — 吹き出し（説明テキスト + ボタン）
└── CoachMarkStep — ステップデータモデル（ターゲットKey、テキスト、穴形状）
```

### 4ステップ

| # | ターゲット | 説明テキスト | 穴の形状 |
|---|-----------|-------------|---------|
| 1 | FAB（アイテム追加ボタン） | 「ここからアイテムを追加できます」 | 円形 |
| 2 | 未購入リスト領域全体 | 「アイテムを追加したら左スワイプで購入済みに移動できます」 | 角丸矩形 |
| 3 | タブバーの「+」ボタン | 「タブを追加して複数の買い物リストを管理できます」 | 円形 |
| 4 | 予算エリア（ボトムバー） | 「予算を設定して買いすぎを防止しましょう」 | 角丸矩形 |

### 表示フロー

```
ウェルカムダイアログ完了
  ↓
CoachMarkOverlay を Overlay に挿入（addPostFrameCallback使用）
  ↓
ステップ1表示（穴抜きアニメーション + 吹き出しフェードイン）
  ↓ 「次へ」タップ
ステップ2〜4へ遷移
  ↓
ステップ4 →「始める」タップ
  ↓
Overlay 除去 + coach_mark_completed = true を保存
```

- 「スキップ」ボタン: 吹き出し内右上に常時表示。全ステップを飛ばして完了
- 背景タップ: 無効（誤操作防止）

### アニメーション

| 要素 | アニメーション | 時間 |
|------|-------------|------|
| オーバーレイ表示 | フェードイン | 300ms |
| 穴の位置移動 | `Curves.easeInOut` | 400ms |
| 吹き出し | フェードイン + 軽いスライド | 300ms（穴移動完了後） |
| オーバーレイ終了 | フェードアウト | 300ms |

### 吹き出しデザイン

- 背景: 白、角丸12px、elevation: 4 のシャドウ
- 説明テキスト: 16px、FontWeight.w500
- 「スキップ」: 右上、テキストボタン、グレー
- 「次へ」ボタン: テーマカラーの FilledButton、ステップ表記付き（例: 次へ 1/4）
- 最終ステップ: ボタンテキストを「始める」に変更
- 尻尾（三角）: 穴の方向に合わせて上下に切り替え

### オーバーレイデザイン

- 背景色: `Colors.black.withOpacity(0.7)`
- 穴抜き: ターゲットの周囲に8pxパディング。角丸矩形は borderRadius: 12
- `CustomPainter` で `Path.combine(PathOperation.difference, ...)` を使用

## 空状態ガイド

### 表示条件

- 現在選択中タブのアイテムが0個のとき表示
- アイテムが追加されたら自動的に消える
- 毎回表示（初回限定フラグなし）

### デザイン

未購入リスト領域の中央に表示：

- アイコン: `Icons.shopping_cart_outlined`、テーマカラーの薄い色で大きめ表示
- メインテキスト: 「アイテムがまだありません」
- サブテキスト: 「下の ＋ ボタンから追加してみましょう」
- 下向き矢印: FAB方向を指し、軽くバウンスするアニメーション

## ファイル構成

### 新規ファイル

```
lib/widgets/coach_mark/
├── coach_mark_overlay.dart      — メインの StatefulWidget（Overlay管理）
├── coach_mark_painter.dart      — CustomPainter（穴抜き描画）
├── coach_mark_tooltip.dart      — 吹き出しウィジェット
└── coach_mark_step.dart         — ステップデータモデル

lib/screens/main/widgets/
└── empty_state_guide.dart       — 空状態ガイドウィジェット
```

### 既存ファイルの変更

| ファイル | 変更内容 |
|---------|---------|
| `main_screen.dart` | 4つの GlobalKey を追加（FAB、未購入リスト領域、タブ追加ボタン、予算エリア） |
| `startup_helpers.dart` | ウェルカムダイアログ完了後にコーチマーク起動処理を追加 |
| `settings_persistence.dart` | `coach_mark_completed` フラグの読み書きメソッド追加 |
| リスト表示部分 | アイテム0個時に EmptyStateGuide を表示する条件分岐追加 |
| `advanced_settings_screen.dart` | コーチマークリセット機能を追加 |

### SharedPreferences

- `coach_mark_completed` — bool、初期値 false
