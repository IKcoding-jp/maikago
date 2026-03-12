# 設計書

## 実装方針

### 変更対象ファイル
- `lib/services/one_time_purchase_service.dart` - `resetForLogout()` メソッド追加
- `lib/providers/auth_provider.dart` - `_updateServicesForUser(null)` でリセット呼び出し追加

### 新規作成ファイル
なし

## 詳細設計

### OneTimePurchaseService.resetForLogout()
```dart
void resetForLogout() {
  _currentUserId = '';
  notifyListeners();
}
```

`_userPremiumStatus` マップはクリアしない（再ログイン時のキャッシュとして利用可能）。
`_currentUserId` を空文字にすることで `_userPremiumStatus['']` → `null` → `false` となり、
`isPremiumUnlocked` が `false` を返す。

### AuthProvider._updateServicesForUser(null)
```dart
void _updateServicesForUser(User? user) {
  if (user?.uid != null) {
    unawaited(_purchaseService.initialize(userId: user!.uid));
    _donationService.handleAccountSwitch(user.uid);
  } else {
    _purchaseService.resetForLogout();  // ← 追加
    _donationService.handleAccountSwitch('');
  }
}
```

## 影響範囲
- `FeatureAccessControl` — `OneTimePurchaseService.isPremiumUnlocked` を参照しているため、自動的にフリー状態に戻る
- 広告表示・テーマ制限・OCR制限等が正しく適用される
- 再ログイン時は `initialize(userId: uid)` が呼ばれ、`_currentUserId` が設定され、Firestoreから購入情報が読み込まれるため、プレミアム状態が復元される

## Flutter固有の注意点
- `notifyListeners()` により、プレミアム状態を監視しているWidgetが自動的にリビルドされる
- data_provider.dart への影響なし（データクリアは既に別途行われている）
