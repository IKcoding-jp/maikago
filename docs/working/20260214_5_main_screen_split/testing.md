# テスト計画書

## Issue情報
- **Issue番号**: #5
- **タイトル**: main_screen.dartの責務分割
- **作成日**: 2026-02-14

## テスト目的

本リファクタリングにおけるテストの目的は以下の通り:

1. **機能の維持**: 既存のすべての機能が分割後も正常に動作することを保証
2. **品質の向上**: 新しいコンポーネント構造が適切に設計されていることを検証
3. **リグレッション防止**: 既存のテストケースがすべてパスすることを確認
4. **パフォーマンス維持**: 分割前と同等以上のパフォーマンスを確保

## テスト戦略

### テストレベル

```
┌─────────────────────────────────────┐
│  統合テスト (Integration Tests)     │ ← 全体フロー
├─────────────────────────────────────┤
│  ウィジェットテスト (Widget Tests)  │ ← UIコンポーネント
├─────────────────────────────────────┤
│  単体テスト (Unit Tests)            │ ← ロジック/ユーティリティ
└─────────────────────────────────────┘
```

### テストカバレッジ目標

- **全体**: 80%以上
- **ビジネスロジック（Mixins）**: 90%以上
- **ユーティリティ**: 100%
- **UIウィジェット**: 70%以上

## 単体テスト (Unit Tests)

### 1. utils/ui_calculations_test.dart

**テスト対象**: `lib/screens/main/utils/ui_calculations.dart`

**テストケース**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/screens/main/utils/ui_calculations.dart';

void main() {
  group('UiCalculations', () {
    group('calculateTabHeight', () {
      test('小さいフォントサイズ（12.0）の場合、最小高さ32.0を返す', () {
        final height = UiCalculations.calculateTabHeight(12.0);
        expect(height, equals(32.0));
      });

      test('デフォルトフォントサイズ（16.0）の場合、適切な高さを返す', () {
        final height = UiCalculations.calculateTabHeight(16.0);
        expect(height, greaterThanOrEqualTo(32.0));
        expect(height, lessThanOrEqualTo(60.0));
      });

      test('大きいフォントサイズ（24.0）の場合、最大高さ60.0を返す', () {
        final height = UiCalculations.calculateTabHeight(24.0);
        expect(height, equals(60.0));
      });

      test('境界値（20.0）での計算が正しい', () {
        final height = UiCalculations.calculateTabHeight(20.0);
        expect(height, equals(48.0)); // 24 + (20 * 1.2) = 48
      });
    });

    group('calculateTabPadding', () {
      test('小さいフォントサイズ（12.0）の場合、最小パディング6.0を返す', () {
        final padding = UiCalculations.calculateTabPadding(12.0);
        expect(padding, equals(6.0));
      });

      test('デフォルトフォントサイズ（16.0）の場合、基本パディング6.0を返す', () {
        final padding = UiCalculations.calculateTabPadding(16.0);
        expect(padding, equals(6.0));
      });

      test('大きいフォントサイズ（28.0）の場合、最大パディング16.0を返す', () {
        final padding = UiCalculations.calculateTabPadding(28.0);
        expect(padding, equals(16.0));
      });
    });

    group('calculateMaxLines', () {
      test('大きいフォントサイズ（22.0）の場合、1行を返す', () {
        final lines = UiCalculations.calculateMaxLines(22.0);
        expect(lines, equals(1));
      });

      test('中程度のフォントサイズ（19.0）の場合、1行を返す', () {
        final lines = UiCalculations.calculateMaxLines(19.0);
        expect(lines, equals(1));
      });

      test('小さいフォントサイズ（16.0）の場合、2行を返す', () {
        final lines = UiCalculations.calculateMaxLines(16.0);
        expect(lines, equals(2));
      });

      test('境界値（20.0）での判定が正しい', () {
        final lines = UiCalculations.calculateMaxLines(20.0);
        expect(lines, equals(1));
      });

      test('境界値（18.0）での判定が正しい', () {
        final lines = UiCalculations.calculateMaxLines(18.0);
        expect(lines, equals(1));
      });
    });
  });
}
```

**実行コマンド**:
```bash
flutter test test/screens/main/utils/ui_calculations_test.dart
```

---

### 2. mixins/item_operations_mixin_test.dart

**テスト対象**: `lib/screens/main/mixins/item_operations_mixin.dart`

**テストケース**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:maikago/screens/main/mixins/item_operations_mixin.dart';
import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';

// モッククラス
class MockDataProvider extends Mock implements DataProvider {}

void main() {
  group('ItemOperationsMixin', () {
    late MockDataProvider mockDataProvider;

    setUp(() {
      mockDataProvider = MockDataProvider();
    });

    testWidgets('handleCheckToggle - チェック状態を正しく更新する', (tester) async {
      // テスト実装
    });

    testWidgets('handleDelete - アイテムを正しく削除する', (tester) async {
      // テスト実装
    });

    testWidgets('handleUpdate - アイテムを正しく更新する', (tester) async {
      // テスト実装
    });

    testWidgets('handleReorderInc - 未購入アイテムの並べ替えが正しく動作する', (tester) async {
      // テスト実装
    });

    testWidgets('handleReorderCom - 購入済みアイテムの並べ替えが正しく動作する', (tester) async {
      // テスト実装
    });

    testWidgets('エラー時に適切なSnackBarを表示する', (tester) async {
      // エラーハンドリングのテスト
    });
  });
}
```

**実行コマンド**:
```bash
flutter test test/screens/main/mixins/item_operations_mixin_test.dart
```

---

## ウィジェットテスト (Widget Tests)

### 3. widgets/main_app_bar_test.dart

**テスト対象**: `lib/screens/main/widgets/main_app_bar.dart`

**テストケース**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/screens/main/widgets/main_app_bar.dart';
import 'package:maikago/models/shop.dart';

void main() {
  group('MainAppBar', () {
    testWidgets('タブリストが正しく表示される', (tester) async {
      final shops = [
        Shop(id: '1', name: 'ショップ1', items: []),
        Shop(id: '2', name: 'ショップ2', items: []),
        Shop(id: '3', name: 'ショップ3', items: []),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: MainAppBar(
              shops: shops,
              selectedIndex: 0,
              tabController: TabController(length: 3, vsync: tester),
              onTabChanged: () {},
              onAddTab: () {},
            ),
          ),
        ),
      );

      // 全てのタブが表示されることを確認
      expect(find.text('ショップ1'), findsOneWidget);
      expect(find.text('ショップ2'), findsOneWidget);
      expect(find.text('ショップ3'), findsOneWidget);
    });

    testWidgets('選択されたタブが強調表示される', (tester) async {
      final shops = [
        Shop(id: '1', name: 'ショップ1', items: []),
        Shop(id: '2', name: 'ショップ2', items: []),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: MainAppBar(
              shops: shops,
              selectedIndex: 1,
              tabController: TabController(length: 2, vsync: tester),
              onTabChanged: () {},
              onAddTab: () {},
            ),
          ),
        ),
      );

      // 選択されたタブのスタイルを確認
      // ...
    });

    testWidgets('タブ追加ボタンをタップするとコールバックが呼ばれる', (tester) async {
      var addTabCalled = false;
      final shops = [Shop(id: '1', name: 'ショップ1', items: [])];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: MainAppBar(
              shops: shops,
              selectedIndex: 0,
              tabController: TabController(length: 1, vsync: tester),
              onTabChanged: () {},
              onAddTab: () => addTabCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      expect(addTabCalled, isTrue);
    });

    testWidgets('共有グループのタブが正しく表示される', (tester) async {
      final shops = [
        Shop(id: '1', name: 'ショップ1', items: [], sharedGroupId: 'group1'),
        Shop(id: '2', name: 'ショップ2', items: [], sharedGroupId: 'group1'),
        Shop(id: '3', name: 'ショップ3', items: []),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: MainAppBar(
              shops: shops,
              selectedIndex: 0,
              tabController: TabController(length: 3, vsync: tester),
              onTabChanged: () {},
              onAddTab: () {},
            ),
          ),
        ),
      );

      // 共有グループのタブのボーダー表示を確認
      // ...
    });
  });
}
```

**実行コマンド**:
```bash
flutter test test/screens/main/widgets/main_app_bar_test.dart
```

---

### 4. widgets/main_drawer_test.dart

**テスト対象**: `lib/screens/main/widgets/main_drawer.dart`

**テストケース**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maikago/screens/main/widgets/main_drawer.dart';
import 'package:maikago/services/one_time_purchase_service.dart';

void main() {
  group('MainDrawer', () {
    testWidgets('ドロワーヘッダーが正しく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: MainDrawer(
              currentTheme: 'pink',
              onNavigate: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('まいカゴ'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_rounded), findsOneWidget);
    });

    testWidgets('全てのメニューアイテムが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: MainDrawer(
              currentTheme: 'pink',
              onNavigate: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('アプリについて'), findsOneWidget);
      expect(find.text('使い方'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
      // その他のメニューアイテム
    });

    testWidgets('メニューアイテムをタップするとonNavigateが呼ばれる', (tester) async {
      String? navigatedTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: MainDrawer(
              currentTheme: 'pink',
              onNavigate: (destination) => navigatedTo = destination,
            ),
          ),
        ),
      );

      await tester.tap(find.text('アプリについて'));
      expect(navigatedTo, equals('about'));
    });

    testWidgets('トライアル中の場合、残り日数が表示される', (tester) async {
      // モックのOneTimePurchaseServiceを使用
      // ...
    });
  });
}
```

---

### 5. widgets/item_list_section_test.dart

**テスト対象**: `lib/screens/main/widgets/item_list_section.dart`

**テストケース**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/screens/main/widgets/item_list_section.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';

void main() {
  group('ItemListSection', () {
    testWidgets('未購入アイテムが左側に表示される', (tester) async {
      final shop = Shop(
        id: '1',
        name: 'テストショップ',
        items: [
          ListItem(id: '1', name: 'アイテム1', isChecked: false),
          ListItem(id: '2', name: 'アイテム2', isChecked: false),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemListSection(
              shop: shop,
              incItems: shop.items.where((e) => !e.isChecked).toList(),
              comItems: [],
              onCheckToggle: (_, __) {},
              onReorderInc: (_, __) async {},
              onReorderCom: (_, __) async {},
              onEdit: (_) {},
              onDelete: (_) async {},
              onRename: (_) {},
              onUpdate: (_) async {},
              onSort: (_) {},
              onBulkDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('未購入'), findsOneWidget);
      expect(find.text('アイテム1'), findsOneWidget);
      expect(find.text('アイテム2'), findsOneWidget);
    });

    testWidgets('購入済みアイテムが右側に表示される', (tester) async {
      final shop = Shop(
        id: '1',
        name: 'テストショップ',
        items: [
          ListItem(id: '3', name: 'アイテム3', isChecked: true),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemListSection(
              shop: shop,
              incItems: [],
              comItems: shop.items.where((e) => e.isChecked).toList(),
              onCheckToggle: (_, __) {},
              onReorderInc: (_, __) async {},
              onReorderCom: (_, __) async {},
              onEdit: (_) {},
              onDelete: (_) async {},
              onRename: (_) {},
              onUpdate: (_) async {},
              onSort: (_) {},
              onBulkDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('購入済み'), findsOneWidget);
      expect(find.text('アイテム3'), findsOneWidget);
    });

    testWidgets('ソートボタンが機能する', (tester) async {
      var sortCalled = false;
      final shop = Shop(id: '1', name: 'テストショップ', items: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemListSection(
              shop: shop,
              incItems: [],
              comItems: [],
              onCheckToggle: (_, __) {},
              onReorderInc: (_, __) async {},
              onReorderCom: (_, __) async {},
              onEdit: (_) {},
              onDelete: (_) async {},
              onRename: (_) {},
              onUpdate: (_) async {},
              onSort: (_) => sortCalled = true,
              onBulkDelete: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.sort).first);
      expect(sortCalled, isTrue);
    });
  });
}
```

---

### 6. dialogs/tab_add_dialog_test.dart

**テスト対象**: `lib/screens/main/dialogs/tab_add_dialog.dart`

**テストケース**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maikago/screens/main/dialogs/tab_add_dialog.dart';
import 'package:maikago/providers/data_provider.dart';

void main() {
  group('TabAddDialog', () {
    testWidgets('ダイアログが正しく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TabAddDialog.show(context),
                child: const Text('ダイアログ表示'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();

      expect(find.text('タブを追加'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('タブ名を入力して保存できる', (tester) async {
      // モックDataProviderを使用してテスト
      // ...
    });

    testWidgets('空のタブ名では保存できない', (tester) async {
      // バリデーションのテスト
      // ...
    });
  });
}
```

---

## 統合テスト (Integration Tests)

### 7. main_screen_integration_test.dart

**テスト対象**: `lib/screens/main_screen.dart`および全サブコンポーネント

**テストケース**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maikago/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MainScreen 統合テスト', () {
    testWidgets('タブ追加 → アイテム追加 → チェック → 削除のフロー', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. タブを追加
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'テストタブ');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // 2. アイテムを追加
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'テストアイテム');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 3. アイテムをチェック
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // 4. アイテムを削除
      await tester.drag(find.text('テストアイテム'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // 検証
      expect(find.text('テストアイテム'), findsNothing);
    });

    testWidgets('予算設定 → アイテム追加 → 予算オーバー警告のフロー', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 予算を設定
      await tester.tap(find.text('予算変更'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 2. 高額アイテムを追加
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '高額商品');
      await tester.enterText(find.byType(TextField).at(1), '1500');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 3. アイテムをチェック
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // 検証: 予算オーバー警告が表示される
      expect(find.text('⚠ 予算を超えています!'), findsOneWidget);
    });

    testWidgets('テーマ変更が正しく反映される', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ドロワーを開く
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // 設定画面を開く
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();

      // テーマを変更（例: darkテーマ）
      await tester.tap(find.text('ダークテーマ'));
      await tester.pumpAndSettle();

      // 検証: テーマが反映されている
      // ...
    });
  });
}
```

**実行コマンド**:
```bash
flutter test integration_test/main_screen_integration_test.dart
```

---

## 手動テストチェックリスト

### プラットフォーム別テスト

#### iOS
- [ ] iPhone SE（小画面）での表示確認
- [ ] iPhone 14 Pro（中画面）での表示確認
- [ ] iPad（大画面）での表示確認
- [ ] ダークモード切り替え
- [ ] システムフォントサイズ変更時の動作
- [ ] タブ切り替えのアニメーション
- [ ] ReorderableListViewのドラッグ操作
- [ ] キーボード表示時のレイアウト

#### Android
- [ ] Pixel 5（小画面）での表示確認
- [ ] Pixel 7 Pro（大画面）での表示確認
- [ ] タブレット（10インチ）での表示確認
- [ ] ダークモード切り替え
- [ ] システムフォントサイズ変更時の動作
- [ ] タブ切り替えのアニメーション
- [ ] ReorderableListViewのドラッグ操作
- [ ] キーボード表示時のレイアウト

#### Web
- [ ] Chrome（デスクトップ）での表示確認
- [ ] Safari（デスクトップ）での表示確認
- [ ] Firefox（デスクトップ）での表示確認
- [ ] 横幅800px制限の確認
- [ ] レスポンシブ対応の確認
- [ ] マウス操作（ホバー等）
- [ ] キーボードショートカット

#### Windows
- [ ] Windows 11での表示確認
- [ ] ウィンドウリサイズ時の動作
- [ ] マウス操作
- [ ] キーボードショートカット

---

### 機能別テスト

#### タブ管理
- [ ] タブ追加（通常）
- [ ] タブ追加（プレミアム制限あり）
- [ ] タブ編集（名前変更）
- [ ] タブ削除
- [ ] タブ切り替え
- [ ] タブの長押し編集
- [ ] 共有グループタブの表示
- [ ] タブ選択状態の保存・復元

#### アイテム管理
- [ ] アイテム追加（手動入力）
- [ ] アイテム追加（カメラOCR）
- [ ] アイテム追加（レシピインポート）
- [ ] アイテム編集
- [ ] アイテム削除
- [ ] アイテム名前変更
- [ ] アイテムチェック/アンチェック
- [ ] アイテム並べ替え（手動）
- [ ] アイテムソート（自動）
- [ ] 一括削除（未購入）
- [ ] 一括削除（購入済み）

#### 予算管理
- [ ] 予算設定
- [ ] 予算変更
- [ ] 予算クリア
- [ ] 予算オーバー警告表示
- [ ] 残り予算計算
- [ ] 共有グループ予算

#### テーマ/フォント
- [ ] テーマ変更（pink, dark, light, lemon, custom）
- [ ] フォント変更（nunito, noto_sans_jp, murecho）
- [ ] フォントサイズ変更（12～24）
- [ ] カスタムカラー設定
- [ ] テーマ/フォント設定の保存・復元

#### 広告
- [ ] バナー広告の表示
- [ ] インタースティシャル広告の表示
- [ ] プレミアム購入後の広告非表示

#### その他
- [ ] ドロワーメニューの表示
- [ ] 各画面への遷移
- [ ] バージョン更新通知
- [ ] トライアル残り日数表示
- [ ] 初回起動時のウェルカムダイアログ

---

## パフォーマンステスト

### ベンチマーク項目

| 項目 | 分割前 | 分割後 | 目標 |
|------|--------|--------|------|
| 起動時間 | TBD ms | TBD ms | ±10% |
| タブ切り替え | TBD ms | TBD ms | ±5% |
| アイテム追加 | TBD ms | TBD ms | ±5% |
| リストスクロール（FPS） | TBD fps | TBD fps | 60 fps維持 |
| メモリ使用量 | TBD MB | TBD MB | ±10% |
| ビルドメソッド呼び出し回数 | TBD 回 | TBD 回 | 削減 |

### 測定方法

```bash
# パフォーマンスプロファイリング
flutter run --profile --trace-startup

# メモリ使用量確認
flutter run --profile
# DevToolsでメモリプロファイリング

# FPS測定
flutter run --profile
# DevToolsでパフォーマンスオーバーレイ表示
```

---

## 静的分析

### 実行コマンド

```bash
# 静的分析実行
flutter analyze

# フォーマット確認
flutter format --dry-run --set-exit-if-changed .

# 未使用import検出
dart analyze --fatal-infos
```

### チェック項目

- [ ] `flutter analyze`でエラーゼロ
- [ ] `flutter analyze`で警告ゼロ（可能な限り）
- [ ] コードフォーマットが統一されている
- [ ] 未使用importがない
- [ ] TODOコメントが残っていない（または対応済み）
- [ ] デッドコードがない

---

## テスト実行手順

### 1. 単体テスト実行

```bash
# 全単体テスト実行
flutter test

# 特定ファイルのテスト実行
flutter test test/screens/main/utils/ui_calculations_test.dart

# カバレッジレポート生成
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 2. ウィジェットテスト実行

```bash
# 全ウィジェットテスト実行
flutter test test/screens/main/widgets/

# 特定ウィジェットのテスト実行
flutter test test/screens/main/widgets/main_app_bar_test.dart
```

### 3. 統合テスト実行

```bash
# iOS統合テスト
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/main_screen_integration_test.dart \
  -d iPhone

# Android統合テスト
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/main_screen_integration_test.dart \
  -d emulator-5554

# Web統合テスト
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/main_screen_integration_test.dart \
  -d chrome
```

### 4. 手動テスト実行

```bash
# デバッグビルド起動
flutter run

# リリースビルドでテスト（パフォーマンス確認）
flutter run --release
```

---

## テスト結果の記録

### テスト実行結果テンプレート

```markdown
## テスト実行結果

**実行日**: 2026-XX-XX
**実行者**: XXX
**ブランチ**: feature/issue-5-main-screen-split

### 単体テスト
- 総テスト数: XX
- 成功: XX
- 失敗: XX
- カバレッジ: XX%

### ウィジェットテスト
- 総テスト数: XX
- 成功: XX
- 失敗: XX

### 統合テスト
- 総テスト数: XX
- 成功: XX
- 失敗: XX

### 手動テスト
- iOS: ✅ / ❌
- Android: ✅ / ❌
- Web: ✅ / ❌
- Windows: ✅ / ❌

### パフォーマンステスト
- 起動時間: XXX ms (分割前: XXX ms)
- タブ切り替え: XXX ms (分割前: XXX ms)
- メモリ使用量: XXX MB (分割前: XXX MB)

### 静的分析
- `flutter analyze`: ✅ / ❌
- `flutter format`: ✅ / ❌

### 備考
- XXX
```

---

## リグレッションテスト

分割前の既存機能が正常に動作することを確認するため、以下のテストを実施:

### 既存テストの実行

```bash
# 既存の全テストを実行
flutter test

# 特定のテストスイート実行
flutter test test/providers/data_provider_test.dart
flutter test test/services/
```

### 期待結果
- 既存のすべてのテストがパスすること
- 新しいエラーや警告が発生しないこと

---

## 不具合発見時の対応

### 優先度

- **P0（緊急）**: アプリがクラッシュする、データが消失する
- **P1（高）**: 主要機能が動作しない
- **P2（中）**: 一部機能が動作しない、UI表示が崩れる
- **P3（低）**: 軽微な表示問題、パフォーマンス劣化

### 報告フォーマット

```markdown
**優先度**: P0 / P1 / P2 / P3
**発生環境**: iOS / Android / Web / Windows
**再現手順**:
1. XXX
2. XXX
3. XXX

**期待される動作**: XXX
**実際の動作**: XXX
**スクリーンショット/ログ**: (添付)
```

---

## テスト完了基準

以下の条件をすべて満たした場合、テスト完了とする:

- [ ] 単体テストカバレッジ80%以上
- [ ] ウィジェットテスト全通過
- [ ] 統合テスト全通過
- [ ] 手動テスト（全プラットフォーム）全通過
- [ ] パフォーマンステスト合格（分割前±10%以内）
- [ ] 静的分析エラーゼロ
- [ ] 既存テスト全通過
- [ ] P0, P1不具合ゼロ
- [ ] P2不具合が修正済みまたは既知の問題として文書化
- [ ] コードレビュー承認
