# まいカゴ 国際化（i18n）設定ガイド

このドキュメントでは、まいカゴアプリの国際化設定とpotファイル生成について説明します。

## 📁 ファイル構成

```
lib/
├── l10n/
│   ├── app_en.arb          # 英語テンプレートファイル
│   ├── app_ja.arb          # 日本語翻訳ファイル
│   └── app.pot             # 翻訳テンプレートファイル（生成）
├── generated/
│   ├── l10n.dart           # 生成されたローカライゼーションクラス
│   └── intl/
│       ├── messages_all.dart
│       └── messages_en.dart
└── main.dart
```

## 🛠️ セットアップ

### 1. 依存関係の追加

`pubspec.yaml`に以下の依存関係が追加されています：

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

dev_dependencies:
  intl_utils: ^2.8.5
```

### 2. 設定ファイル

- `l10n.yaml`: 国際化の設定ファイル
- `generate_pot.py`: ARBファイルからpotファイルを生成するPythonスクリプト
- `generate_pot.bat`: Windows環境用のバッチファイル

## 🔧 potファイルの生成

### 方法1: バッチファイルを使用（推奨）

```bash
.\generate_pot.bat
```

### 方法2: Pythonスクリプトを直接実行

```bash
python generate_pot.py
```

### 方法3: 手動でARBファイルから生成

1. `lib/l10n/app_en.arb`ファイルを確認
2. Pythonスクリプトを実行
3. `lib/l10n/app.pot`ファイルが生成されます

## 📝 翻訳作業の流れ

### 1. potファイルの配布

生成された`lib/l10n/app.pot`ファイルを翻訳者に配布します。

### 2. poファイルの作成

翻訳者は以下の手順で翻訳を行います：

```bash
# potファイルをpoファイルに変換
msginit -i lib/l10n/app.pot -o lib/l10n/app_ja.po -l ja

# または、既存のpoファイルを更新
msgmerge -U lib/l10n/app_ja.po lib/l10n/app.pot
```

### 3. 翻訳の実施

poファイルを編集して翻訳を追加します：

```po
msgid "Add Item"
msgstr "アイテム追加"
```

### 4. moファイルの生成

```bash
msgfmt lib/l10n/app_ja.po -o lib/l10n/app_ja.mo
```

## 🌐 新しい言語の追加

### 1. ARBファイルの作成

新しい言語用のARBファイルを作成します：

```bash
# 例：フランス語
cp lib/l10n/app_en.arb lib/l10n/app_fr.arb
```

### 2. 翻訳の実施

`lib/l10n/app_fr.arb`ファイルを編集して翻訳を追加します。

### 3. 設定の更新

`l10n.yaml`ファイルの`preferred-supported-locales`に新しい言語を追加：

```yaml
preferred-supported-locales: [en, ja, fr]
```

### 4. ファイルの再生成

```bash
dart run intl_utils:generate
```

## 🔄 翻訳の更新

### 1. 新しい文字列の追加

`lib/l10n/app_en.arb`に新しい文字列を追加：

```json
{
  "newFeature": "New Feature",
  "@newFeature": {
    "description": "Description for new feature"
  }
}
```

### 2. potファイルの再生成

```bash
.\generate_pot.bat
```

### 3. 既存の翻訳ファイルの更新

```bash
msgmerge -U lib/l10n/app_ja.po lib/l10n/app.pot
```

## 🚀 アプリでの使用

### 1. MaterialAppの設定

`lib/main.dart`でローカライゼーションを有効にします：

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('ja'),
  ],
  // ...
)
```

### 2. 文字列の使用

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// コンテキストから取得
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle);

// または、直接使用
Text(AppLocalizations.of(context)!.addItem);
```

## 📋 注意事項

1. **文字エンコーディング**: すべてのファイルはUTF-8で保存してください
2. **改行文字**: 複数行の文字列は適切にエスケープされます
3. **特殊文字**: 引用符やバックスラッシュは自動的にエスケープされます
4. **バージョン管理**: potファイルはバージョン管理に含めないことを推奨します

## 🛠️ トラブルシューティング

### よくある問題

1. **Pythonが見つからない**
   - Pythonをインストールしてください
   - PATHにPythonが含まれていることを確認してください

2. **ARBファイルが見つからない**
   - `lib/l10n/app_en.arb`ファイルが存在することを確認してください

3. **生成されたファイルが更新されない**
   - `flutter clean`を実行してから再生成してください

4. **文字化けが発生する**
   - ファイルのエンコーディングがUTF-8であることを確認してください

## 📞 サポート

問題が発生した場合は、以下を確認してください：

1. Flutterのバージョン
2. 依存関係のバージョン
3. エラーメッセージの詳細

---

**最終更新**: 2025年8月20日
**バージョン**: 0.7.0
