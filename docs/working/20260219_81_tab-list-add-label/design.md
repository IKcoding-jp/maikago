# 設計書

## 実装方針

### 変更対象ファイル

#### 1. `lib/screens/main/widgets/main_app_bar.dart`（タブ追加ボタン）
- **現在**: `IconButton(icon: Icon(Icons.add), onPressed: onAddTab, tooltip: 'タブ追加')`
- **変更後**: テキストラベル付きボタンに変更
  - 案A: `TextButton.icon(icon: Icon(Icons.tab), label: Text('タブ追加'))`
  - 案B: `Row` で `Icon(Icons.add) + Text('タブ追加')` を `InkWell` でラップ
- **注意**: AppBar の `actions` 内に配置されるため、スペースを考慮

#### 2. `lib/screens/main/widgets/bottom_summary_widget.dart`（リスト追加FAB）
- **現在**: `FloatingActionButton(mini: true, child: Icon(Icons.add))`
- **変更後**: `FloatingActionButton.extended(icon: Icon(Icons.playlist_add), label: Text('リスト追加'))`
- **注意**: BottomSummaryWidget のアクションボタン行（予算変更・カメラ・レシピ・追加）のレイアウトに影響
  - FABが横に広がるため、4つのボタンが1行に収まるか確認
  - 収まらない場合は `mini: true` を維持しつつラベル追加、またはアイコンを変更するのみに留める

### 新規作成ファイル
- なし

## UI変更のビジュアルイメージ

### Before
```
AppBar:  [タブ1] [タブ2] [タブ3]           [+]
Bottom:  [予算変更] [📷] [🍳] [●+●]  ← mini FAB
```

### After
```
AppBar:  [タブ1] [タブ2] [タブ3]    [+ タブ追加]
Bottom:  [予算変更] [📷] [🍳] [+ リスト追加]  ← extended FAB
```

## 影響範囲
- `MainAppBar` ウィジェット - actions プロパティの変更
- `BottomSummaryWidget` ウィジェット - FABの形状変更
- テーマカラーとの整合性（`SettingsTheme.generateTheme()` で生成されるカラーとの整合）

## Flutter固有の注意点
- `FloatingActionButton.extended` は `mini` プロパティがないため、サイズ調整は別途必要
- AppBar の actions は右寄せされるため、テキスト付きボタンのサイズに注意
- Web対応コードでは `kIsWeb` で分岐が必要な場合がある（横幅800px制限）
- `scaffoldBgLuminance` に基づくアイコン色の分岐ロジックは維持すること
