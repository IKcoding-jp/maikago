# 要件定義: アーキテクチャ整理（デッドコード削除・レイヤー統一・ナビゲーション統一）

**Issue**: #88
**ラベル**: refactor, major
**作成日**: 2026-02-20

## 背景

複数のLLMによるバイブコーディングの結果、以下のアーキテクチャ上の問題が蓄積された:
- Service層のバイパス（未使用Serviceクラスの残存）
- ナビゲーションパターンの混在（Navigator vs go_router）
- レイヤー違反（UI層からの内部状態直接操作）
- デッドコード・不要な依存性の残存

## 要件一覧

### High Priority

| ID | 要件 | 対象ファイル |
|----|------|-------------|
| H-1 | 未使用の `ItemService` を削除 | `lib/services/item_service.dart`, `test/services/item_service_test.dart` |
| H-2 | 未使用の `ShopService` を削除 | `lib/services/shop_service.dart`, `test/services/shop_service_test.dart` |
| H-3 | `LoginScreen` の `AuthService` 直接インスタンス化を `AuthProvider` 経由に変更 | `lib/screens/login_screen.dart` |

### Medium Priority

| ID | 要件 | 対象ファイル |
|----|------|-------------|
| M-1 | `Navigator.pop()` 等を `context.pop()` に統一（go_router） | 複数の画面ファイル |
| M-2 | `DataProviderState` の `notifyListeners` バッチ更新制御を文書化/リファクタ | `lib/providers/data_provider_state.dart` |
| M-3 | `ListItem`, `Shop` モデルに `==` 演算子と `hashCode` を実装 | `lib/models/list.dart`, `lib/models/shop.dart` |
| M-4 | `DebugService` から不要な `ChangeNotifier` 継承を削除 | `lib/services/debug_service.dart` |

### Low Priority

| ID | 要件 | 対象ファイル |
|----|------|-------------|
| L-1 | `router.dart` の `extra` 経由の冗長パラメータ渡しを削除 | `lib/router.dart`, 各画面 |
| L-2 | `SharedGroupManager` の不要な `await` を削除 | `lib/providers/managers/shared_group_manager.dart` |
| L-3 | `ItemOperations` の `DataProvider.shops` 直接変更をファサード経由に修正 | `lib/screens/main/utils/item_operations.dart` |

## 非機能要件

- 既存の動作を変更しない（リファクタリングのみ）
- `flutter analyze` エラーゼロ
- `flutter test` 全テスト通過
- レイヤー構造: 画面 → Provider → Service → Firestore の一貫性を維持

## 受入基準

1. 未使用の Service クラス（ItemService, ShopService）がコードベースから完全に削除されている
2. LoginScreen が AuthProvider 経由で認証を行っている
3. 全画面でナビゲーションが go_router（context.pop/push/go）に統一されている
4. モデルクラスに値等価性が実装されている
5. DebugService が ChangeNotifier に依存していない
6. 全テストが通過し、Lintエラーがない
