# 初回チュートリアル（コーチマーク + 空状態ガイド）Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 新規ユーザーが初回起動時にアプリの基本操作を直感的に理解できるコーチマークと、アイテム0個時の空状態ガイドを実装する。

**Architecture:** 自前実装の `Overlay` + `CustomPainter` によるフルオーバーレイ方式コーチマーク（4ステップ）。ウェルカムダイアログ完了後に `addPostFrameCallback` で起動。空状態ガイドは `ItemListSection` 内でアイテム0個時に表示する独立ウィジェット。

**Tech Stack:** Flutter, CustomPainter, Overlay, AnimationController, SharedPreferences

---

### Task 1: SharedPreferences にコーチマーク完了フラグを追加

**Files:**
- Modify: `lib/services/settings_persistence.dart:131-137`
- Test: `test/services/settings_persistence_test.dart`（既存テストがあれば追加、なければ新規）

**Step 1: `settings_persistence.dart` にフラグを追加**

`lib/services/settings_persistence.dart` の `_isFirstLaunchKey` 定義付近（L13-18あたり）に定数を追加し、初回起動フラグと同じパターンでメソッドを追加:

```dart
static const String _coachMarkCompletedKey = 'coach_mark_completed';

static Future<bool> isCoachMarkCompleted() =>
    _load(_coachMarkCompletedKey, false, 'isCoachMarkCompleted');

static Future<void> setCoachMarkCompleted() =>
    _save(_coachMarkCompletedKey, true, 'setCoachMarkCompleted');

static Future<void> resetCoachMark() =>
    _save(_coachMarkCompletedKey, false, 'resetCoachMark');
```

**Step 2: 静的分析を実行**

Run: `flutter analyze lib/services/settings_persistence.dart`
Expected: No issues found

**Step 3: コミット**

```bash
git add lib/services/settings_persistence.dart
git commit -m "feat: コーチマーク完了フラグをSettingsPersistenceに追加"
```

---

### Task 2: CoachMarkStep データモデルを作成

**Files:**
- Create: `lib/widgets/coach_mark/coach_mark_step.dart`

**Step 1: ステップデータモデルを作成**

```dart
import 'package:flutter/material.dart';

/// コーチマークの穴の形状
enum CoachMarkShape {
  circle,
  roundedRectangle,
}

/// コーチマークの1ステップを表すデータモデル
class CoachMarkStep {
  const CoachMarkStep({
    required this.targetKey,
    required this.description,
    required this.shape,
    this.padding = 8.0,
    this.borderRadius = 12.0,
  });

  /// ターゲットウィジェットの GlobalKey
  final GlobalKey targetKey;

  /// 説明テキスト
  final String description;

  /// 穴の形状
  final CoachMarkShape shape;

  /// ターゲットの周囲パディング
  final double padding;

  /// 角丸矩形の場合の borderRadius
  final double borderRadius;

  /// ターゲットの Rect を取得
  Rect? getTargetRect() {
    final renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Rect.fromLTWH(
      offset.dx - padding,
      offset.dy - padding,
      size.width + padding * 2,
      size.height + padding * 2,
    );
  }
}
```

**Step 2: 静的分析を実行**

Run: `flutter analyze lib/widgets/coach_mark/coach_mark_step.dart`
Expected: No issues found

**Step 3: コミット**

```bash
git add lib/widgets/coach_mark/coach_mark_step.dart
git commit -m "feat: CoachMarkStep データモデルを作成"
```

---

### Task 3: CoachMarkPainter（穴抜き描画）を作成

**Files:**
- Create: `lib/widgets/coach_mark/coach_mark_painter.dart`

**Step 1: CustomPainter を作成**

```dart
import 'package:flutter/material.dart';
import 'coach_mark_step.dart';

/// コーチマークの半透明オーバーレイと穴抜き描画を行う CustomPainter
class CoachMarkPainter extends CustomPainter {
  CoachMarkPainter({
    required this.targetRect,
    required this.shape,
    this.borderRadius = 12.0,
    this.overlayColor = const Color(0xB3000000), // black.withOpacity(0.7)
  });

  final Rect targetRect;
  final CoachMarkShape shape;
  final double borderRadius;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 画面全体のパス
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // ターゲットの穴のパス
    final holePath = Path();
    switch (shape) {
      case CoachMarkShape.circle:
        final center = targetRect.center;
        final radius = targetRect.shortestSide / 2;
        holePath.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case CoachMarkShape.roundedRectangle:
        holePath.addRRect(
          RRect.fromRectAndRadius(targetRect, Radius.circular(borderRadius)),
        );
        break;
    }

    // 差分パスで穴抜き
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullPath,
      holePath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()..color = overlayColor,
    );
  }

  @override
  bool shouldRepaint(CoachMarkPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.shape != shape;
  }
}
```

**Step 2: 静的分析を実行**

Run: `flutter analyze lib/widgets/coach_mark/coach_mark_painter.dart`
Expected: No issues found

**Step 3: コミット**

```bash
git add lib/widgets/coach_mark/coach_mark_painter.dart
git commit -m "feat: CoachMarkPainter（穴抜き描画）を作成"
```

---

### Task 4: CoachMarkTooltip（吹き出し）を作成

**Files:**
- Create: `lib/widgets/coach_mark/coach_mark_tooltip.dart`

**Step 1: 吹き出しウィジェットを作成**

```dart
import 'package:flutter/material.dart';

/// コーチマークの吹き出しウィジェット
/// ターゲットの位置に応じて上下に表示位置を自動判定する
class CoachMarkTooltip extends StatelessWidget {
  const CoachMarkTooltip({
    super.key,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    required this.targetRect,
    required this.screenSize,
    required this.onNext,
    required this.onSkip,
    required this.animation,
  });

  final String description;
  final int currentStep;
  final int totalSteps;
  final Rect targetRect;
  final Size screenSize;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Animation<double> animation;

  bool get _isLastStep => currentStep == totalSteps - 1;

  /// ターゲットが画面の上半分にあるかどうか
  bool get _showBelow => targetRect.center.dy < screenSize.height / 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: 24,
      right: 24,
      top: _showBelow ? targetRect.bottom + 16 : null,
      bottom: _showBelow ? null : screenSize.height - targetRect.top + 16,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, _showBelow ? -0.1 : 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 説明テキスト + スキップ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'スキップ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 次へ / 始めるボタン
                  Center(
                    child: FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: Text(
                        _isLastStep
                            ? '始める'
                            : '次へ (${currentStep + 1}/$totalSteps)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: 静的分析を実行**

Run: `flutter analyze lib/widgets/coach_mark/coach_mark_tooltip.dart`
Expected: No issues found

**Step 3: コミット**

```bash
git add lib/widgets/coach_mark/coach_mark_tooltip.dart
git commit -m "feat: CoachMarkTooltip（吹き出しウィジェット）を作成"
```

---

### Task 5: CoachMarkOverlay（メインコントローラー）を作成

**Files:**
- Create: `lib/widgets/coach_mark/coach_mark_overlay.dart`

**Step 1: オーバーレイウィジェットを作成**

```dart
import 'package:flutter/material.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'coach_mark_step.dart';
import 'coach_mark_painter.dart';
import 'coach_mark_tooltip.dart';

/// コーチマークオーバーレイ
/// Overlay上に表示し、ステップごとにターゲットをハイライトして説明を表示する
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  final List<CoachMarkStep> steps;
  final VoidCallback onComplete;

  /// Overlay にコーチマークを挿入する
  static OverlayEntry? show({
    required BuildContext context,
    required List<CoachMarkStep> steps,
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => CoachMarkOverlay(
        steps: steps,
        onComplete: () {
          entry?.remove();
          onComplete?.call();
        },
      ),
    );
    overlay.insert(entry);
    return entry;
  }

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with TickerProviderStateMixin {
  int _currentStepIndex = 0;

  // オーバーレイのフェードイン/アウト
  late final AnimationController _overlayController;
  late final Animation<double> _overlayAnimation;

  // 穴の位置アニメーション
  late final AnimationController _holeController;
  late final Animation<double> _holeAnimation;

  // 吹き出しのフェードアニメーション
  late final AnimationController _tooltipController;
  late final Animation<double> _tooltipAnimation;

  Rect _currentTargetRect = Rect.zero;
  Rect _previousTargetRect = Rect.zero;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    );

    _holeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _holeAnimation = CurvedAnimation(
      parent: _holeController,
      curve: Curves.easeInOut,
    );

    _tooltipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tooltipAnimation = CurvedAnimation(
      parent: _tooltipController,
      curve: Curves.easeOut,
    );

    _initStep();
    _overlayController.forward().then((_) {
      _holeController.forward().then((_) {
        _tooltipController.forward();
      });
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _holeController.dispose();
    _tooltipController.dispose();
    super.dispose();
  }

  void _initStep() {
    final step = widget.steps[_currentStepIndex];
    final rect = step.getTargetRect();
    if (rect != null) {
      _currentTargetRect = rect;
      _previousTargetRect = rect;
    }
  }

  Future<void> _goToNext() async {
    if (_currentStepIndex >= widget.steps.length - 1) {
      await _complete();
      return;
    }

    // 吹き出しをフェードアウト
    await _tooltipController.reverse();

    // 次のステップへ
    _currentStepIndex++;
    final step = widget.steps[_currentStepIndex];
    final rect = step.getTargetRect();
    if (rect != null) {
      _previousTargetRect = _currentTargetRect;
      _currentTargetRect = rect;
    }

    // 穴の移動アニメーション
    _holeController.reset();
    await _holeController.forward();

    // 吹き出しフェードイン
    _tooltipController.reset();
    await _tooltipController.forward();
  }

  Future<void> _complete() async {
    await SettingsPersistence.setCoachMarkCompleted();
    await _overlayController.reverse();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final step = widget.steps[_currentStepIndex];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _overlayAnimation,
        _holeAnimation,
        _tooltipAnimation,
      ]),
      builder: (context, child) {
        // 穴の位置を補間
        final animatedRect = Rect.lerp(
          _previousTargetRect,
          _currentTargetRect,
          _holeAnimation.value,
        )!;

        return GestureDetector(
          // 背景タップは無効
          onTap: () {},
          child: Stack(
            children: [
              // 半透明オーバーレイ + 穴抜き
              Opacity(
                opacity: _overlayAnimation.value,
                child: CustomPaint(
                  size: screenSize,
                  painter: CoachMarkPainter(
                    targetRect: animatedRect,
                    shape: step.shape,
                    borderRadius: step.borderRadius,
                  ),
                ),
              ),
              // 吹き出し
              if (_tooltipAnimation.value > 0)
                CoachMarkTooltip(
                  description: step.description,
                  currentStep: _currentStepIndex,
                  totalSteps: widget.steps.length,
                  targetRect: animatedRect,
                  screenSize: screenSize,
                  onNext: _goToNext,
                  onSkip: _complete,
                  animation: _tooltipAnimation,
                ),
            ],
          ),
        );
      },
    );
  }
}
```

**Step 2: 静的分析を実行**

Run: `flutter analyze lib/widgets/coach_mark/`
Expected: No issues found

**Step 3: コミット**

```bash
git add lib/widgets/coach_mark/
git commit -m "feat: CoachMarkOverlay（メインコントローラー）を作成"
```

---

### Task 6: MainScreen に GlobalKey を追加しコーチマークを統合

**Files:**
- Modify: `lib/screens/main_screen.dart`
- Modify: `lib/screens/main/widgets/bottom_summary_widget.dart`
- Modify: `lib/screens/main/widgets/main_app_bar.dart`
- Modify: `lib/screens/main/widgets/item_list_section.dart`

**Step 1: GlobalKey をトップレベルで定義し子ウィジェットに渡す**

`main_screen.dart` の `_MainScreenState` に4つの GlobalKey を追加:

```dart
// コーチマーク用 GlobalKey
final GlobalKey _fabKey = GlobalKey();
final GlobalKey _itemListKey = GlobalKey();
final GlobalKey _addTabKey = GlobalKey();
final GlobalKey _budgetKey = GlobalKey();
```

各 GlobalKey を子ウィジェットに渡す:
- `BottomSummaryWidget` に `fabKey` と `budgetKey` を追加
- `MainAppBar` に `addTabKey` を追加
- `ItemListSection` に `itemListKey` を追加

**Step 2: 各子ウィジェットで GlobalKey をコンストラクタで受け取り、対象ウィジェットの `key` に設定**

`bottom_summary_widget.dart`:
- コンストラクタに `GlobalKey? fabKey` と `GlobalKey? budgetKey` を追加
- 「リスト追加」ボタン（L521）に `key: widget.fabKey` を設定
- 予算変更ボタン（L425）に `key: widget.budgetKey` を設定

`main_app_bar.dart`:
- コンストラクタに `GlobalKey? addTabKey` を追加
- 「タブ追加」InkWell（L78付近）に `key: widget.addTabKey` を設定

`item_list_section.dart`:
- コンストラクタに `GlobalKey? itemListKey` を追加
- 未購入リストの `Expanded`（L131）に `key: widget.itemListKey` を設定

**Step 3: 静的分析を実行**

Run: `flutter analyze lib/screens/`
Expected: No issues found

**Step 4: コミット**

```bash
git add lib/screens/main_screen.dart lib/screens/main/widgets/
git commit -m "feat: コーチマーク用 GlobalKey を MainScreen と子ウィジェットに追加"
```

---

### Task 7: startup_helpers にコーチマーク起動処理を追加

**Files:**
- Modify: `lib/screens/main/utils/startup_helpers.dart:64-73`
- Modify: `lib/widgets/welcome_dialog.dart:102-107`
- Modify: `lib/screens/main_screen.dart` (initState)

**Step 1: ウェルカムダイアログにコーチマーク起動コールバックを追加**

`welcome_dialog.dart` にコールバックを追加:

```dart
class WelcomeDialog extends StatefulWidget {
  const WelcomeDialog({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;
  // ...
}
```

`_completeWelcome()` を修正:

```dart
Future<void> _completeWelcome() async {
  await SettingsPersistence.setFirstLaunchComplete();
  if (mounted) {
    context.pop();
    widget.onCompleted?.call();
  }
}
```

**Step 2: startup_helpers にコーチマーク表示メソッドを追加**

`startup_helpers.dart` に新規メソッド追加:

```dart
import 'package:maikago/widgets/coach_mark/coach_mark_overlay.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_step.dart';

static Future<void> checkAndShowCoachMark(
  BuildContext context, {
  required GlobalKey fabKey,
  required GlobalKey itemListKey,
  required GlobalKey addTabKey,
  required GlobalKey budgetKey,
}) async {
  final isCompleted = await SettingsPersistence.isCoachMarkCompleted();
  if (isCompleted || !context.mounted) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    CoachMarkOverlay.show(
      context: context,
      steps: [
        CoachMarkStep(
          targetKey: fabKey,
          description: 'ここからアイテムを追加できます',
          shape: CoachMarkShape.roundedRectangle,
        ),
        CoachMarkStep(
          targetKey: itemListKey,
          description: 'アイテムを追加したら左スワイプで購入済みに移動できます',
          shape: CoachMarkShape.roundedRectangle,
        ),
        CoachMarkStep(
          targetKey: addTabKey,
          description: 'タブを追加して複数の買い物リストを管理できます',
          shape: CoachMarkShape.roundedRectangle,
        ),
        CoachMarkStep(
          targetKey: budgetKey,
          description: '予算を設定して買いすぎを防止しましょう',
          shape: CoachMarkShape.roundedRectangle,
        ),
      ],
    );
  });
}
```

**Step 3: `checkAndShowWelcomeDialog` にコーチマーク起動を統合**

既存の `checkAndShowWelcomeDialog` を修正し、GlobalKey を受け取れるようにする:

```dart
static Future<void> checkAndShowWelcomeDialog(
  BuildContext context, {
  GlobalKey? fabKey,
  GlobalKey? itemListKey,
  GlobalKey? addTabKey,
  GlobalKey? budgetKey,
}) async {
  final isFirstLaunch = await SettingsPersistence.isFirstLaunch();
  if (isFirstLaunch && context.mounted) {
    unawaited(showConstrainedDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomeDialog(
        onCompleted: () {
          if (fabKey != null &&
              itemListKey != null &&
              addTabKey != null &&
              budgetKey != null) {
            // ウェルカムダイアログ完了後にコーチマーク起動
            checkAndShowCoachMark(
              context,
              fabKey: fabKey,
              itemListKey: itemListKey,
              addTabKey: addTabKey,
              budgetKey: budgetKey,
            );
          }
        },
      ),
    ));
  } else {
    // 初回起動ではないが、コーチマーク未完了の場合
    if (fabKey != null &&
        itemListKey != null &&
        addTabKey != null &&
        budgetKey != null) {
      await checkAndShowCoachMark(
        context,
        fabKey: fabKey,
        itemListKey: itemListKey,
        addTabKey: addTabKey,
        budgetKey: budgetKey,
      );
    }
  }
}
```

**Step 4: MainScreen の initState で GlobalKey を渡す**

`main_screen.dart` の `addPostFrameCallback` 内を修正:

```dart
StartupHelpers.checkAndShowWelcomeDialog(
  context,
  fabKey: _fabKey,
  itemListKey: _itemListKey,
  addTabKey: _addTabKey,
  budgetKey: _budgetKey,
);
```

**Step 5: 静的分析を実行**

Run: `flutter analyze lib/`
Expected: No issues found

**Step 6: コミット**

```bash
git add lib/screens/main/utils/startup_helpers.dart lib/widgets/welcome_dialog.dart lib/screens/main_screen.dart
git commit -m "feat: ウェルカムダイアログ完了後にコーチマークを起動する処理を追加"
```

---

### Task 8: 空状態ガイド（EmptyStateGuide）を作成

**Files:**
- Create: `lib/screens/main/widgets/empty_state_guide.dart`
- Modify: `lib/screens/main/widgets/item_list_section.dart:133-134`

**Step 1: EmptyStateGuide ウィジェットを作成**

```dart
import 'package:flutter/material.dart';

/// アイテムが0個のとき未購入リスト領域に表示する空状態ガイド
class EmptyStateGuide extends StatefulWidget {
  const EmptyStateGuide({super.key});

  @override
  State<EmptyStateGuide> createState() => _EmptyStateGuideState();
}

class _EmptyStateGuideState extends State<EmptyStateGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'アイテムがまだありません',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下の ＋ ボタンから追加してみましょう',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 28,
                  color: primaryColor.withOpacity(0.4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

**Step 2: ItemListSection の空状態に EmptyStateGuide を挿入**

`item_list_section.dart` L133-134 を修正。**未購入リスト（`isIncomplete == true`）のときのみ表示**する。

`_buildSection` に `isIncomplete` パラメータを追加するか、呼び出し時に判別する。

変更前:
```dart
child: items.isEmpty
    ? const SizedBox.shrink()
    : ReorderableListView.builder(
```

変更後（未購入セクションの場合のみ表示）:
```dart
child: items.isEmpty
    ? (isIncomplete ? const EmptyStateGuide() : const SizedBox.shrink())
    : ReorderableListView.builder(
```

`_buildSection` メソッドに `bool isIncomplete` パラメータを追加し、呼び出し元（L52-87付近）で `isIncomplete: true` / `isIncomplete: false` を渡す。

**Step 3: 静的分析を実行**

Run: `flutter analyze lib/screens/main/widgets/`
Expected: No issues found

**Step 4: コミット**

```bash
git add lib/screens/main/widgets/empty_state_guide.dart lib/screens/main/widgets/item_list_section.dart
git commit -m "feat: アイテム0個時の空状態ガイド（EmptyStateGuide）を追加"
```

---

### Task 9: 詳細設定画面にコーチマークリセット機能を追加

**Files:**
- Modify: `lib/screens/drawer/settings/advanced_settings_screen.dart:405-418`

**Step 1: 既存のウェルカムダイアログリセットの近くにコーチマークリセットを追加**

既存のウェルカムダイアログ表示ボタン（L405-418）の直後に、コーチマークリセットボタンを追加:

```dart
ListTile(
  leading: const Icon(Icons.refresh),
  title: const Text('チュートリアルをリセット'),
  subtitle: const Text('コーチマークを再表示します'),
  onTap: () async {
    await SettingsPersistence.resetCoachMark();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('チュートリアルをリセットしました。アプリを再起動すると表示されます。')),
      );
    }
  },
),
```

**Step 2: 静的分析を実行**

Run: `flutter analyze lib/screens/drawer/settings/advanced_settings_screen.dart`
Expected: No issues found

**Step 3: コミット**

```bash
git add lib/screens/drawer/settings/advanced_settings_screen.dart
git commit -m "feat: 詳細設定にコーチマークリセット機能を追加"
```

---

### Task 10: 統合テスト・手動検証・最終調整

**Step 1: 全体の静的分析を実行**

Run: `flutter analyze`
Expected: No issues found

**Step 2: 既存テストを実行し壊れていないことを確認**

Run: `flutter test`
Expected: All tests passed

**Step 3: 手動検証チェックリスト**

以下を確認（エミュレーター / 実機で）:
- [ ] 初回起動時: ウェルカムダイアログ→「始める」→コーチマークが表示される
- [ ] コーチマーク: 4ステップが正しく遷移する
- [ ] コーチマーク: 穴抜きが正しい位置にある
- [ ] コーチマーク: 吹き出しが穴の上下に適切に配置される
- [ ] コーチマーク: 「スキップ」で全ステップをスキップできる
- [ ] コーチマーク: 完了後に再表示されない
- [ ] 空状態ガイド: アイテム0個で表示される
- [ ] 空状態ガイド: アイテム追加後に消える
- [ ] 空状態ガイド: 購入済みリスト側には表示されない
- [ ] 空状態ガイド: 矢印のバウンスアニメーションが動作する
- [ ] 詳細設定: リセットボタンでコーチマークが再表示される
- [ ] 既存機能に影響がない

**Step 4: 最終コミット（調整があれば）**

```bash
git add -A
git commit -m "fix: コーチマーク・空状態ガイドの最終調整"
```
