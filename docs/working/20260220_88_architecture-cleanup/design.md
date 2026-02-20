# 設計書: アーキテクチャ整理

**Issue**: #88
**作成日**: 2026-02-20

---

## 1. デッドコード削除（H-1, H-2）

### 現状
- `ItemService` と `ShopService` は実装されているが、`lib/` 内のどこからもインポートされていない
- `ItemRepository` と `ShopRepository` が同等の機能を実装済み
- テストファイルのみが存在

### 修正方針
- **ファイル削除**: `item_service.dart`, `shop_service.dart` とそのテストを完全に削除
- 影響なし（未使用のため）

---

## 2. AuthService DI 統一（H-3）

### 現状
```dart
// login_screen.dart:19
final AuthService _authService = AuthService();
```
- LoginScreen が AuthService を直接インスタンス化
- AuthProvider も同じ方法でインスタンス化（auth_provider.dart:39）

### 修正方針
- LoginScreen で `AuthProvider` 経由でログイン操作を実行
- `context.read<AuthProvider>()` を使用して Provider を取得
- `_authService.signInWithGoogle()` → `authProvider.signInWithGoogle()` に変更
- AuthProvider に必要なメソッドが不足している場合は追加

---

## 3. ナビゲーション統一（M-1）

### 現状
- go_router 導入済みだが、`Navigator.pop()` が多数残存
- `Navigator.pop(context)` と `context.pop()` が混在

### 修正方針
- 全ファイルで `Navigator.pop(context)` → `context.pop()` に置き換え
- `Navigator.pop(context, value)` → `context.pop(value)` に置き換え
- `Navigator.of(context).pop()` → `context.pop()` に置き換え
- go_router のインポートを追加: `import 'package:go_router/go_router.dart';`

### 注意点
- `showDialog` / `showModalBottomSheet` 内の `Navigator.pop()` は go_router ではなく Flutter のオーバーレイ機構のため、`Navigator.pop()` のまま残す場合もある
- ただし `context.pop()` でも動作する（go_router は Navigator に委譲）ため、統一して問題なし

---

## 4. モデル値等価性（M-3）

### 現状
- `ListItem` と `Shop` は参照比較のみ
- Equatable パッケージは未導入

### 修正方針
- 手動で `==` 演算子と `hashCode` を実装（新規パッケージ追加を避ける）
- `ListItem`: `id` を主キーとした等価性
- `Shop`: `id` を主キーとした等価性

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is ListItem && runtimeType == other.runtimeType && id == other.id;

@override
int get hashCode => id.hashCode;
```

### 設計判断
- 全フィールド比較ではなく `id` ベースの等価性を採用
- 理由: Firestore ドキュメントIDで一意性が保証されている

---

## 5. DebugService 簡素化（M-4）

### 現状
```dart
class DebugService extends ChangeNotifier {
```
- `ChangeNotifier` の機能（`addListener`, `notifyListeners`）を一切使用していない

### 修正方針
- `extends ChangeNotifier` を削除
- シングルトンパターンはそのまま維持

---

## 6. DataProviderState 文書化（M-2）

### 修正方針
- `isBatchUpdating` フラグの使い方にコメントを追加
- `notifyListeners` の呼び出しパターンを文書化
- 動作の変更は行わない

---

## 7. router.dart extra 削減（L-1）

### 現状
- `CalculatorScreen`, `ReleaseHistoryScreen` 等に `extra` でテーマ情報を渡している
- フォールバックで結局 `ThemeProvider` から読み取っている

### 修正方針
- テーマ関連の `extra` パラメータを削除
- 各画面内で `context.read<ThemeProvider>()` から直接取得
- アイテムデータ等、画面固有のパラメータは `extra` を維持

---

## 8. SharedGroupManager 同期化（L-2）

### 現状
- `getDisplayTotal()` に不要な `await Future.delayed(Duration(milliseconds: 10))`
- 計算自体は同期的

### 修正方針
- `Future<int> getDisplayTotal()` → `int getDisplayTotal()` に変更
- `Future<int> getSharedGroupTotal()` → `int getSharedGroupTotal()` に変更
- 呼び出し元の `await` を削除

---

## 9. ItemOperations ファサード経由化（L-3）

### 現状
- `dataProvider.shops[shopIndex] = ...` でショップリストを直接変更
- DataProvider のカプセル化を破壊

### 修正方針
- DataProvider にショップ更新メソッドを追加
- ItemOperations からファサード経由で更新
