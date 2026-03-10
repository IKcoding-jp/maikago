# ログレベル導入 & 不要ログ削除 実装計画

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** DebugServiceにログレベルを導入し、デフォルトで重要なログのみ表示。不要なログは削除。

**Architecture:** config.dartの`--dart-define`でビルド時にログレベルを制御。DebugServiceにLogLevel enumとフィルタリングを追加。既存の`log()`はdebugレベル（デフォルト非表示）、新規`logInfo()`でinfoレベル（デフォルト表示）。

**Tech Stack:** Flutter/Dart, DebugService singleton

---

### Task 1: config.dart にログレベル設定を追加

**Files:**
- Modify: `lib/config.dart`

**Step 1: ログレベル設定を追加**

`configEnableDebugMode` の直後に追加:

```dart
/// ログ出力レベル（verbose, debug, info, warning, error）
/// デフォルト: info（info以上を表示）
/// 詳細ログが必要な場合: --dart-define=MAIKAGO_LOG_LEVEL=debug
const String configLogLevel = String.fromEnvironment(
  'MAIKAGO_LOG_LEVEL',
  defaultValue: 'info',
);
```

**Step 2: コミット**

```bash
git add lib/config.dart
git commit -m "feat(config): ログレベル設定を追加"
```

---

### Task 2: DebugService にログレベルフィルタリングを導入

**Files:**
- Modify: `lib/services/debug_service.dart`

**Step 1: LogLevel enumを追加し、DebugServiceを書き換え**

```dart
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';

/// ログ出力レベル（低い方がより詳細）
enum LogLevel {
  verbose, // 最も詳細（ソート比較、キャッシュ操作等）
  debug,   // デバッグ情報（初期化ステップ、CRUD操作等）
  info,    // 重要な状態変更（認証、データロード完了等）
  warning, // 警告
  error,   // エラー
}

/// デバッグ機能を提供するサービス
/// kDebugModeガードにより、リリースビルドではログ出力を完全に抑制
/// ログレベルにより、デバッグビルドでも出力量を制御可能
class DebugService {
  factory DebugService() => _instance;
  DebugService._internal();

  static final DebugService _instance = DebugService._internal();

  /// configLogLevel文字列からLogLevelに変換
  static final LogLevel _minLevel = _parseLogLevel(configLogLevel);

  static LogLevel _parseLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'verbose':
        return LogLevel.verbose;
      case 'debug':
        return LogLevel.debug;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  /// 指定レベルが現在の最小レベル以上かどうか
  bool _shouldLog(LogLevel level) => level.index >= _minLevel.index;

  /// デバッグモードが有効かどうか
  bool get isDebugMode => kDebugMode;

  /// 本番環境かどうか
  bool get isProductionMode => kReleaseMode;

  /// 製品版リリース用のデバッグログ制御
  bool get enableDebugMode =>
      isDebugMode && !isProductionMode && configEnableDebugMode;

  /// デバッグレベルのログ出力（デフォルトでは非表示）
  /// 既存のlog()呼び出しはすべてこのレベル
  void log(String message) {
    if (kDebugMode && _shouldLog(LogLevel.debug)) {
      debugPrint(message);
    }
  }

  /// 情報レベルのログ出力（デフォルトで表示）
  /// 重要な状態変更（認証、データロード完了等）に使用
  void logInfo(String message) {
    if (kDebugMode && _shouldLog(LogLevel.info)) {
      debugPrint(message);
    }
  }

  /// デバッグ情報を出力（debugレベル）
  void logDebug(String message) {
    if (kDebugMode && _shouldLog(LogLevel.debug)) {
      debugPrint('🔍 DEBUG: $message');
    }
  }

  /// 警告情報を出力（warningレベル）
  void logWarning(String message) {
    if (kDebugMode && _shouldLog(LogLevel.warning)) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// エラー情報を出力（errorレベル）
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode && _shouldLog(LogLevel.error)) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('エラー詳細: $error');
      }
      if (stackTrace != null) {
        debugPrint('スタックトレース: $stackTrace');
      }
    }
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isDebugMode': isDebugMode,
      'isProductionMode': isProductionMode,
      'logLevel': _minLevel.name,
      'enableDebugMode': enableDebugMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// デバッグ機能が利用可能かどうか
  bool get isDebugEnabled => enableDebugMode;
}
```

変更点:
- `LogLevel` enum追加
- `_minLevel`と`_shouldLog()`でフィルタリング
- `logInfo()`新規追加
- 未使用の`logPerformance()`、`logIf()`、`isProfileMode`を削除
- `getDebugInfo()`にlogLevelを追加

**Step 2: コミット**

```bash
git add lib/services/debug_service.dart
git commit -m "feat(debug): ログレベルフィルタリングを導入"
```

---

### Task 3: main.dart のログ整理

**Files:**
- Modify: `lib/main.dart`

**変更内容:**
- 起動開始/完了のログ → 削除（毎回の冗長なステップ）
- プラットフォーム情報 → 削除
- Flutterエンジン初期化完了 → 削除
- Firebase初期化成功 → 削除
- Firestoreキャッシュ設定完了 → 削除
- Google Mobile Ads初期化開始/完了 → 削除
- エラーログ → `logError`のまま維持

**Step 1: main.dartのログを整理**

```dart
// 削除: DebugService().logDebug('🚀 アプリ起動開始');
// 削除: DebugService().logDebug('📱 プラットフォーム: Web');
// 削除: DebugService().logDebug('📱 プラットフォーム: ${Platform.operatingSystem}');
// 削除: DebugService().logDebug('✅ Flutterエンジン初期化完了');
// 削除: DebugService().logDebug('✅ Firebase初期化成功');
// 削除: DebugService().logDebug('✅ Firestoreオフラインキャッシュ設定完了');
// 削除: DebugService().logDebug('🔧 Google Mobile Ads初期化開始');
// 削除: DebugService().logDebug('✅ Google Mobile Ads初期化完了');
// 維持: DebugService().logError(...) はすべて維持
```

**Step 2: コミット**

---

### Task 4: auth_provider.dart のログ整理

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**変更内容:**
- エラーログ（❌） → `logError`に変更
- 警告ログ（⚠️） → `logWarning`に変更
- 初期化開始/完了 → 削除
- ユーザー状態の詳細出力 → 削除
- サービス初期化完了 → 削除
- 認証状態変更 → `logInfo`（1行に集約）
- ゲストデータマイグレーション → `logInfo`（開始のみ、完了は削除）

---

### Task 5: auth_service.dart のログ整理

**Files:**
- Modify: `lib/services/auth_service.dart`

**変更内容:**
- GoogleSignIn初期化 → 削除
- リダイレクト認証結果の詳細 → 削除
- プラットフォーム判定ログ → 削除
- サインイン開始ログ → 削除
- サインイン成功 → `logInfo`
- ログアウト完了 → `logInfo`
- エラーログ → `logError`に変更
- 警告（CLIENT_ID未設定等） → `logWarning`に変更

---

### Task 6: data_provider.dart のログ整理

**Files:**
- Modify: `lib/providers/data_provider.dart`

**変更内容:**
- 初期化完了のログ → 削除
- デバッグモード限定の詳細ログ → 削除
- 認証状態変更（ログイン/ゲスト/ログアウト検出） → `logInfo`
- データ読み込み完了統計 → `logInfo`
- loadData開始・現在状態ログ → 削除
- マイグレーション開始 → `logInfo`、詳細ステップ → 削除
- データクリア → 削除
- エラーログ → `logError`
- 税率保存無効化 → `logWarning`

---

### Task 7: data_cache_manager.dart のログ整理

**Files:**
- Modify: `lib/providers/managers/data_cache_manager.dart`

**変更内容:**
- 初期化時の状態ログ → 削除
- Firebase読み込み/タイムアウト/ローカルモード判定 → 削除
- データ読み込み完了統計 → `logInfo`
- エラーログ → `logError`

---

### Task 8: realtime_sync_manager.dart のログ整理

**Files:**
- Modify: `lib/providers/managers/realtime_sync_manager.dart`

**変更内容:**
- 同期開始/停止の汎用ログ → 削除
- ストリーム受信時の件数ログ → 削除
- ストリーム終了ログ → 削除
- サブスクリプション停止のログ → 削除
- リアルタイム同期停止完了 → 削除
- リアルタイム同期開始完了 → `logInfo`
- リトライ関連 → `logWarning`
- エラーログ → `logError`

---

### Task 9: one_time_purchase_service.dart のログ整理（最多61箇所）

**Files:**
- Modify: `lib/services/one_time_purchase_service.dart`

**変更内容:**
- デバイスフィンガープリント生成の詳細 → 削除
- IAP初期化時のプラットフォーム判定/ストリーム詳細 → 削除
- 商品情報取得の詳細（各商品の価格） → 削除
- 購入更新の詳細 → 削除
- 購入復元時の詳細 → 削除
- ローカルストレージ読み込み/保存完了 → 削除
- Firebase初期化/利用可能性チェック → 削除
- 体験期間タイマー詳細 → 削除
- 初期化開始/完了 → `logInfo`
- 体験期間の開始/終了 → `logInfo`
- エラーログ → `logError`
- 二重開始チェック → `logWarning`

---

### Task 10: data_service.dart のログ整理

**Files:**
- Modify: `lib/services/data_service.dart`

**変更内容:**
- Firebase利用可能性チェック/スキップログ（大量） → 削除
- タイムアウト/件数ログ → 削除
- エラーログ → `logError`

---

### Task 11: donation_service.dart のログ整理

**Files:**
- Modify: `lib/services/donation_service.dart`

**変更内容:**
- 初期化済み/開始/完了のログ → 削除
- CRUD操作ログ → 削除
- ローカルストレージ読み込み/保存完了 → 削除
- Firestore読み込み/保存完了 → 削除
- アカウント切り替え検知 → `logInfo`
- エラーログ → `logError`

---

### Task 12: shop_repository.dart のログ整理

**Files:**
- Modify: `lib/providers/repositories/shop_repository.dart`

**変更内容:**
- ショップ追加/更新/削除のログ → 削除
- 共有タブ削除処理の詳細 → 削除
- Firestore保存処理の詳細 → 削除
- エラーログ → `logError`

---

### Task 13: 残りファイルのログ整理（バッチ）

**Files:**
- Modify: `lib/services/cloud_functions_service.dart`
- Modify: `lib/services/vision_ocr_service.dart`
- Modify: `lib/services/hybrid_ocr_service.dart`
- Modify: `lib/utils/responsive_utils.dart`
- Modify: `lib/models/sort_mode.dart`
- Modify: `lib/screens/camera_screen.dart`
- Modify: `lib/services/camera_service.dart`
- Modify: `lib/providers/repositories/item_repository.dart`
- Modify: `lib/providers/managers/shared_group_manager.dart`
- Modify: `lib/services/settings_persistence.dart`
- Modify: `lib/services/product_name_summarizer_service.dart`
- Modify: `lib/services/shared_group_service.dart`
- Modify: `lib/screens/login_screen.dart`
- Modify: `lib/screens/main_screen.dart`
- Modify: `lib/screens/main/utils/startup_helpers.dart`
- Modify: `lib/screens/main/utils/item_operations.dart`
- Modify: `lib/screens/main/dialogs/sort_dialog.dart`
- Modify: `lib/screens/drawer/donation_screen.dart`
- Modify: `lib/screens/main/widgets/bottom_summary_widget.dart`
- Modify: `lib/screens/drawer/settings/advanced_settings_screen.dart`
- Modify: `lib/services/app_info_service.dart`
- Modify: `lib/services/ad/ad_banner.dart`
- Modify: `lib/screens/main/widgets/main_drawer.dart`

**方針:**
- 正常系のトレースログ → 削除
- エラーログ → `logError`に変更（既に`log()`で❌を含むもの）
- 警告ログ → `logWarning`に変更（既に`log()`で⚠️を含むもの）
- `log()`のまま残すもの → debugレベルとして自動的にフィルタリング
- sort_mode.dartのソート比較ログ → 完全削除（毎ソート実行で大量出力）
- responsive_utils.dartのデバイス情報 → `log()`のまま（printDeviceInfoメソッド自体が明示的呼び出し）

---

### Task 14: 静的解析 & テスト実行

**Step 1: flutter analyze**

```bash
flutter analyze
```

未使用importやlint警告がないことを確認。

**Step 2: flutter test**

```bash
flutter test
```

既存テストがすべてパスすることを確認。

**Step 3: コミット**

```bash
git commit -m "refactor(logging): ログレベル導入と不要ログの削除"
```

---

## 変更の概要

| 項目 | 数値 |
|------|------|
| 変更ファイル数 | ~35 |
| 削除されるログ | ~250-300箇所 |
| logInfo に昇格 | ~15-20箇所 |
| logError に変更 | ~40-50箇所 |
| logWarning に変更 | ~10-15箇所 |
| log() のまま残る | ~50-80箇所（debugレベルとして非表示） |

## デフォルト動作の変化

**変更前:** 起動時60行以上のログ
**変更後:** デフォルト（info）で5-10行程度

詳細ログが必要な場合: `--dart-define=MAIKAGO_LOG_LEVEL=debug`
