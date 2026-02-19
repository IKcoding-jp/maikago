# 設計書

## 実装方針

### 原則
- 既存の動作を変更しない（パフォーマンス改善のみ）
- Provider パターンは維持（Riverpod等への移行は行わない）
- 段階的に修正し、各フェーズ後にテストを実行

### 変更対象ファイル

#### フェーズ1（高優先度）

| ファイル | 変更内容 |
|---------|---------|
| `lib/screens/main_screen.dart` | Consumer2→Selector分割、TabController移動、ソートキャッシュ |
| `lib/screens/drawer/settings/advanced_settings_screen.dart` | FutureBuilder修正、_getCurrentThemeキャッシュ |

#### フェーズ2（中優先度）

| ファイル | 変更内容 |
|---------|---------|
| `lib/screens/drawer/settings/settings_screen.dart` | 空setState修正、_getCurrentThemeキャッシュ |
| `lib/screens/drawer/settings/advanced_settings_screen.dart` | 空setState修正 |
| `lib/screens/recipe_confirm_screen.dart` | Provider.of → context.read |
| `lib/screens/main/widgets/main_app_bar.dart` | 不要Consumer2除去 |
| `lib/screens/main/widgets/bottom_summary_widget.dart` | 非同期処理最適化 |
| `lib/router.dart` | ThemeDataキャッシュ利用 |

#### フェーズ3（Firestore）

| ファイル | 変更内容 |
|---------|---------|
| `lib/services/data_service.dart` | deleteShop()のWriteBatch化 |
| `lib/providers/repositories/item_repository.dart` | バッチ更新のWriteBatch化 |

#### フェーズ4（低優先度）

| ファイル | 変更内容 |
|---------|---------|
| `lib/screens/main/widgets/item_list_section.dart` | cacheExtent調整 |

### 新規作成ファイル
なし

## 設計詳細

### 1. MainScreen のリビルド最適化

**現状**:
```dart
// main_screen.dart:301
return Consumer2<DataProvider, AuthProvider>(
  builder: (context, dataProvider, authProvider, child) {
    // Scaffold全体がここでビルドされる
  },
);
```

**改善案**:
```dart
// Selectorで必要なデータのみ監視
final shops = context.select<DataProvider, List<Shop>>((dp) => dp.shops);
final isLoading = context.select<DataProvider, bool>((dp) => dp.isLoading);
// AuthProviderは除去（build内で未使用）
```

### 2. TabController の移動

**現状**: build()内でdispose+再作成
**改善案**: didChangeDependenciesまたはProviderリスナーのコールバック内で処理

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final shops = context.read<DataProvider>().shops;
  if (tabController.length != shops.length) {
    _recreateTabController(shops.length);
  }
}
```

### 3. context.select の導入パターン

```dart
// 特定のプロパティのみ監視
final shopCount = context.select<DataProvider, int>((dp) => dp.shops.length);

// リスト全体ではなく特定ショップのアイテム数のみ
final itemCount = context.select<DataProvider, int>(
  (dp) => dp.shops[index].items.length,
);
```

### 4. FutureBuilder の修正

**現状**:
```dart
FutureBuilder<bool>(
  future: _getAutoCompleteEnabled(), // 毎回新しいFuture
  builder: ...
)
```

**改善案**:
```dart
late Future<bool> _autoCompleteFuture;

@override
void initState() {
  super.initState();
  _autoCompleteFuture = _getAutoCompleteEnabled();
}

// build内
FutureBuilder<bool>(
  future: _autoCompleteFuture, // 保存済みFuture
  builder: ...
)

// 値の更新時
void _onToggle() {
  setState(() {
    _autoCompleteFuture = _getAutoCompleteEnabled();
  });
}
```

## 影響範囲

- **Provider依存関係**: Consumer2→Selectorへの変更はAPIの変更なし（消費側のみ）
- **プラットフォーム分岐**: なし（全プラットフォーム共通の変更）
- **data_provider.dart**: ファサードの外部インターフェースは変更なし
- **テーマ**: ThemeData生成ロジックは変更なし、呼び出しパターンのみ変更

## Flutter固有の注意点

- `context.select`はbuild()内でのみ使用可能（イベントハンドラ内ではcontext.readを使用）
- `TabController`のライフサイクル管理はTickerProviderStateMixinに依存
- `Selector`ウィジェットとcontext.select()は機能的に同等だが、context.select()の方がコードが簡潔
- WriteBatchは最大500操作まで対応（現在のアイテム数では十分）
