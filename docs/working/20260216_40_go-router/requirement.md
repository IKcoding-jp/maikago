# 要件定義: ナビゲーション管理の導入（go_router）

## Issue
- **番号**: #40
- **タイトル**: [Medium/Architecture] ナビゲーション管理の導入（go_router）
- **ラベル**: refactor

## 背景
現在のまいカゴアプリでは画面遷移が `Navigator.push` / `MaterialPageRoute` の直接使用に依存しており、ルート定義が一元管理されていない。唯一のスタティックルートは `/subscription` のみで、他の25+箇所はすべてインラインの `MaterialPageRoute` で遷移している。

## 要件

### 必須要件
1. `go_router` パッケージを導入する
2. ルート定義を `lib/router.dart` に一元化する
3. 画面遷移を `context.go()` / `context.push()` に統一する
4. Deep linking 対応の基盤を構築する
5. 認証フロー（AuthWrapper）を go_router の redirect 機能で統合する

### 制約・注意事項
- ダイアログ（`showConstrainedDialog`）は go_router の対象外。既存のまま維持する
- 戻り値付き遷移（`Navigator.pop(context, result)`）は `context.pop<T>(result)` で置き換える
- Web対応の横幅制限（800px）は維持する
- 既存の Provider パターンによる状態管理は変更しない
- `SplashWrapper` → `AuthWrapper` の認証フローは go_router の redirect に統合

### 対象外
- ダイアログの表示方法の変更（showConstrainedDialog はそのまま）
- Provider パターンの変更
- UI/UXの変更

## 影響範囲
- `lib/main.dart` - MaterialApp → MaterialApp.router への変更
- `lib/screens/` 配下の全画面ファイル - Navigator.push の書き換え
- `lib/widgets/` - 一部ウィジェットからの Navigator.push 書き換え
- `lib/services/settings_theme.dart` - SubscriptionScreen への遷移
- 新規ファイル: `lib/router.dart`

## 成功基準
- すべての画面遷移が go_router 経由で動作すること
- `flutter analyze` がエラーなしで通ること
- 既存のテストが通ること
- ダイアログの動作に影響がないこと
