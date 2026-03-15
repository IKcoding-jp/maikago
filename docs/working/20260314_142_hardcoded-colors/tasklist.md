# タスクリスト: ハードコード色をテーマ変数に置換

## Issue

- **Issue番号**: #142
- **ステータス**: 完了
- **完了日**: 2026-03-15
- **作成日**: 2026-03-14

---

## フェーズ1: 基盤整備（AppColors / ThemeUtils 拡張）

### 1-1. AppColors に不足している色定数を追加

- [ ] `AppColors` にカメラUI用定数を追加（`cameraBackground`, `cameraForeground` 等）
- [ ] `AppColors` に upcoming_features_screen 用の装飾色定数を追加（`featureBlue`, `featureCyan`, `featureDeepPurple`, `featureAmber`, `featurePink`, `featureLightBlue`, `featureLightGreen`, `featureDeepOrange`, `featureTeal`, `featureIndigo`）
- [ ] `AppColors` にステータス色定数を追加（`statusInDevelopment`, `statusPlanned` 等）

### 1-2. ThemeUtils 拡張の確認・追加

- [ ] `theme_utils.dart` の `cardShadowColor` が全ファイルで利用可能か確認
- [ ] 必要に応じて `onPrimaryColor` 等の便利プロパティを追加検討

---

## フェーズ2: テーマ生成ロジック内の整理（settings_theme.dart）

### 2-1. SettingsTheme ヘルパーメソッドの整理

- [ ] `getContrastColor()` (L295): `Colors.black` / `Colors.white` → テーマ生成ロジック内なので許容するか判断。許容する場合はコメントで意図を明記
- [ ] `getOnPrimaryColor()` (L300): `Colors.white` → 許容（テーマ定義の一部）
- [ ] `getTextColor()` (L305): `Colors.white` / `Colors.black87` → 許容（テーマ定義の一部）
- [ ] `getSubtextColor()` (L310): `Colors.white70` / `Colors.black54` → 許容（テーマ定義の一部）
- [ ] `getCardColor()` (L315): `Colors.white` → 許容（テーマ定義の一部）
- [ ] `getSurfaceColor()` (L320): `Colors.transparent` → 対象外
- [ ] `_getBackgroundColor()` (L229): `Colors.white` → 許容（テーマ定義の一部）
- [ ] `generateTheme()` 内の全 `Colors` 使用を確認し、テーマ生成ロジックとして許容するものにコメント付与

### 2-2. AppColors 定数クラスの Colors 使用

- [ ] `AppColors.onPrimary` (L9): `Colors.white` → テーマ定数定義として許容
- [ ] `AppColors.textPrimary` (L26): `Colors.black87` → テーマ定数定義として許容
- [ ] `AppColors.textSecondary` (L27): `Colors.black54` → テーマ定数定義として許容
- [ ] `AppColors.textDisabled` (L28): `Colors.black38` → テーマ定数定義として許容

---

## フェーズ3: カメラ系画面の置換（8ファイル・30箇所）

### 3-1. camera_screen.dart（3箇所）

- [ ] L288: `Colors.black` → `AppColors.cameraBackground` または コメント付きで維持
- [ ] L310: `Colors.white` → `AppColors.cameraForeground` または `colorScheme.onPrimary`
- [ ] L321: `Colors.white` → 同上

### 3-2. camera_top_bar.dart（6箇所）

- [ ] L39: `Colors.black.withValues(alpha: 0.7)` → `AppColors.cameraBackground.withValues(alpha: 0.7)` またはグラデーション用定数
- [ ] L40: `Colors.transparent` → 対象外
- [ ] L48: `Colors.white` → `AppColors.cameraForeground`
- [ ] L55: `Colors.white` → `AppColors.cameraForeground`
- [ ] L65: `Colors.white` → `AppColors.cameraForeground`
- [ ] L70: `Colors.white` → `AppColors.cameraForeground`

### 3-3. camera_bottom_controls.dart（14箇所）

- [ ] L46: `Colors.transparent` → 対象外
- [ ] L47: `Colors.black.withValues(alpha: 0.7)` → `AppColors.cameraBackground.withValues(alpha: 0.7)`
- [ ] L79: `Colors.grey` / `Colors.white` → `Colors.grey` は `AppColors.cameraDisabled`, `Colors.white` は `AppColors.cameraForeground`
- [ ] L80: `Colors.white` → `AppColors.cameraForeground`
- [ ] L83: `Colors.black` → `AppColors.cameraBackground`
- [ ] L84: `Colors.black` → `AppColors.cameraBackground`
- [ ] L95: `Colors.white70` → `AppColors.cameraForeground.withValues(alpha: 0.7)` またはサブテキスト用定数
- [ ] L106: `Colors.black.withValues(alpha: 0.5)` → `AppColors.cameraBackground.withValues(alpha: 0.5)`
- [ ] L116: `Colors.white` → `AppColors.cameraForeground`
- [ ] L121: `Colors.transparent` → 対象外
- [ ] L128: `Colors.white.withValues(alpha: 0.2)` → `AppColors.cameraForeground.withValues(alpha: 0.2)`
- [ ] L134: `Colors.white` → `AppColors.cameraForeground`
- [ ] L144: `Colors.white` → `AppColors.cameraForeground`
- [ ] L149: `Colors.transparent` → 対象外

---

## フェーズ4: スプラッシュ画面の置換（splash_screen.dart・7箇所）

- [ ] L152: `Colors.white.withValues(alpha: 0.9)` → `colorScheme.onPrimary.withValues(alpha: 0.9)`
- [ ] L156: `Colors.black.withValues(alpha: 0.1)` → `theme.cardShadowColor`
- [ ] L175: `Colors.white` → `colorScheme.onPrimary`
- [ ] L184: `Colors.white.withValues(alpha: 0.8)` → `colorScheme.onPrimary.withValues(alpha: 0.8)`
- [ ] L194: `Colors.white.withValues(alpha: 0.8)` → `colorScheme.onPrimary.withValues(alpha: 0.8)`
- [ ] L206: `Colors.white.withValues(alpha: 0.7)` → `colorScheme.onPrimary.withValues(alpha: 0.7)`
- [ ] L214: `Colors.white.withValues(alpha: 0.7)` → `colorScheme.onPrimary.withValues(alpha: 0.7)`

---

## フェーズ5: upcoming_features_screen.dart の置換（15箇所）

- [ ] L80: `Colors.blue` → `AppColors.featureBlue`（新規定義）
- [ ] L87: `Colors.green` → `AppColors.featureMaterialGreen`（既存）
- [ ] L95: `Colors.cyan` → `AppColors.featureCyan`（新規定義）
- [ ] L102: `Colors.deepPurple` → `AppColors.featureDeepPurple`（新規定義）
- [ ] L109: `Colors.purple` → `AppColors.featurePurple`（既存）
- [ ] L116: `Colors.red` → `AppColors.featureRed`（既存）
- [ ] L123: `Colors.teal` → `AppColors.featureTeal`（新規定義）
- [ ] L130: `Colors.indigo` → `AppColors.featureIndigo`（新規定義）
- [ ] L137: `Colors.amber` → `AppColors.featureAmber`（新規定義）
- [ ] L144: `Colors.pink` → `AppColors.featurePink`（新規定義）
- [ ] L151: `Colors.lightBlue` → `AppColors.featureLightBlue`（新規定義）
- [ ] L158: `Colors.lightGreen` → `AppColors.featureLightGreen`（新規定義）
- [ ] L165: `Colors.deepOrange` → `AppColors.featureDeepOrange`（新規定義）
- [ ] L187: `Colors.orange` → `AppColors.statusInDevelopment`（新規定義）
- [ ] L187: `Colors.blue` → `AppColors.statusPlanned`（新規定義）

---

## フェーズ6: 設定系画面の置換

### 6-1. font_select_screen.dart（8箇所）

- [ ] L110: `Colors.black.withValues(alpha: 0.05)` → `theme.cardShadowColor`（または `colorScheme.shadow.withValues(alpha: 0.05)`）
- [ ] L239: `Colors.grey.withValues(alpha: 0.31)` → `colorScheme.outline.withValues(alpha: 0.31)`
- [ ] L252: `Colors.black.withValues(alpha: 0.03)` → `theme.cardShadowColor`
- [ ] L259: `Colors.transparent` → 対象外
- [ ] L292: `Colors.white` → `colorScheme.onPrimary`
- [ ] L297: `Colors.white` → `colorScheme.onPrimary`
- [ ] L312: `Colors.grey` → `colorScheme.outline` または `colorScheme.onSurface.withValues(alpha: 0.38)`
- [ ] L318: `Colors.white` → `colorScheme.onPrimary`
- [ ] L323: `Colors.white` → `colorScheme.onPrimary`

### 6-2. font_size_select_screen.dart（1箇所）

- [ ] L176: `Colors.white` → `colorScheme.onPrimary`

### 6-3. theme_select_screen.dart（1箇所）

- [ ] L93: `Colors.black.withValues(alpha: 0.05)` → `theme.cardShadowColor`

---

## フェーズ7: 使い方画面系の置換

### 7-1. usage_header.dart（3箇所）

- [ ] L26: `Colors.white` → `colorScheme.onPrimary`
- [ ] L33: `Colors.white` → `colorScheme.onPrimary`
- [ ] L42: `Colors.white` → `colorScheme.onPrimary`

### 7-2. usage_step_card.dart（2箇所）

- [ ] L30: `Colors.black.withValues(alpha: 0.1)` → `theme.cardShadowColor`
- [ ] L71: `Colors.white` → `colorScheme.onPrimary`

### 7-3. usage_screen_explanation_card.dart（2箇所）

- [ ] L16: `Colors.black.withValues(alpha: 0.1)` → `theme.cardShadowColor`
- [ ] L110: `Colors.grey[600]` → `theme.subtextColor`（ThemeUtils拡張）

### 7-4. usage_list_operation_card.dart（2箇所）

- [ ] L17: `Colors.black.withValues(alpha: 0.1)` → `theme.cardShadowColor`
- [ ] L127: `Colors.white` → `colorScheme.onPrimary`

### 7-5. usage_camera_feature_card.dart（1箇所）

- [ ] L17: `Colors.black.withValues(alpha: 0.1)` → `theme.cardShadowColor`

---

## フェーズ8: その他画面の置換

### 8-1. welcome_dialog.dart（2箇所）

- [ ] L123: `Colors.transparent` → 対象外
- [ ] L143: `Colors.black.withValues(alpha: 0.15)` → `theme.cardShadowColor`

### 8-2. image_analysis_progress_dialog.dart（1箇所）

- [ ] L108: `Colors.black.withValues(alpha: 0.1)` → `theme.cardShadowColor`

### 8-3. camera_guidelines_dialog.dart（1箇所）

- [ ] L206: `Colors.white` → `colorScheme.onPrimary`

### 8-4. upgrade_promotion_widget.dart（1箇所）

- [ ] L64: `Colors.black.withValues(alpha: 0.1)` → `theme.cardShadowColor`

### 8-5. main_screen.dart（2箇所）

- [ ] L440: `Colors.white` → `colorScheme.onPrimary`（ダークモード時のドロワー色）
- [ ] L443: `Colors.white` → `colorScheme.onPrimary`（ダークモード時のドロワーテキスト色）

### 8-6. item_edit_dialog.dart（2箇所）

- [ ] L227: `Colors.white`（ダーク分岐）→ `colorScheme.onSurface`
- [ ] L236: `Colors.white`（ダーク分岐）→ `colorScheme.onSurface`

### 8-7. main_drawer.dart（1箇所）

- [ ] L187: `Colors.orange.shade700` → `AppColors.warning` または専用定数

### 8-8. recipe_confirm_screen.dart（3箇所）

- [ ] L410: `Colors.white` → `theme.cardColor`
- [ ] L413: `Colors.black.withValues(alpha: 0.05)` → `theme.cardShadowColor`
- [ ] L439: `Colors.white` → `colorScheme.onPrimary`

### 8-9. release_history_screen.dart（4箇所）

- [ ] L187: `Colors.transparent` → 対象外
- [ ] L195: `Colors.transparent` → 対象外
- [ ] L206: `Colors.transparent` → 対象外
- [ ] L273: `Colors.transparent` → 対象外

### 8-10. theme_utils.dart（2箇所）

- [ ] L7: `Colors.black.withValues(alpha: 0.3)` → テーマユーティリティの定義自体なので許容。コメント付与
- [ ] L8: `Colors.black.withValues(alpha: 0.1)` → 同上

---

## フェーズ9: 検証

- [ ] `flutter analyze` エラーなし確認
- [ ] `flutter test` 全テスト通過確認
- [ ] ライトモード（pink テーマ）で全対象画面の目視確認
- [ ] ダークモード（dark テーマ）で全対象画面の目視確認
- [ ] その他2テーマ（blue, lavender 等）でスポット確認
- [ ] PR 作成・レビュー依頼

---

## 集計

| フェーズ | 対象箇所数 | 対象外(transparent等) | 実置換数 |
|---------|-----------|---------------------|---------|
| 1. 基盤整備 | - | - | - |
| 2. テーマ生成ロジック | 20 | 20（許容） | 0 |
| 3. カメラ系 | 23 | 5（transparent） | 18 |
| 4. スプラッシュ | 7 | 0 | 7 |
| 5. 新機能画面 | 15 | 0 | 15 |
| 6. 設定系 | 10 | 1（transparent） | 9 |
| 7. 使い方系 | 10 | 0 | 10 |
| 8. その他 | 16 | 4（transparent） | 12 |
| 9. 検証 | - | - | - |
| **合計** | **101** | **30** | **71** |

※ テーマ生成ロジック（`settings_theme.dart` の `generateTheme()` / ヘルパーメソッド / `AppColors` 定数定義）は色定義の源であるため「許容」扱い。
