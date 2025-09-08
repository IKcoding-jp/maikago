# GPT-5-nano 商品名要約機能の設定

## 概要
商品名が長すぎる問題を解決するため、GPT-5-nano（現在はGPT-4o-mini）を使用して商品名を簡潔に要約する機能を実装しました。

## 機能
- 長い商品名（30文字以上）を自動検出
- GPT-5-nanoを使用してメーカー、商品名、容量・重さのみを抽出
- 最大20文字以内に要約
- APIエラー時はフォールバック要約を使用

## 設定方法

### 1. OpenAI APIキーの取得
1. [OpenAI Platform](https://platform.openai.com/)にアクセス
2. アカウントを作成またはログイン
3. API Keys セクションで新しいAPIキーを作成
4. キーをコピーして保存

### 2. APIキーの設定
`lib/services/product_name_summarizer_service.dart` の以下の行を編集：

```dart
static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // ここに実際のAPIキーを設定
```

例：
```dart
static const String _apiKey = 'sk-1234567890abcdef...';
```

### 3. 環境変数での管理（推奨）
セキュリティのため、APIキーを環境変数で管理することを推奨します：

```dart
static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
```

環境変数の設定：
```bash
# Windows
set OPENAI_API_KEY=sk-1234567890abcdef...

# macOS/Linux
export OPENAI_API_KEY=sk-1234567890abcdef...
```

## 使用例

### 要約前
```
味の素 コンソメ 顆粒 50g 袋入 AJINOMOTO 調味料 洋風スープ 煮込み料理 野菜のコク 炒め物 スープ ブイヨン まとめ買い プロの味 料理 洋食
```

### 要約後
```
味の素 コンソメ 顆粒 50g
```

## フォールバック機能
APIが利用できない場合、以下のロジックで要約：
1. 容量・重さのパターン（例：50g、1L）を検出
2. メーカー名や商品名の基本部分を保持
3. 最大3単語まで抽出

## コスト管理
- GPT-4o-miniは非常に低コスト（$0.00015/1K tokens）
- 商品名要約は約50 tokens程度
- 1回の要約で約$0.0000075（0.00075円）

## 注意事項
- APIキーは絶対に公開リポジトリにコミットしないでください
- 本番環境では環境変数を使用してください
- API利用制限に注意してください

## トラブルシューティング

### エラー: "API認証エラー"
- APIキーが正しく設定されているか確認
- APIキーに適切な権限があるか確認

### エラー: "利用制限に達しました"
- OpenAIアカウントの利用制限を確認
- 必要に応じてプランをアップグレード

### 要約が動作しない
- フォールバック要約が使用されます
- ログでエラー内容を確認してください
