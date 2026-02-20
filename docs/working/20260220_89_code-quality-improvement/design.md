# 設計書 — Issue #89: コード品質改善

## 1. カメラ画面統合（H-1）

### 現状

| ファイル | 行数 | 使用状況 |
|---------|------|---------|
| `camera_screen.dart` | 432行 | 未使用（router.dartに参照なし） |
| `enhanced_camera_screen.dart` | 522行 | router.dartで使用中 |

重複度: 95%以上。共通: カメラ初期化、撮影、ガイドライン、ズーム、ライフサイクル管理。

### 設計方針

- `EnhancedCameraScreen` をベースに統一（UI構造が分割済みで保守性が高い）
- `camera_screen.dart` を削除 → `enhanced_camera_screen.dart` を `camera_screen.dart` にリネーム
- クラス名 `EnhancedCameraScreen` → `CameraScreen` に変更

### 変更ファイル

- `lib/screens/camera_screen.dart` — 削除
- `lib/screens/enhanced_camera_screen.dart` — リネーム＋クラス名変更
- `lib/router.dart` — import パス更新

---

## 2. ハードコードバージョン修正（H-2）

### 現状

| ファイル | 行 | 値 | 正しい値 |
|---------|---|---|---------|
| `version_notification_service.dart` | 46 | `'1.2.0'` | `'1.3.1'` |
| `release_history_screen.dart` | 43 | `'1.1.6'` | `'1.3.1'` |

### 設計方針

各ファイル内でフォールバック定数を定義し、現行バージョン `1.3.1` と同期。

---

## 3. settings_persistence 共通化（M-1）

### 現状

421行、29個のstaticメソッド。20+の同一パターンが反復。

### 設計方針

ジェネリックプライベートヘルパー2メソッドで共通化:

```dart
static Future<void> _save(String key, dynamic value, String caller) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    else if (value is int) await prefs.setInt(key, value);
    else if (value is double) await prefs.setDouble(key, value);
    else if (value is bool) await prefs.setBool(key, value);
  } catch (e) {
    DebugService().log('$caller エラー: $e');
  }
}

static Future<T> _load<T>(String key, T defaultValue, String caller) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(key);
    if (value is T) return value;
    return defaultValue;
  } catch (e) {
    DebugService().log('$caller エラー: $e');
    return defaultValue;
  }
}
```

### 対象メソッド

**保存（4個）**: saveTheme, saveFont, saveFontSize, saveDefaultShopDeleted
**読み込み（6個）**: loadTheme, loadFont, loadFontSize, loadDefaultShopDeleted, loadAutoComplete, loadStrikethrough
**タブ別（4個）**: saveTabBudget, loadTabBudget, saveTabTotal, loadTabTotal

---

## 4. エラーハンドリング修正（M-2）

### 各箇所の修正方針

| ファイル | 行 | 現状 | 修正 |
|---------|---|------|------|
| `main_screen.dart` | 178 | `catch (_) {}` | `DebugService().log()` 追加 |
| `main_screen.dart` | 248 | コメントのみ | `DebugService().log()` 追加 |
| `data_service.dart` | 603 | コメントのみ | `DebugService().log()` 追加 |
| `shared_group_icons.dart` | 80-82 | catch→return null | ログ追加 |
| `version_notification_service.dart` | 62 | コメントのみ | `DebugService().log()` 追加 |

---

## 5. donation_screen switch文統一（M-3）

### 現状

2つのswitch文（`_getAmountFromProductId` / `_getProductIdFromAmount`）が逆引き関係。

### 設計方針

Map定数を定義し、switch文を置換:

```dart
static const Map<String, int> _productIdToAmount = {
  'donation_300': 300,
  'donation_500': 500,
  'donation_1000': 1000,
  'donation_2000': 2000,
  'donation_5000': 5000,
  'donation_10000': 10000,
};

static final Map<int, String> _amountToProductId =
    _productIdToAmount.map((k, v) => MapEntry(v, k));
```

### 変更ファイル

- `lib/screens/drawer/donation_screen.dart`
