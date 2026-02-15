# 設計書: Issue #46 Color/fontSize定数の集約

## 方針

### 1. Color定数の集約

**アプローチ: `colorScheme` セマンティックカラー中心 + `AppColors` は画面固有色のみ**

- テーマ依存色（テキスト色、背景色、カード色等）→ `Theme.of(context).colorScheme` で取得
- 画面固有の装飾色（ウェルカムダイアログのパステル色等）→ `AppColors` に定数定義

**`AppColors` の整理:**

```dart
class AppColors {
  // === 装飾・ブランド色（テーマ非依存） ===
  static const Color pastelPink = Color(0xFFFFB6C1);
  static const Color pastelGreen = Color(0xFF90EE90);
  static const Color pastelBlue = Color(0xFF87CEEB);
  static const Color mintGreen = Color(0xFFB5EAD7);

  // === プレミアム画面用 ===
  static const Color premiumTitle = Color(0xFF2C3E50);
  static const Color premiumSubtext = Color(0xFF7F8C8D);
  // ... 必要な定数を整理
}
```

**置換しない箇所:**
- `settings_theme.dart` のテーマ定義 switch 文内（一次ソースとして許容）
- `getAvailableThemes()` のプレビュー色

### 2. fontSize定数の集約

**アプローチ: `textTheme` 活用 + 画面固有サイズは定数クラスで管理**

`settings_font.dart` で既に以下のマッピングが定義済み:

| textTheme | サイズ (base=16) |
|-----------|-----------------|
| displayLarge | 26 |
| displayMedium | 22 |
| displaySmall | 18 |
| headlineLarge | 20 |
| headlineMedium | 18 |
| headlineSmall | 16 |
| titleLarge | 16 |
| titleMedium | 14 |
| titleSmall | 12 |
| bodyLarge | 16 |
| bodyMedium | 14 |
| bodySmall | 12 |
| labelLarge | 14 |
| labelMedium | 12 |
| labelSmall | 10 |

**置換マッピング例:**
- `fontSize: 22` → `Theme.of(context).textTheme.displayMedium`
- `fontSize: 18` → `Theme.of(context).textTheme.displaySmall` / `headlineMedium`
- `fontSize: 16` → `Theme.of(context).textTheme.bodyLarge`
- `fontSize: 14` → `Theme.of(context).textTheme.bodyMedium`
- `fontSize: 12` → `Theme.of(context).textTheme.bodySmall`
- `fontSize: 10` → `Theme.of(context).textTheme.labelSmall`

**textTheme にマッピングできないサイズ（24, 28, 32, 36 等）:**
- プレミアム画面等の特殊 UI 用。`textTheme` の fontSize をベースに相対計算するか、定数として管理

### 3. AdMob IDの環境変数移行

**変更前 (`config.dart`):**
```dart
const String _productionInterstitialAdUnitId = 'ca-app-pub-8931010669383801/4047702359';
// defaultValue が本番ID
const String adInterstitialUnitId = String.fromEnvironment(
  'ADMOB_INTERSTITIAL_AD_UNIT_ID',
  defaultValue: _productionInterstitialAdUnitId,
);
```

**変更後:**
```dart
// テスト用ID (Google公式)
const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
const String _testAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';

const String adInterstitialUnitId = String.fromEnvironment(
  'ADMOB_INTERSTITIAL_AD_UNIT_ID',
  defaultValue: _testInterstitialAdUnitId,
);
```

本番 ID は `env.json` に移行し、CI/CD の `--dart-define` で注入。

## 影響範囲

### Color置換対象（主要ファイル）

| ファイル | 箇所数 | 内容 |
|---------|--------|------|
| `maikago_premium.dart` | 13+ | 画面固有色 → `AppColors` 定数化 |
| `main_screen.dart` | 5 | `customColors` マップ → 削除/`colorScheme` 参照 |
| `welcome_dialog.dart` | 3+ | パステル色 → `AppColors` 定数化 |
| `about_screen.dart` | 7 | 装飾色 → `AppColors` or `colorScheme` |
| その他ウィジェット | 多数 | 個別対応 |

### fontSize置換対象（主要ファイル）

| ファイル | 箇所数 |
|---------|--------|
| `maikago_premium.dart` | 20+ |
| `calculator_screen.dart` | 10+ |
| `main_screen.dart` | 5+ |
| その他 | 多数 |
