# まいカゴ サブスクリプション機能 テストスイート

## 概要

このディレクトリには、まいカゴアプリのサブスクリプション機能に関する包括的なテストスイートが含まれています。

## テスト構成

### 1. サービス層テスト

#### `services/subscription_manager_test.dart`
- **対象**: `SubscriptionManager`クラス
- **テスト内容**:
  - プラン管理（Free, Basic, Premium, Family）
  - サブスクリプション処理
  - 家族共有機能
  - データ永続化
  - エラーハンドリング
  - 境界値テスト

#### `services/feature_access_control_test.dart`
- **対象**: `FeatureAccessControl`クラス
- **テスト内容**:
  - 機能アクセス制御
  - 制限チェック
  - 使用状況サマリー
  - エラーハンドリング
  - 境界値テスト

### 2. UI層テスト

#### `widgets/migration_status_widget_test.dart`
- **対象**: `MigrationStatusWidget`クラス
- **テスト内容**:
  - 表示テスト（新規ユーザー、既存寄付者、移行案内）
  - インタラクションテスト
  - 状態表示テスト
  - アイコンと色のテスト
  - エラーハンドリング
  - レスポンシブデザインテスト

### 3. 統合テスト

#### `integration/subscription_integration_test.dart`
- **対象**: 複数サービスの連携
- **テスト内容**:
  - サービス連携テスト
  - プラン変更テスト
  - 家族共有機能テスト
  - 移行機能テスト
  - データ永続化テスト
  - エラーハンドリング
  - パフォーマンステスト
  - 境界値テスト

## テスト実行方法

### 1. 全テストの実行

```bash
flutter test
```

### 2. 特定のテストファイルの実行

```bash
# SubscriptionManagerのテスト
flutter test test/services/subscription_manager_test.dart

# FeatureAccessControlのテスト
flutter test test/services/feature_access_control_test.dart

# MigrationStatusWidgetのテスト
flutter test test/widgets/migration_status_widget_test.dart

# 統合テスト
flutter test test/integration/subscription_integration_test.dart
```

### 3. テストカバレッジの確認

```bash
flutter test --coverage
```

### 4. モックファイルの生成

```bash
flutter packages pub run build_runner build
```

## テストカバレッジ

### 目標カバレッジ
- **単体テスト**: 90%以上
- **統合テスト**: 80%以上
- **UIテスト**: 70%以上

### カバレッジ対象
- 正常系の動作
- 異常系の処理
- 境界値の処理
- エラーハンドリング
- データ永続化
- UI表示とインタラクション

## テストデータ

### プラン定義
- **Free**: 3リスト、基本機能のみ
- **Basic**: 10リスト、テーマ・フォント・広告削除
- **Premium**: 50リスト、分析機能追加
- **Family**: 100リスト、家族共有機能

### テストユーザー
- **新規ユーザー**: 寄付なし、サブスクリプションなし
- **既存寄付者**: 300円以上寄付済み
- **サブスクリプション利用者**: 各プランの利用者

## モックオブジェクト

### 使用ライブラリ
- `mockito`: モックオブジェクトの生成
- `build_runner`: モックファイルの自動生成

### モック対象
- `SharedPreferences`
- `FirebaseFirestore`
- `SubscriptionIntegrationService`
- `InAppPurchaseService`

## CI/CD統合

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter packages pub run build_runner build
```

### テスト結果の通知
- テスト失敗時のSlack通知
- カバレッジレポートの生成
- テスト実行時間の記録

## トラブルシューティング

### よくある問題

#### 1. モックファイルが見つからない
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 2. SharedPreferencesのエラー
```dart
// テストファイルの先頭に追加
SharedPreferences.setMockInitialValues({});
```

#### 3. Providerのエラー
```dart
// テストウィジェットでProviderを適切に設定
ChangeNotifierProvider<Service>.value(
  value: mockService,
  child: TestWidget(),
)
```

### デバッグ方法

#### 1. 詳細なログ出力
```bash
flutter test --verbose
```

#### 2. 特定のテストの実行
```bash
flutter test --name "テスト名"
```

#### 3. テストファイルの監視
```bash
flutter test --watch
```

## ベストプラクティス

### 1. テストの書き方
- テスト名は具体的で分かりやすく
- 各テストは独立して実行可能
- 適切なセットアップとクリーンアップ
- モックオブジェクトの適切な使用

### 2. カバレッジの向上
- 境界値のテスト
- エラーケースのテスト
- 異常系の処理
- UIの状態変化

### 3. パフォーマンス
- テストの実行時間を短縮
- 不要なモックの削除
- 効率的なテストデータの使用

## 今後の拡張予定

### 1. 追加予定のテスト
- PaymentServiceのテスト
- 決済処理の統合テスト
- パフォーマンステストの拡張
- セキュリティテスト

### 2. テストツールの改善
- テストデータの自動生成
- テストレポートの改善
- カバレッジレポートの詳細化

### 3. CI/CDの強化
- 自動テスト実行の最適化
- テスト結果の可視化
- 品質ゲートの設定
