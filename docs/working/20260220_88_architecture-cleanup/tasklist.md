# タスクリスト: アーキテクチャ整理

**Issue**: #88
**ステータス**: 未着手
**作成日**: 2026-02-20

---

## Phase 1: デッドコード削除（High）

- [ ] **H-1**: `lib/services/item_service.dart` を削除
- [ ] **H-1**: `test/services/item_service_test.dart` を削除
- [ ] **H-2**: `lib/services/shop_service.dart` を削除
- [ ] **H-2**: `test/services/shop_service_test.dart` を削除
- [ ] 静的分析で未使用インポートがないことを確認

## Phase 2: レイヤー違反修正（High）

- [ ] **H-3**: `login_screen.dart` の `AuthService` 直接インスタンス化を削除
- [ ] **H-3**: `AuthProvider` 経由でログイン処理を呼び出すように修正

## Phase 3: ナビゲーション統一（Medium）

- [ ] **M-1**: `Navigator.pop()` / `Navigator.of(context).pop()` の全使用箇所を特定
- [ ] **M-1**: 各ファイルで `context.pop()` に置き換え
  - `calculator_screen.dart`
  - `main_drawer.dart`
  - `recipe_confirm_screen.dart`
  - `ocr_result_confirm_screen.dart`
  - その他の画面ファイル
- [ ] go_router のインポート追加（`import 'package:go_router/go_router.dart'`）

## Phase 4: モデル改善（Medium）

- [ ] **M-3**: `ListItem` に `==` 演算子と `hashCode` を実装
- [ ] **M-3**: `Shop` に `==` 演算子と `hashCode` を実装
- [ ] **M-4**: `DebugService` から `ChangeNotifier` 継承を削除

## Phase 5: 状態管理改善（Medium）

- [ ] **M-2**: `DataProviderState` の `notifyListeners` バッチ更新制御にコメント/文書化を追加

## Phase 6: 細かい改善（Low）

- [ ] **L-1**: `router.dart` の `extra` 冗長パラメータを削除し、Provider から直接読み取りに変更
- [ ] **L-2**: `SharedGroupManager.getDisplayTotal()` を同期メソッドに変更
- [ ] **L-2**: `getSharedGroupTotal()` も同期メソッドに変更
- [ ] **L-2**: 呼び出し元の `await` を削除
- [ ] **L-3**: `ItemOperations` の `dataProvider.shops` 直接変更をファサードメソッド経由に修正

## Phase 7: 検証

- [ ] `flutter analyze` エラーゼロ
- [ ] `flutter test` 全テスト通過
