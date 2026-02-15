# 要件定義: #36 build()内副作用除去 + #37 エラーハンドリング統一

## 対象Issue

- **#36** [Medium/Performance] build()内の副作用除去とパフォーマンス改善
- **#37** [Medium/Architecture] エラーハンドリング戦略の統一

## 背景

### Issue #36
`main_screen.dart`のbuild()メソッド内でTabControllerの再生成、テーマ監視、getCustomTheme()の繰り返し呼び出し等の副作用が存在し、パフォーマンスに悪影響を与えている。また`list_edit.dart`でのSharedPreferences個別読み込み、`ad_banner.dart`でのbusy-waitパターンも問題。

### Issue #37
エラー処理パターンが非統一。文字列ベース(`e.toString().contains(...)`)のエラー判定が23箇所、空のcatchブロックが6箇所以上、AuthProviderでの5重ネストtry-catch、StreamSubscription未解除がある。カスタム例外クラスが存在しない。

## 要件一覧

### #36 パフォーマンス改善

| # | 要件 | 優先度 |
|---|------|--------|
| 36-1 | build()先頭でgetCustomTheme()を1回だけ呼び、変数に保持する | 高 |
| 36-2 | TabController更新をbuild()外（didChangeDependenciesなど）に移動する | 高 |
| 36-3 | updateThemeAndFontIfNeeded()をbuild()外に移動する | 高 |
| 36-4 | 取り消し線設定をProviderまたはパラメータで渡し、各ListEditの個別I/Oを排除する | 中 |
| 36-5 | AdBannerのbusy-waitをCompleter/リスナーパターンに変更する | 中高 |

### #37 エラーハンドリング統一

| # | 要件 | 優先度 |
|---|------|--------|
| 37-1 | カスタム例外クラスを定義する（AppException, NotFoundError等） | 高 |
| 37-2 | Service/Repository層でFirebase例外をカスタム例外に変換する | 高 |
| 37-3 | settings_persistence.dartの空catchブロックにログ出力を追加し一貫性を持たせる | 高 |
| 37-4 | AuthProviderのStreamSubscriptionを保存しdispose()でcancel()する | 高 |
| 37-5 | AuthProviderの5重ネストtry-catchを整理する | 中 |

## 成功基準

- `flutter analyze` がエラーなしで通過する
- `flutter test` が全件通過する
- build()内から副作用が除去されている
- エラー処理パターンが統一されている
- StreamSubscriptionが適切に管理されている
