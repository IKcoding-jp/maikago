# 要件定義: テストカバレッジの向上

## Issue
- **番号**: #33
- **タイトル**: [High/Testing] テストカバレッジの向上（現状推定10%未満）
- **ラベル**: testing, major

## 背景
- lib/ に83ファイル、test/ に7ファイル（うちテストファイルは5つ、ヘルパー/モック2つ）
- 推定カバレッジ率: 10%未満
- サービス層、ウィジェット、ユーティリティのテストが皆無

## 現状のテストカバー範囲
- **モデル層**: ListItem, Shop, SortMode（カバー済み）
- **Provider層**: DataProvider（基本CRUD）、ThemeProvider（カバー済み）
- **Service層**: 未テスト
- **UI層**: 未テスト

## 目標
### Phase 1: サービス層ユニットテスト（カバレッジ30%以上）
以下のサービスのユニットテストを追加:
1. `FeatureAccessControl` - プレミアム判定ロジック
2. `ItemService` - アイテムCRUD操作
3. `ShopService` - ショップCRUD、デフォルトショップ管理
4. `SharedGroupService` - 共有グループ管理

### Phase 2: Provider層テスト
1. `ItemRepository` - 楽観的更新とロールバック
2. `ShopRepository` - ショップCRUD
3. `DataCacheManager` - キャッシュ管理
4. `SharedGroupManager` - 共有グループ管理

### Phase 3: ウィジェットテスト（将来）
### Phase 4: 統合テスト（将来）

## スコープ
- **今回のIssueではPhase 1のみ実施**
- Phase 2以降は別Issueで対応

## 受け入れ基準
- [ ] Phase 1の4サービスにユニットテストが追加されている
- [ ] すべてのテストが `flutter test` で通過する
- [ ] `flutter analyze` でLintエラーがない
- [ ] 既存テストが壊れていない
