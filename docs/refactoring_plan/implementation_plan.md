# まいカゴ リファクタリング計画書

## 概要

「まいカゴ」Flutterプロジェクトの責務分離とモジュール化を目的としたリファクタリング計画。巨大ファイルの分割、Provider層の責務分離、サービス層の整理を段階的に実施する。

---

## プロジェクト構造分析

### 現在の構成

```
lib/
├── main.dart                    (368行) - アプリエントリ、テーマ管理
├── ad/                          (3ファイル)
│   ├── ad_banner.dart           - バナー広告
│   ├── app_open_ad_service.dart - アプリオープン広告
│   └── interstitial_ad_service.dart - インタースティシャル広告
├── drawer/                      (7+8ファイル)
│   ├── about_screen.dart        (27KB)
│   ├── calculator_screen.dart   (22KB)
│   ├── donation_screen.dart     (34KB)
│   ├── feedback_screen.dart     (18KB)
│   ├── maikago_premium.dart     (29KB)
│   ├── upcoming_features_screen.dart
│   ├── usage_screen.dart        (23KB)
│   └── settings/                (8ファイル)
├── models/                      (7ファイル)
│   ├── list.dart               (174行) - ListItem
│   ├── shop.dart               (157行) - Shop
│   ├── sort_mode.dart          - ソートモード
│   ├── donation.dart, one_time_purchase.dart, etc.
├── providers/                   (2ファイル)
│   ├── auth_provider.dart       (190行) - 認証状態管理
│   └── data_provider.dart       (1,575行) ⚠️ 巨大
├── screens/                     (8ファイル)
│   ├── main_screen.dart         (3,530行) ⚠️ 最大
│   ├── camera_screen.dart       (19KB)
│   ├── enhanced_camera_screen.dart (16KB)
│   ├── login_screen.dart        (10KB)
│   └── その他画面
├── services/                    (14ファイル)
│   ├── chatgpt_service.dart     (1,383行) ⚠️ 大
│   ├── data_service.dart        (677行)
│   ├── hybrid_ocr_service.dart
│   ├── vision_ocr_service.dart
│   └── その他サービス
├── utils/                       (2ファイル)
└── widgets/                     (6ファイル)
```

---

## 主要ファイルの責務分析

### 1. `main_screen.dart` (3,530行, 58関数/クラス)

| クラス/メソッド | 責務 | 問題点 |
|----------------|------|--------|
| `_MainScreenState` | タブUI、ダイアログ、OCR統合、テーマ管理 | 2,600行超、複数責務が混在 |
| `showAddTabDialog` | タブ追加ダイアログ | ビジネスロジックとUIが混在 |
| `showItemEditDialog` | アイテム編集 (300行) | 別ファイルに切り出し可能 |
| `showTabEditDialog` | タブ編集 (200行) | 別ファイルに切り出し可能 |
| `_reorderIncItems/ComItems` | 並べ替え処理 (各100行) | ロジックをProviderへ移動可 |
| `_BudgetDialog` | 予算設定ダイアログ | 独立ウィジェット化 |
| `BottomSummary` | 合計表示、OCR連携 (650行) | 複数機能が混在 |

### 2. `data_provider.dart` (1,575行, 42メソッド)

| 責務グループ | メソッド例 | 推奨分離先 |
|-------------|-----------|-----------|
| アイテムCRUD | `addItem`, `updateItem`, `deleteItem`, `deleteItems` | `ItemProvider` |
| ショップCRUD | `addShop`, `updateShop`, `deleteShop` | `ShopProvider` |
| リアルタイム同期 | `_startRealtimeSync`, `_cancelRealtimeSync` | `SyncService` |
| 共有グループ | `updateSharedGroup`, `removeFromSharedGroup` | `SharedGroupProvider` |
| データロード | `loadData`, `_loadItems`, `_loadShops` | `DataRepository` |

### 3. `chatgpt_service.dart` (1,383行, 14メソッド)

| 責務 | 推奨改善 |
|------|---------|
| OCRテキスト解析 | `OcrTextParser` クラスに分離 |
| 価格候補抽出 | `PriceCandidateExtractor` に分離 |
| OpenAI API呼び出し | `OpenAiApiClient` に分離 |

---

## リファクタリングポイント一覧（優先順位付き）

### 優先度 ★★★（高）

| # | 項目 | 理由 | 影響範囲 |
|---|------|------|---------|
| 1 | `main_screen.dart` UI分割 | 最大ファイル、保守困難 | 全UI |
| 2 | `data_provider.dart` 分割 | 責務過多、テスト困難 | データ操作全般 |
| 3 | ダイアログの独立ファイル化 | 再利用性向上 | 各ダイアログ使用箇所 |

### 優先度 ★★（中）

| # | 項目 | 理由 | 影響範囲 |
|---|------|------|---------|
| 4 | Repository層の導入 | テスト容易性向上 | データアクセス |
| 5 | OCR/広告サービスの初期化一元化 | ライフサイクル管理 | 各サービス |
| 6 | テーマ/フォント管理の整理 | グローバル状態の明確化 | main.dart、設定画面 |

### 優先度 ★（低）

| # | 項目 | 理由 | 影響範囲 |
|---|------|------|---------|
| 7 | `chatgpt_service.dart` 分割 | 可読性向上 | OCR処理 |
| 8 | パフォーマンス最適化 | notifyListeners頻発抑制 | 全体 |
| 9 | Riverpod移行検討 | 状態管理の改善（オプション） | 全Provider |

---

## 改善詳細

### フェーズ1: UI分割（`main_screen.dart` → 8ファイル）

#### [NEW] `lib/screens/main/main_screen.dart`
- メイン画面のコアロジックのみ保持（約300行目標）
- TabControllerの管理
- 各サブウィジェットの組み立て

#### [NEW] `lib/screens/main/widgets/tab_bar_widget.dart`
- タブバーUI部分を分離
- タブ追加/編集ボタン

#### [NEW] `lib/screens/main/widgets/item_list_widget.dart`
- 未購入/購入済みリスト表示（共通化）
- ReorderableListViewのラッパー

#### [NEW] `lib/screens/main/widgets/bottom_summary_widget.dart`
- 合計表示部分のみ
- OCRボタンは別ウィジェットへ

#### [NEW] `lib/screens/main/dialogs/budget_dialog.dart`
- 予算設定ダイアログ

#### [NEW] `lib/screens/main/dialogs/item_edit_dialog.dart`
- アイテム編集ダイアログ（約300行）

#### [NEW] `lib/screens/main/dialogs/tab_edit_dialog.dart`
- タブ編集ダイアログ（約200行）

#### [NEW] `lib/screens/main/dialogs/sort_dialog.dart`
- ソート選択ダイアログ

---

### フェーズ2: Provider分割（`data_provider.dart` → 4ファイル）

#### [NEW] `lib/providers/item_provider.dart`

```dart
class ItemProvider extends ChangeNotifier {
  // アイテムCRUD
  Future<void> addItem(ListItem item);
  Future<void> updateItem(ListItem item);
  Future<void> deleteItem(String itemId);
  Future<void> deleteItems(List<String> itemIds);
  Future<void> updateItemsBatch(List<ListItem> items);
}
```

#### [NEW] `lib/providers/shop_provider.dart`

```dart
class ShopProvider extends ChangeNotifier {
  // ショップCRUD
  Future<void> addShop(Shop shop);
  Future<void> updateShop(Shop shop);
  Future<void> deleteShop(String shopId);
  void updateShopName(int index, String newName);
  void updateShopBudget(int index, int? budget);
}
```

#### [NEW] `lib/providers/sync_provider.dart`

```dart
class SyncProvider extends ChangeNotifier {
  // リアルタイム同期管理
  void startRealtimeSync();
  void cancelRealtimeSync();
  bool get isSynced;
}
```

#### [MODIFY] `lib/providers/data_provider.dart`
- 分割後は各Providerを統合するFacadeとして機能
- 既存のAPI互換性を維持（段階的移行のため）

---

### フェーズ3: サービス層の整理

#### [NEW] `lib/repositories/item_repository.dart`

```dart
abstract class ItemRepository {
  Future<List<ListItem>> getItems();
  Future<void> saveItem(ListItem item);
  Future<void> updateItem(ListItem item);
  Future<void> deleteItem(String id);
}

class FirestoreItemRepository implements ItemRepository {
  // Firestore実装
}
```

#### [NEW] `lib/repositories/shop_repository.dart`
- 同様にShop用のリポジトリを作成

#### [NEW] `lib/services/service_locator.dart`
- サービスの初期化/破棄を一元管理
- OCR、広告、認証サービスのライフサイクル管理

---

### フェーズ4: パフォーマンス最適化

| 改善項目 | 変更内容 | 期待効果 |
|---------|---------|---------|
| TabController最適化 | dispose/再生成の頻度削減 | メモリ効率向上 |
| notifyListeners抑制 | 差分比較による呼び出し削減 | 不要な再描画防止 |
| ListView最適化 | `cacheExtent`設定、`const`化 | スクロール性能向上 |
| メモ化導入 | 計算済み値のキャッシュ | CPU負荷軽減 |

---

## コミット戦略

### ブランチ構成

```
main
└── refactor/main-screen-split     ← フェーズ1
    ├── refactor/extract-tab-bar
    ├── refactor/extract-item-list
    ├── refactor/extract-dialogs
    └── refactor/extract-bottom-summary
└── refactor/provider-split        ← フェーズ2
    ├── refactor/item-provider
    ├── refactor/shop-provider
    └── refactor/sync-provider
└── refactor/service-layer         ← フェーズ3
└── refactor/performance           ← フェーズ4
```

### コミット単位

1. 各ウィジェット/クラスの切り出しは1コミット
2. 切り出し後のインポート修正は同一コミット内
3. テスト追加は別コミット
4. ビルドが通ることを各コミットで確認

---

## 検証計画

### 自動テスト

> [!WARNING]
> 現在、`test/` ディレクトリが存在せず、既存のユニットテストはありません。
> リファクタリング実施時に、分割した各コンポーネントに対してテストを新規作成する必要があります。

#### 新規テスト作成予定

| テスト対象 | テスト内容 | コマンド |
|-----------|-----------|---------|
| `ItemProvider` | アイテムCRUD操作 | `flutter test test/providers/item_provider_test.dart` |
| `ShopProvider` | ショップCRUD操作 | `flutter test test/providers/shop_provider_test.dart` |
| `ItemRepository` | Firestoreモック連携 | `flutter test test/repositories/item_repository_test.dart` |

### 手動検証

> [!IMPORTANT]
> 既存のUIテストがないため、以下の手動検証が必須です。

#### 検証ステップ

1. **アプリ起動確認**
   ```bash
   flutter run -d android
   # または
   flutter run -d chrome
   ```
   - スプラッシュ画面 → ログイン画面 → メイン画面の遷移確認

2. **タブ操作**
   - タブ追加/編集/削除が正常動作すること
   - タブ切り替えでデータが正しく表示されること

3. **アイテム操作**
   - アイテム追加/編集/削除が正常動作すること
   - チェック状態の切り替えが反映されること
   - 並べ替え（ドラッグ&ドロップ）が動作すること

4. **合計/予算表示**
   - BottomSummaryの金額計算が正確であること
   - 共有グループモードでの合計が正しいこと

5. **OCR機能**
   - カメラ起動 → 撮影 → 解析 → アイテム追加の一連フロー

6. **ビルド確認**
   ```bash
   flutter build apk --release
   flutter build web
   ```

---

## 想定リスクと対策

| リスク | 対策 |
|--------|------|
| 既存機能の破壊 | 各フェーズで手動検証、段階的マージ |
| Provider間の依存関係エラー | Facadeパターンで既存API維持 |
| パフォーマンス悪化 | 変更前後のプロファイリング比較 |
| マージコンフリクト | 小さなコミット単位、頻繁なrebase |

---

## 次のアクション

1. **ユーザー承認後**、まずフェーズ1（UI分割）から着手
2. 各フェーズ完了時に動作確認レポートを作成
3. 問題発生時は該当コミットをrevert

> [!NOTE]
> この計画は分析フェーズの成果物です。コード変更はユーザー承認後に実施します。
