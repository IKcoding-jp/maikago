# まいカゴ 成長・収益化改善 実装計画

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** フリーミアム再設計・初回体験改善・広告戦略変更により、インストール数と課金率を向上させる

**Architecture:** 既存のProvider + FeatureAccessControl パターンを拡張。ゲストモードはAuthProviderに状態追加、機能制限はFeatureAccessControlに集約。広告はバナーのみ残しインタースティシャル/アプリオープン広告を廃止。

**Tech Stack:** Flutter, Provider, Firebase Auth/Firestore, SharedPreferences, google_mobile_ads, in_app_purchase

**設計書:** `docs/plans/2026-03-10-growth-and-monetization-design.md`

---

## Phase 1A: 広告戦略の変更（最も独立性が高く、即効性あり）

### Task 1: インタースティシャル広告の廃止 (Issue #111)

**Files:**
- Modify: `lib/screens/main_screen.dart`
- Modify: `lib/main.dart`
- Delete: `lib/services/ad/interstitial_ad_service.dart`

**Step 1: main_screen.dart からインタースティシャル広告の呼び出しを全削除**

`lib/screens/main_screen.dart` から以下を削除:
- 行8: `import 'package:maikago/services/ad/interstitial_ad_service.dart';` を削除
- 行52: `InterstitialAdService? _interstitialAdService;` フィールドを削除
- 行71, 95, 112, 134, 289: `await _showInterstitialAdSafely();` / `_showInterstitialAdSafely` の呼び出しを全て削除
- 行139-149: `_showInterstitialAdSafely()` メソッド定義を全削除
- 行175-180付近: initState内の `_interstitialAdService` 初期化を削除
- 行206: dispose内の `_interstitialAdService?.dispose();` を削除

**Step 2: main.dart からインタースティシャル広告のProvider登録を削除**

`lib/main.dart` から以下を削除:
- 行19: `import 'package:maikago/services/ad/interstitial_ad_service.dart';` を削除
- 行57-62付近: `InterstitialAdService` インスタンス作成を削除
- 行94-95付近: `MyApp` への `interstitialAdService` 引数渡しを削除
- 行241-245付近: MultiProvider内の `InterstitialAdService` Provider登録を削除

**Step 3: interstitial_ad_service.dart を削除**

`lib/services/ad/interstitial_ad_service.dart` をファイルごと削除。

**Step 4: ビルド確認**

Run: `flutter analyze`
Expected: エラーなし

Run: `flutter test`
Expected: テスト通過（インタースティシャル広告に依存するテストがあれば修正）

**Step 5: コミット**

```bash
git add -A
git commit -m "feat: インタースティシャル広告を廃止（UX改善）

3操作ごとの全画面広告を廃止し、バナー広告のみに変更。
ユーザー体験を大幅に改善する。

Refs: #111"
```

---

### Task 2: アプリオープン広告の廃止 (Issue #111)

**Files:**
- Modify: `lib/main.dart`
- Delete: `lib/services/ad/app_open_ad_service.dart`

**Step 1: main.dart からアプリオープン広告の初期化・表示を全削除**

`lib/main.dart` から以下を削除:
- 行18: `import 'package:maikago/services/ad/app_open_ad_service.dart';` を削除
- 行57-62付近: `AppOpenAdManager` インスタンス作成を削除
- 行94-95付近: `MyApp` への `appOpenAdManager` 引数渡しを削除
- 行99-104付近: `_initializeMobileAdsInBackground()` の呼び出しを削除（バナー広告のMobileAds初期化は別途残す必要あり）
- 行125-143: `_initializeMobileAdsInBackground()` 関数を削除。ただし `MobileAds.instance.initialize()` はバナー広告に必要なので、別の場所で呼び出す
- 行183: `_MyAppState` の `WidgetsBindingObserver` mixin を削除（他に使用がなければ）
- 行197-199: `addObserver(this)` を削除
- 行213-229: `didChangeAppLifecycleState` と `_showAppOpenAdOnResume()` を削除
- 行241-245付近: MultiProvider内の `AppOpenAdManager` Provider登録を削除

**重要: バナー広告のためのMobileAds初期化を残す**

```dart
// main.dart のrunApp前（モバイルのみ）
if (!kIsWeb) {
  // バナー広告のための初期化（バックグラウンドで実行）
  Future.delayed(const Duration(seconds: 3), () {
    MobileAds.instance.initialize();
  });
}
```

**Step 2: app_open_ad_service.dart を削除**

`lib/services/ad/app_open_ad_service.dart` をファイルごと削除。

**Step 3: ビルド確認**

Run: `flutter analyze`
Expected: エラーなし

Run: `flutter test`
Expected: テスト通過

**Step 4: コミット**

```bash
git add -A
git commit -m "feat: アプリオープン広告を廃止

起動時の全画面広告を廃止。バナー広告のみ維持。
MobileAds初期化はバナー広告のために引き続き実行。

Refs: #111"
```

---

## Phase 1B: プレミアム再設計の基盤（FeatureAccessControl拡張）

### Task 3: FeatureAccessControl に新しい機能制限タイプを追加 (Issue #106, #107, #108, #109)

**Files:**
- Modify: `lib/services/feature_access_control.dart`
- Test: `test/services/feature_access_control_test.dart` (新規作成)

**Step 1: テストを書く**

`test/services/feature_access_control_test.dart` を新規作成:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([OneTimePurchaseService])
import 'feature_access_control_test.mocks.dart';

void main() {
  late FeatureAccessControl featureControl;
  late MockOneTimePurchaseService mockPurchaseService;

  setUp(() {
    mockPurchaseService = MockOneTimePurchaseService();
    when(mockPurchaseService.isPremiumUnlocked).thenReturn(false);
    when(mockPurchaseService.addListener(any)).thenReturn(null);
    when(mockPurchaseService.removeListener(any)).thenReturn(null);
    featureControl = FeatureAccessControl();
    featureControl.initialize(mockPurchaseService);
  });

  group('OCR制限', () {
    test('無料ユーザーはOCRを月5回まで使える', () {
      expect(featureControl.canUseOcr(), true);
      expect(featureControl.ocrRemainingCount, 5);
    });

    test('5回使用後はOCRが使えなくなる', () {
      for (var i = 0; i < 5; i++) {
        featureControl.incrementOcrUsage();
      }
      expect(featureControl.canUseOcr(), false);
      expect(featureControl.ocrRemainingCount, 0);
    });

    test('プレミアムユーザーはOCR無制限', () {
      when(mockPurchaseService.isPremiumUnlocked).thenReturn(true);
      for (var i = 0; i < 100; i++) {
        featureControl.incrementOcrUsage();
      }
      expect(featureControl.canUseOcr(), true);
    });

    test('月初にカウンターがリセットされる', () {
      for (var i = 0; i < 5; i++) {
        featureControl.incrementOcrUsage();
      }
      expect(featureControl.canUseOcr(), false);
      featureControl.resetMonthlyOcrCount();
      expect(featureControl.canUseOcr(), true);
      expect(featureControl.ocrRemainingCount, 5);
    });
  });

  group('ショップ制限', () {
    test('無料ユーザーはショップを2つまで作れる', () {
      expect(featureControl.canCreateShop(currentShopCount: 0), true);
      expect(featureControl.canCreateShop(currentShopCount: 1), true);
      expect(featureControl.canCreateShop(currentShopCount: 2), false);
    });

    test('プレミアムユーザーはショップ無制限', () {
      when(mockPurchaseService.isPremiumUnlocked).thenReturn(true);
      expect(featureControl.canCreateShop(currentShopCount: 100), true);
    });
  });

  group('レシピ解析制限', () {
    test('無料ユーザーはレシピ解析を使えない', () {
      expect(featureControl.canUseRecipeParser(), false);
    });

    test('プレミアムユーザーはレシピ解析を使える', () {
      when(mockPurchaseService.isPremiumUnlocked).thenReturn(true);
      expect(featureControl.canUseRecipeParser(), true);
    });
  });

  group('共有グループ制限', () {
    test('無料ユーザーは共有グループを使えない', () {
      expect(featureControl.canUseSharedGroup(), false);
    });

    test('プレミアムユーザーは共有グループを使える', () {
      when(mockPurchaseService.isPremiumUnlocked).thenReturn(true);
      expect(featureControl.canUseSharedGroup(), true);
    });
  });
}
```

**Step 2: テストが失敗することを確認**

Run: `flutter pub run build_runner build --delete-conflicting-outputs` (mockito mock生成)
Run: `flutter test test/services/feature_access_control_test.dart`
Expected: FAIL（新メソッドが未実装）

**Step 3: FeatureAccessControl を拡張実装**

`lib/services/feature_access_control.dart` に以下を追加:

FeatureType enumに追加:
```dart
enum FeatureType {
  themeCustomization,
  fontCustomization,
  adRemoval,
  ocrUnlimited,      // 追加
  shopUnlimited,     // 追加
  recipeParser,      // 追加
  sharedGroup,       // 追加
}
```

クラスに以下のフィールド・メソッドを追加:
```dart
// OCR月間使用制限
static const int maxFreeOcrPerMonth = 5;
int _ocrMonthlyUsageCount = 0;
String _ocrCountMonth = ''; // 'YYYY-MM' 形式

int get ocrRemainingCount => isPremiumUnlocked
    ? 999 // 無制限を表現
    : (maxFreeOcrPerMonth - _ocrMonthlyUsageCount).clamp(0, maxFreeOcrPerMonth);

bool canUseOcr() {
  if (isPremiumUnlocked) return true;
  _checkAndResetMonthlyOcr();
  return _ocrMonthlyUsageCount < maxFreeOcrPerMonth;
}

void incrementOcrUsage() {
  if (isPremiumUnlocked) return;
  _checkAndResetMonthlyOcr();
  _ocrMonthlyUsageCount++;
  _saveOcrUsageToLocal();
  notifyListeners();
}

void resetMonthlyOcrCount() {
  _ocrMonthlyUsageCount = 0;
  _ocrCountMonth = _currentMonth();
  _saveOcrUsageToLocal();
  notifyListeners();
}

void _checkAndResetMonthlyOcr() {
  final currentMonth = _currentMonth();
  if (_ocrCountMonth != currentMonth) {
    _ocrMonthlyUsageCount = 0;
    _ocrCountMonth = currentMonth;
    _saveOcrUsageToLocal();
  }
}

String _currentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

Future<void> _saveOcrUsageToLocal() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('ocr_monthly_usage_count', _ocrMonthlyUsageCount);
  await prefs.setString('ocr_count_month', _ocrCountMonth);
}

Future<void> _loadOcrUsageFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  _ocrMonthlyUsageCount = prefs.getInt('ocr_monthly_usage_count') ?? 0;
  _ocrCountMonth = prefs.getString('ocr_count_month') ?? '';
  _checkAndResetMonthlyOcr();
}

// ショップ制限
static const int maxFreeShops = 2;

bool canCreateShop({required int currentShopCount}) {
  if (isPremiumUnlocked) return true;
  return currentShopCount < maxFreeShops;
}

// レシピ解析制限
bool canUseRecipeParser() => isPremiumUnlocked;

// 共有グループ制限
bool canUseSharedGroup() => isPremiumUnlocked;
```

`initialize()` メソッド内に `_loadOcrUsageFromLocal()` 呼び出しを追加。

`isFeatureAvailable()` メソッドの switch文に新しい FeatureType の case を追加。

**Step 4: テストが通ることを確認**

Run: `flutter test test/services/feature_access_control_test.dart`
Expected: ALL PASS

**Step 5: ビルド全体確認**

Run: `flutter analyze`
Expected: エラーなし

**Step 6: コミット**

```bash
git add lib/services/feature_access_control.dart test/services/feature_access_control_test.dart
git commit -m "feat: FeatureAccessControlにOCR・ショップ・レシピ・共有の制限を追加

- OCR月5回制限（SharedPreferencesで月間カウント管理）
- ショップ2つ制限
- レシピ解析をプレミアム限定
- 共有グループをプレミアム限定
- 全制限のユニットテスト追加

Refs: #106, #107, #108, #109"
```

---

### Task 4: OCR月5回制限をUI層に統合 (Issue #106)

**Files:**
- Modify: `lib/services/hybrid_ocr_service.dart` (制限チェック追加)
- Modify: OCR呼び出し元の画面（カメラ画面からのコールバック受け取り側）
- Create: `lib/widgets/premium_upgrade_dialog.dart` (プレミアム誘導ダイアログ、再利用可能)

**Step 1: プレミアム誘導ダイアログを作成**

`lib/widgets/premium_upgrade_dialog.dart` を新規作成。
OCR制限、ショップ制限、レシピ制限、共有制限で共通利用する汎用ダイアログ。

```dart
import 'package:flutter/material.dart';

class PremiumUpgradeDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onUpgrade;

  const PremiumUpgradeDialog({
    super.key,
    required this.title,
    required this.message,
    this.onUpgrade,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onUpgrade,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        title: title,
        message: message,
        onUpgrade: onUpgrade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade?.call();
          },
          child: const Text('プレミアムにアップグレード'),
        ),
      ],
    );
  }
}
```

**Step 2: OCR呼び出し前に制限チェックを追加**

OCRは `CameraScreen` の `onImageCaptured` コールバック経由で呼ばれる。
呼び出し元（router.dart の `/camera` ルート定義、行239-248付近）で、カメラ画面に遷移する前に `FeatureAccessControl.canUseOcr()` をチェック。

カメラ画面への遷移箇所（メイン画面のカメラボタン押下時）で:
```dart
final featureControl = context.read<FeatureAccessControl>();
if (!featureControl.canUseOcr()) {
  PremiumUpgradeDialog.show(
    context,
    title: 'OCR回数制限',
    message: '今月の無料OCR（月${FeatureAccessControl.maxFreeOcrPerMonth}回）を使い切りました。\nプレミアムにアップグレードすると無制限に使えます。',
    onUpgrade: () => context.push('/premium'),
  );
  return;
}
```

OCR成功時（結果を受け取った後）に:
```dart
featureControl.incrementOcrUsage();
```

**Step 3: OCR残り回数の表示**

カメラ画面またはOCRボタン付近に残り回数を表示:
```dart
Text('残り ${featureControl.ocrRemainingCount} 回')
```

**Step 4: ビルド確認・テスト**

Run: `flutter analyze`
Run: `flutter test`

**Step 5: コミット**

```bash
git add -A
git commit -m "feat: OCR月5回制限のUI統合

- プレミアム誘導ダイアログ（汎用ウィジェット）を追加
- カメラ遷移前にOCR残り回数チェック
- OCR成功時にカウンター増加
- 残り回数の表示

Refs: #106"
```

---

### Task 5: ショップ（タブ）2つ制限の実装 (Issue #107)

**Files:**
- Modify: `lib/screens/main/dialogs/tab_add_dialog.dart`
- Modify: `lib/providers/data_provider.dart` (ショップ数取得用getter)

**Step 1: tab_add_dialog.dart にショップ制限チェックを追加**

`_handleAdd()` メソッド（行55-89）の先頭に制限チェックを挿入:

```dart
Future<void> _handleAdd() async {
  final name = _controller.text.trim();
  if (name.isEmpty) return;

  // ショップ数制限チェック
  final featureControl = context.read<FeatureAccessControl>();
  final dataProvider = context.read<DataProvider>();
  final currentShopCount = dataProvider.shops.length;

  if (!featureControl.canCreateShop(currentShopCount: currentShopCount)) {
    if (mounted) {
      Navigator.of(context).pop();
      PremiumUpgradeDialog.show(
        context,
        title: 'ショップ数の上限',
        message: '無料版ではショップは${FeatureAccessControl.maxFreeShops}つまでです。\nプレミアムにアップグレードすると無制限に作成できます。',
        onUpgrade: () => context.push('/premium'),
      );
    }
    return;
  }

  // 既存のaddShop処理...
```

**Step 2: ビルド確認・テスト**

Run: `flutter analyze`
Run: `flutter test`

**Step 3: コミット**

```bash
git add -A
git commit -m "feat: ショップ（タブ）2つ制限を実装

無料ユーザーのショップ作成を2つまでに制限。
3つ目の追加時にプレミアム誘導ダイアログを表示。

Refs: #107"
```

---

### Task 6: レシピ解析をプレミアム限定に変更 (Issue #108)

**Files:**
- Modify: レシピ解析のエントリーポイント画面（レシピ入力画面 or レシピ解析ボタンのある画面）

**Step 1: レシピ解析のエントリーポイントを特定**

`router.dart` 行251-262 の `/recipe-confirm` ルート、およびレシピ解析を開始するUIボタンを特定する。

**Step 2: レシピ解析画面への遷移前に制限チェック追加**

レシピ解析を呼び出すボタン押下時:
```dart
final featureControl = context.read<FeatureAccessControl>();
if (!featureControl.canUseRecipeParser()) {
  PremiumUpgradeDialog.show(
    context,
    title: 'プレミアム機能',
    message: 'レシピ解析はプレミアム限定機能です。\nレシピテキストから買い物リストを自動作成できます。',
    onUpgrade: () => context.push('/premium'),
  );
  return;
}
```

**Step 3: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: レシピ解析をプレミアム限定に変更

無料ユーザーがレシピ解析にアクセスした際にプレミアム誘導ダイアログを表示。

Refs: #108"
```

---

### Task 7: 共有グループ（ファミリー機能）をプレミアム限定に変更 (Issue #109)

**Files:**
- Modify: 共有グループのエントリーポイント画面

**Step 1: 共有グループのUIエントリーポイントを特定**

共有グループの作成・参加UIが存在する画面を特定する（メイン画面のタブ長押し or ドロワー内）。

**Step 2: 共有グループ画面への遷移前に制限チェック追加**

```dart
final featureControl = context.read<FeatureAccessControl>();
if (!featureControl.canUseSharedGroup()) {
  PremiumUpgradeDialog.show(
    context,
    title: 'プレミアム機能',
    message: '共有グループはプレミアム限定機能です。\n家族やパートナーとリアルタイムで買い物リストを共有できます。',
    onUpgrade: () => context.push('/premium'),
  );
  return;
}
```

**Step 3: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: 共有グループをプレミアム限定に変更

無料ユーザーが共有グループにアクセスした際にプレミアム誘導ダイアログを表示。

Refs: #109"
```

---

### Task 8: プレミアム紹介画面の刷新・価格変更 (Issue #110)

**Files:**
- Modify: プレミアム紹介画面（特定が必要。ドロワー内 or 設定画面内）
- Modify: `lib/services/one_time_purchase_service.dart` — productId / 価格表示

**Step 1: プレミアム紹介画面を特定して読む**

ドロワーメニューや設定画面からプレミアム画面への導線を確認。

**Step 2: 特典一覧を新しい内容に更新**

表示内容を変更:
```
【まいカゴプレミアム — ¥480（買い切り）】

✅ OCR（値札撮影）無制限 — 月5回の制限を解除
✅ ショップ（タブ）無制限 — 2つの制限を解除
✅ レシピ解析 — テキストから買い物リストを自動作成
✅ 共有グループ — 家族でリアルタイム共有
✅ 全テーマ・全フォント
✅ 広告完全非表示

コーヒー1杯分で、ずっと使える。
```

**Step 3: 価格関連の更新**

`feature_access_control.dart` の `getRecommendedUpgradePlan()` 内（行95-122付近）の価格表示を ¥280 → ¥480 に更新。

**注意:** Google Play Console / App Store Connect での実際の価格変更は手動で行う（アプリ外作業）。

**Step 4: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: プレミアム紹介画面を刷新、価格を¥480に更新

新しいプレミアム特典（OCR無制限、ショップ無制限、レシピ解析、共有グループ）を表示。
価格表示を¥280→¥480に変更。

Refs: #110"
```

---

## Phase 1C: 初回体験の改善（ゲストモード＋ウェルカム画面）

### Task 9: AuthProvider にゲストモード状態を追加 (Issue #104)

**Files:**
- Modify: `lib/providers/auth_provider.dart`
- Test: `test/providers/auth_provider_test.dart` (新規作成)

**Step 1: テストを書く**

```dart
import 'package:flutter_test/flutter_test.dart';

// AuthProviderのゲストモード関連のテスト
void main() {
  group('ゲストモード', () {
    test('初期状態はゲストモードではない', () {
      // authProvider.isGuestMode == false
    });

    test('enterGuestModeでゲストモードに入れる', () {
      // authProvider.enterGuestMode()
      // authProvider.isGuestMode == true
      // authProvider.canUseApp == true
    });

    test('ゲストモード中にログインするとゲストモードが解除される', () {
      // authProvider.enterGuestMode()
      // authProvider.signInWithGoogle() (mock)
      // authProvider.isGuestMode == false
    });
  });
}
```

**Step 2: AuthProvider にゲストモード実装**

`lib/providers/auth_provider.dart` に追加:

```dart
// フィールド追加
bool _isGuestMode = false;

// getter追加
bool get isGuestMode => _isGuestMode;

// canUseApp を修正（行52）
bool get canUseApp => isLoggedIn || _isGuestMode;

// メソッド追加
void enterGuestMode() {
  _isGuestMode = true;
  notifyListeners();
}

void _exitGuestMode() {
  _isGuestMode = false;
}
```

`signInWithGoogle()` 内（行160-171）でログイン成功時に `_exitGuestMode()` を呼ぶ。

**Step 3: テスト通過確認・コミット**

```bash
git add -A
git commit -m "feat: AuthProviderにゲストモード状態を追加

- isGuestMode フラグ
- enterGuestMode() / _exitGuestMode() メソッド
- canUseApp がゲストモードでもtrueを返すように変更

Refs: #104"
```

---

### Task 10: router.dart のゲストモード対応 (Issue #104)

**Files:**
- Modify: `lib/router.dart`

**Step 1: 認証リダイレクトにゲストモード対応を追加**

`router.dart` 行36-54 の `redirect` ロジックを修正:

```dart
redirect: (context, state) {
  final isLoggedIn = authProvider.isLoggedIn;
  final isGuestMode = authProvider.isGuestMode;  // 追加
  final isLoading = authProvider.isLoading;
  final currentPath = state.matchedLocation;

  // スプラッシュは常にアクセス可能
  if (currentPath == '/') return null;

  // 読み込み中はリダイレクトなし
  if (isLoading) return null;

  // ログイン済み or ゲストモードで /login にいる場合 → /home へ
  if ((isLoggedIn || isGuestMode) && currentPath == '/login') {
    return '/home';
  }

  // 未ログイン かつ ゲストモードでない場合 → /login へ
  if (!isLoggedIn && !isGuestMode && currentPath != '/login') {
    return '/login';
  }

  return null;
},
```

**Step 2: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: ルーターのゲストモード対応

ゲストモード時はログイン画面をスキップして/homeへ遷移。

Refs: #104"
```

---

### Task 11: ゲストモード用ローカルデータ管理 (Issue #104)

**Files:**
- Modify: `lib/providers/data_provider.dart`
- Modify: `lib/providers/repositories/shop_repository.dart`
- Modify: `lib/providers/repositories/item_repository.dart`

**Step 1: DataProviderのゲストモード対応**

ゲストモード時はFirestoreではなくローカルメモリ（既存のキャッシュ構造）のみでデータを管理する。

`DataProviderState` に `isLocalMode` のような概念が既にあるか確認（行37付近 `ローカルモードでなければ` の記述あり）。既存の `isLocalMode` を活用し、ゲストモード時に `isLocalMode = true` を設定する。

**Step 2: AuthProviderとDataProviderの連携**

`DataProvider.setAuthProvider()` 内（行70-80付近）で、`authProvider.isGuestMode` を監視し、ゲストモード時にローカルモードを有効化。

**Step 3: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: ゲストモード時のローカルデータ管理

ゲストモード時はFirestoreを使わずメモリ内キャッシュのみで動作。

Refs: #104"
```

---

### Task 12: ウェルカム画面の実装 (Issue #103)

**Files:**
- Create: `lib/screens/welcome_screen.dart`
- Modify: `lib/router.dart` — ウェルカム画面ルート追加
- Modify: `lib/screens/login_screen.dart` — ウェルカム画面への導線

**Step 1: ウェルカム画面を作成**

`lib/screens/welcome_screen.dart` を新規作成:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maikago/providers/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _WelcomePage(
      title: '買い物リスト＋電卓\nこれ1つで',
      subtitle: 'メモと電卓はもういらない',
      icon: Icons.shopping_cart_outlined,
    ),
    _WelcomePage(
      title: '予算を設定して\nオーバーしない買い物を',
      subtitle: '残額をリアルタイムで確認',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _WelcomePage(
      title: '値札を撮るだけで\n自動入力',
      subtitle: 'AIが商品名と価格を認識',
      icon: Icons.camera_alt_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            // ページインジケーター
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // ボタン群
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _startAsGuest,
                      child: const Text('まずは使ってみる'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _signIn,
                      child: const Text('Googleでログイン'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _startAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);
    if (mounted) {
      context.read<AuthProvider>().enterGuestMode();
      context.go('/home');
    }
  }

  Future<void> _signIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);
    if (mounted) {
      context.go('/login');
    }
  }
}

class _WelcomePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _WelcomePage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: router.dart にウェルカム画面ルートを追加**

ルート定義に `/welcome` を追加。
スプラッシュ画面（`/`）のリダイレクトロジックで、初回起動時に `/welcome` へリダイレクト:

```dart
// redirect 内
if (currentPath == '/') {
  if (isLoading) return null;
  // 初回起動チェック
  // SharedPreferencesの同期読み込みが難しいため、
  // スプラッシュ画面側でチェックして遷移するのが望ましい
}
```

**Step 3: スプラッシュ画面にウェルカム画面表示判定を追加**

スプラッシュ画面の初期化後:
```dart
final prefs = await SharedPreferences.getInstance();
final welcomeSeen = prefs.getBool('welcome_seen') ?? false;
if (!welcomeSeen) {
  context.go('/welcome');
  return;
}
// 既存のログイン状態チェック...
```

**Step 4: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: ウェルカム画面（オンボーディング）を実装

- 3枚スライドのチュートリアル兼価値訴求
- 「まずは使ってみる」（ゲストモード）ボタン
- 「Googleでログイン」ボタン
- 初回のみ表示（SharedPreferencesでフラグ管理）

Refs: #103"
```

---

### Task 13: ゲスト→ログイン時のデータマイグレーション (Issue #105)

**Files:**
- Modify: `lib/providers/auth_provider.dart`
- Modify: `lib/providers/data_provider.dart`

**Step 1: マイグレーションロジック実装**

`AuthProvider.signInWithGoogle()` のログイン成功後に:
1. ゲストモードだった場合、ローカルのショップ・アイテムデータを取得
2. Firestore初期化後にデータをFirestoreへ書き込み
3. ローカルデータをクリア
4. ゲストモードを解除

```dart
Future<void> signInWithGoogle() async {
  // 既存のログイン処理...

  // ゲストモードからのマイグレーション
  if (_isGuestMode) {
    await _migrateGuestData();
    _exitGuestMode();
  }
}

Future<void> _migrateGuestData() async {
  // DataProviderからゲスト時のローカルデータを取得
  // Firestoreへ書き込み
  // ローカルデータをクリア
}
```

**Step 2: DataProvider にマイグレーション用メソッドを追加**

```dart
Future<List<Shop>> getLocalShopsForMigration() async {
  return List.from(_shopRepository.shops);
}

Future<void> migrateDataToFirestore(String userId) async {
  // ローカルのショップとアイテムをFirestoreに書き込み
  // 書き込み成功後にローカルキャッシュをクリア＆再読み込み
}
```

**Step 3: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: ゲスト→ログイン時のデータマイグレーション

ゲストモードで作成したデータをログイン後にFirestoreへ移行。

Refs: #105"
```

---

## Phase 2: ストア掲載の更新（コード変更）

### Task 14: アプリ名・メタデータの変更 (Issue #112)

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` — `android:label`
- Modify: `ios/Runner/Info.plist` — `CFBundleDisplayName`
- Modify: `web/index.html` — `<title>`
- Modify: `web/manifest.json` — `name`, `short_name`

**Step 1: 各ファイルのアプリ名を変更**

全ファイルで以下の置換:
```
旧: まいカゴ – 値札読み取りで買い物の合計金額が一瞬でわかる
新: まいカゴ – 買い物リスト＆電卓。予算オーバーしない
```

`web/manifest.json` の `description` も更新:
```json
"description": "メモと電卓はもういらない。買い物リスト＋自動計算＋予算管理、これ1つ。"
```

**Step 2: ビルド確認・コミット**

```bash
git add -A
git commit -m "feat: アプリ名を新しい訴求軸に変更

「値札読み取り」→「買い物リスト＆電卓。予算オーバーしない」に変更。
ターゲット（節約志向の人）に刺さるキーワードを含む。

Refs: #112"
```

---

## タスク依存関係

```
Task 1 (インタースティシャル廃止) ← 独立
Task 2 (アプリオープン広告廃止) ← Task 1 の後（main.dart の整合性）
Task 3 (FeatureAccessControl拡張) ← 独立
Task 4 (OCR制限UI) ← Task 3 の後
Task 5 (ショップ制限) ← Task 3 の後
Task 6 (レシピ制限) ← Task 3 の後
Task 7 (共有制限) ← Task 3 の後
Task 8 (プレミアム画面刷新) ← Task 3-7 の後
Task 9 (AuthProviderゲストモード) ← 独立
Task 10 (ルーターゲストモード対応) ← Task 9 の後
Task 11 (ゲストモードローカルデータ) ← Task 9, 10 の後
Task 12 (ウェルカム画面) ← Task 9, 10 の後
Task 13 (データマイグレーション) ← Task 11, 12 の後
Task 14 (アプリ名変更) ← 独立
```

## 並列実行可能なグループ

```
Group A: Task 1 → Task 2       （広告廃止）
Group B: Task 3 → Task 4,5,6,7 → Task 8  （プレミアム再設計）
Group C: Task 9 → Task 10,11 → Task 12 → Task 13  （ゲストモード）
Group D: Task 14               （ストア更新）

Group A, B, C, D は全て並列実行可能
```
