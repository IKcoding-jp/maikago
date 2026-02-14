# 設計書

## 実装方針

### 変更対象ファイル
- `lib/screens/main/dialogs/` - ダイアログ群
- `lib/screens/main_screen.dart` - showDialog呼び出し箇所

### 推奨方針: ラッパー関数方式（方針B）

```dart
// lib/utils/dialog_utils.dart
Future<T?> showConstrainedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      if (kIsWeb) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: builder(context),
          ),
        );
      }
      return builder(context);
    },
  );
}
```

## 影響範囲
- 全`showDialog`呼び出し箇所
- 全`showModalBottomSheet`呼び出し箇所

## Flutter固有の注意点
- `kIsWeb`でプラットフォーム分岐
- Overlayルートは`MaterialApp.builder`のスコープ外
