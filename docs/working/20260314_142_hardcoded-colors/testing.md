# テスト計画: ハードコード色をテーマ変数に置換

## Issue

- **Issue番号**: #142
- **作成日**: 2026-03-14

---

## 1. テスト戦略

本 Issue はリファクタリング（動作変更なし）であるため、以下の方針でテストする:

1. **静的解析**: `flutter analyze` でコンパイルエラー・警告がないこと
2. **既存テスト**: `flutter test` で全テストが通過すること（回帰テストとして機能）
3. **目視確認**: テーマ切り替えによる表示の適切性を確認

新規ユニットテストの追加は不要（色の値自体は変更しないため、既存テストでカバー）。

---

## 2. 静的解析テスト

### 2-1. flutter analyze

```bash
flutter analyze
```

**期待結果**: エラー 0 件、警告 0 件（既存の警告がある場合はそれ以上増えないこと）

### 2-2. ハードコード色の残存チェック

以下のコマンドで、対象外（`settings_theme.dart` の定義部分、`Colors.transparent`）を除いた `Colors.xxx` の使用がないことを確認:

```bash
# lib/ 配下で Colors. の使用を検索（settings_theme.dart を除外）
grep -rn "Colors\." lib/ \
  --include="*.dart" \
  | grep -v "settings_theme.dart" \
  | grep -v "Colors\.transparent" \
  | grep -v "theme_utils.dart"
```

**期待結果**: 出力なし（全箇所が置換済み）

---

## 3. 既存テスト実行

### 3-1. 全テスト実行

```bash
flutter test
```

**期待結果**: 全テスト通過

### 3-2. 影響範囲の個別テスト（存在する場合）

```bash
# テーマ関連のテストを優先実行
flutter test test/ --name "theme"
flutter test test/ --name "settings"
flutter test test/ --name "color"
```

---

## 4. 目視確認チェックリスト

### 4-1. テーマ別確認

最低3テーマで全対象画面を確認する:

| テーマ | 確認状態 |
|--------|---------|
| pink（デフォルト / ライトモード） | [ ] |
| dark（ダークモード） | [ ] |
| blue（ライトモード / 濃い色） | [ ] |

### 4-2. 画面別チェックリスト

#### カメラ系画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| カメラ画面の背景が黒 | [ ] | [ ] | [ ] |
| カメラ画面のプログレスインジケーターが白 | [ ] | [ ] | [ ] |
| 上部バーのグラデーション（黒→透明） | [ ] | [ ] | [ ] |
| 上部バーのアイコン（閉じる/ギャラリー/ヘルプ）が白 | [ ] | [ ] | [ ] |
| 上部バーのタイトルテキストが白 | [ ] | [ ] | [ ] |
| 撮影ボタンが白、撮影中はグレー | [ ] | [ ] | [ ] |
| 撮影ボタン内アイコンが黒 | [ ] | [ ] | [ ] |
| ズームコントロールのテキスト/アイコンが白 | [ ] | [ ] | [ ] |
| 説明テキストが白（やや透過） | [ ] | [ ] | [ ] |
| カメラガイドラインダイアログの「了解して撮影開始」ボタン | [ ] | [ ] | [ ] |

#### スプラッシュ画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| アプリアイコンの背景が白（やや透過） | [ ] | [ ] | [ ] |
| アプリ名「まいカゴ」が白 | [ ] | [ ] | [ ] |
| サブタイトル「買い物リスト管理アプリ」が白（やや透過） | [ ] | [ ] | [ ] |
| ローディングインジケーターが白（やや透過） | [ ] | [ ] | [ ] |
| ステータステキストが白（やや透過） | [ ] | [ ] | [ ] |

#### 今後の新機能画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| 各機能カードのアイコン色が適切 | [ ] | [ ] | [ ] |
| 「開発中」バッジの色（オレンジ系） | [ ] | [ ] | [ ] |
| 「計画中」バッジの色（ブルー系） | [ ] | [ ] | [ ] |
| カード全体のレイアウトが崩れていない | [ ] | [ ] | [ ] |

#### フォント選択画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| ヘッダーカードの影が適切 | [ ] | [ ] | [ ] |
| 未選択フォントの枠線が適切 | [ ] | [ ] | [ ] |
| 選択中フォントの「選択中」バッジが白文字 | [ ] | [ ] | [ ] |
| 制限中フォントの「制限中」バッジが白文字 | [ ] | [ ] | [ ] |
| 未選択フォントのホバー影が適切 | [ ] | [ ] | [ ] |

#### フォントサイズ選択画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| 選択中プリセットボタンのテキストが白 | [ ] | [ ] | [ ] |

#### テーマ選択画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| ヘッダーカードの影が適切 | [ ] | [ ] | [ ] |

#### 使い方画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| ヘッダーのアイコン/テキストが白 | [ ] | [ ] | [ ] |
| ステップカードの番号バッジが白文字 | [ ] | [ ] | [ ] |
| ステップカードの影が適切 | [ ] | [ ] | [ ] |
| 画面構成カードの説明テキスト色が適切 | [ ] | [ ] | [ ] |
| リスト操作カードのバッジテキストが白文字 | [ ] | [ ] | [ ] |
| カメラ機能カードの影が適切 | [ ] | [ ] | [ ] |

#### その他の画面

| 確認項目 | pink | dark | blue |
|---------|------|------|------|
| ウェルカムダイアログの影が適切 | [ ] | [ ] | [ ] |
| 画像解析プログレスダイアログの影が適切 | [ ] | [ ] | [ ] |
| アップグレードプロモーションの影が適切 | [ ] | [ ] | [ ] |
| メイン画面のドロワーアイテム色が適切 | [ ] | [ ] | [ ] |
| アイテム編集ダイアログの合計テキスト色が適切 | [ ] | [ ] | [ ] |
| ドロワーのデバッグオーバーライドテキスト色が適切 | [ ] | [ ] | [ ] |
| レシピ確認画面のフッター背景/ボタン色が適切 | [ ] | [ ] | [ ] |

---

## 5. エッジケース確認

### 5-1. const 削除の影響

`const` を削除したウィジェットで、Hot Reload が正常に動作することを確認。

### 5-2. カスタムテーマとの互換性

`main_screen.dart` の `customColors` 使用時に、色が正しく適用されることを確認。

### 5-3. AppColors 新定数の値

`AppColors` に追加した定数（`featureBlue`, `featureCyan` 等）が、元の `Colors.xxx` と同じ色値であることを確認:

| 定数名 | 期待される値 | 元の Colors |
|--------|------------|------------|
| `featureBlue` | 0xFF2196F3 | `Colors.blue` |
| `featureCyan` | 0xFF00BCD4 | `Colors.cyan` |
| `featureDeepPurple` | 0xFF673AB7 | `Colors.deepPurple` |
| `featureTeal` | 0xFF009688 | `Colors.teal` |
| `featureIndigo` | 0xFF3F51B5 | `Colors.indigo` |
| `featureAmber` | 0xFFFF9800 | `Colors.amber`(※) |
| `featurePink` | 0xFFE91E63 | `Colors.pink` |
| `featureLightBlue` | 0xFF03A9F4 | `Colors.lightBlue` |
| `featureLightGreen` | 0xFF8BC34A | `Colors.lightGreen` |
| `featureDeepOrange` | 0xFFFF5722 | `Colors.deepOrange` |
| `statusInDevelopment` | 0xFFFF9800 | `Colors.orange`(※) |
| `statusPlanned` | 0xFF2196F3 | `Colors.blue` |
| `cameraBackground` | 0xFF000000 | `Colors.black` |
| `cameraForeground` | 0xFFFFFFFF | `Colors.white` |
| `cameraDisabled` | 0xFF9E9E9E | `Colors.grey` |

(※) `Colors.amber` の primary value は 0xFFFFC107、`Colors.orange` の primary value は 0xFFFF9800。正確な値を使用すること。

---

## 6. リグレッション防止

### 6-1. CI パイプラインでの確認

Codemagic CI で以下が通過することを確認:
- `flutter analyze`
- `flutter test`
- iOS Simulator Test（既存ワークフロー）

### 6-2. PR レビューでの確認ポイント

- 各 `Colors.xxx` → テーマ変数の置換が意味的に正しいか
- `const` の削除が必要最小限か
- `AppColors` の新定数名が既存の命名規則に一致しているか
- ダーク/ライト分岐（三項演算子）がテーマ側に吸収されているか

---

## 7. テスト実行手順

```bash
# 1. 静的解析
flutter analyze

# 2. 全テスト実行
flutter test

# 3. ハードコード色の残存チェック
grep -rn "Colors\." lib/ --include="*.dart" \
  | grep -v "settings_theme.dart" \
  | grep -v "Colors\.transparent" \
  | grep -v "theme_utils.dart"

# 4. ビルド確認（Web）
flutter build web

# 5. 目視確認（デバッグモード起動）
flutter run -d chrome
# または
flutter run -d <device_id>
```
