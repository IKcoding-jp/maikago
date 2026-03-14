# 設計書

## 実装方針

### A1: 課金テストの設計

#### テスト手法
- **Fake実装パターン**を採用（`feature_access_control_test.dart` のFakeOneTimePurchaseServiceを参考）
- Firebase/InAppPurchase に強く依存するため Mockito ではなく手動Fake
- `SharedPreferences.setMockInitialValues({})` でローカルストレージをモック

#### TrialManager テスト設計
```
TrialManager(onStateChanged: callback)
├── startTrial(7) → isTrialActive == true, endDate == now + 7日
├── endTrial() → isTrialActive == false
├── checkAndExpireIfNeeded() → 期限切れ時に自動終了
└── startTrial(7) [2回目] → 二重開始防止（isTrialEverStarted）
```

#### PurchasePersistence テスト設計
```
PurchasePersistence
├── saveToLocalStorage() → loadFromLocalStorage() 往復
├── レガシーキー互換 → premium_unlocked からの移行
└── Firestore操作 → FakeFirestore or モック
```

### A2: 認証テストの設計

#### FakeAuthService 設計
```dart
class FakeAuthService {
  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  // テストから状態を制御
  void setUser(User? user) { ... }

  // AuthService のインターフェースを実装
  Future<UserCredential?> signInWithGoogle() async { ... }
  Future<void> signOut() async { ... }
  Stream<User?> get authStateChanges => _authStateController.stream;
}
```

#### AuthProvider テスト設計
```
AuthProvider(authService, purchaseService, featureControl)
├── 初期状態: isLoggedIn == false, isGuestMode == false
├── enterGuestMode() → isGuestMode == true, canUseApp == true
├── signInWithGoogle() → isLoggedIn == true, サービス初期化呼出
├── signOut() → isLoggedIn == false, 状態リセット
└── ゲストデータマイグレーション → コールバック実行確認
```

### A3: 命名リファクタの設計

#### 命名マッピング（確定は実装時）

| 旧名 | 新名（案） |
|------|----------|
| `sharedGroupId` | `sharedTabGroupId` |
| `sharedGroupIcon` | `sharedTabGroupIcon` |
| `SharedGroupManager` | `SharedTabManager` |
| `SharedGroupService` | **削除** |
| `SharedGroupIcons` | `SharedTabIcons` |
| `SharedGroupIcon` | `SharedTabIcon` |
| `shared_group_manager.dart` | `shared_tab_manager.dart` |
| `shared_group_icons.dart` | `shared_tab_icons.dart` |
| `getSharedGroupTotal()` | `getSharedTabTotal()` |
| `getSharedGroupBudget()` | `getSharedTabBudget()` |
| `updateSharedGroup()` | `updateSharedTab()` |
| `removeFromSharedGroup()` | `removeFromSharedTab()` |
| `syncSharedGroupBudget()` | `syncSharedTabBudget()` |
| `sortShopsBySharedGroups()` | `sortShopsBySharedTabs()` |
| `getSharedGroupMembers()` | `getSharedTabMembers()` |
| `getSharedGroupInfo()` | `getSharedTabInfo()` |

#### Firestore デュアルリード設計

```dart
// lib/models/shop.dart — fromJson
factory Shop.fromJson(Map<String, dynamic> json) {
  return Shop(
    // 新フィールド優先、旧フィールドにフォールバック
    sharedTabGroupId: json['sharedTabGroupId'] ?? json['sharedGroupId'],
    sharedTabGroupIcon: json['sharedTabGroupIcon'] ?? json['sharedGroupIcon'],
    // ...
  );
}

// toJson は新フィールド名のみ出力
Map<String, dynamic> toJson() {
  return {
    'sharedTabGroupId': sharedTabGroupId,
    'sharedTabGroupIcon': sharedTabGroupIcon,
    // ...
  };
}
```

- 既存ユーザーのデータ: 旧フィールド名で保存 → fromJson のフォールバックで読み込み
- 新規保存: 新フィールド名で保存 → 次回読み込み時は新フィールド名が優先
- 自然移行: ユーザーが共有タブを編集するたびに新フィールド名に置き換わる

### 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `lib/models/shop.dart` | フィールド名リネーム + fromJson デュアルリード |
| `lib/models/shared_group_icons.dart` | ファイル名・クラス名リネーム |
| `lib/providers/managers/shared_group_manager.dart` | ファイル名・クラス名・メソッド名リネーム |
| `lib/providers/data_provider.dart` | メソッド名・変数名更新 |
| `lib/screens/main/dialogs/tab_edit_dialog.dart` | 参照更新 |
| `lib/screens/main/widgets/main_app_bar.dart` | 参照更新 |
| `lib/screens/main/widgets/bottom_summary_widget.dart` | 参照更新 |
| `lib/screens/main/dialogs/budget_dialog.dart` | 参照更新 |
| `lib/screens/main/utils/item_operations.dart` | 参照更新 |
| `lib/utils/tab_sorter.dart` | メソッド名更新 |
| `test/helpers/test_helpers.dart` | パラメータ名更新 |
| `test/models/shop_test.dart` | フィールド名更新 |

### 削除対象ファイル
| ファイル | 理由 |
|---------|------|
| `lib/services/shared_group_service.dart` | 本体未使用、SharedGroupManager に複製済み |
| `test/services/shared_group_service_test.dart` | 上記の削除に伴い不要 |

### 新規作成ファイル
| ファイル | 役割 |
|---------|------|
| `test/services/one_time_purchase_service_test.dart` | 課金サービステスト |
| `test/services/purchase/trial_manager_test.dart` | 体験期間テスト |
| `test/services/purchase/purchase_persistence_test.dart` | 永続化テスト |
| `test/services/auth_service_test.dart` | 認証サービステスト |
| `test/providers/auth_provider_test.dart` | 認証プロバイダーテスト |
| `test/providers/managers/shared_tab_manager_test.dart` | 共有タブマネージャーテスト |

## 影響範囲
- A1/A2: テスト追加のみ。本体コード変更なし
- A3: モデル〜UI全層に影響するが、ロジック変更はなし（命名のみ）
- Firestore: デュアルリードで後方互換性を維持
- Cloud Functions / Firestoreルール: 影響なし

## Flutter固有の注意点
- Provider依存: DataProvider → SharedTabManager（旧SharedGroupManager）の委譲関係は変わらない
- プラットフォーム分岐: 命名リファクタに kIsWeb 分岐は関係なし
- data_provider.dart: メソッド名変更により、UIからの呼び出し箇所も全て更新必要
