# 設計書

## 実装方針

### 変更対象ファイル
- `lib/main.dart:205,213` - `void` → `Future<void>`
- `lib/services/vision_ocr_service.dart:167` - `catch (_)` にログ追加
- その他Grepで見つかるファイル

### 修正パターン

**Before:**
```dart
void _checkForUpdatesInBackground() async {
```

**After:**
```dart
Future<void> _checkForUpdatesInBackground() async {
```

**Before:**
```dart
} catch (_) {
  // 何もしない
}
```

**After:**
```dart
} catch (e) {
  debugPrint('画像前処理エラー: $e');
}
```

## 影響範囲
- 戻り値型の変更は呼び出し元に影響しない（`unawaited`呼び出しの場合）
- `catch`の変更は動作に影響しない（ログ追加のみ）

## Flutter固有の注意点
- `DebugService`を使用してログ出力を統一（configEnableDebugModeに依存）
