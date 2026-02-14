# 設計書 - Issue #4: ChatGPTサービスの責務分割

**Issue番号**: #4
**作成日**: 2026-02-14
**ラベル**: refactor, critical

---

## 1. アーキテクチャ概要

### 1.1 現状のアーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                     ChatGptService                          │
│  (1,487行 - 責務が混在)                                      │
├─────────────────────────────────────────────────────────────┤
│  - OpenAI API通信                                            │
│  - プロンプト管理                                            │
│  - 価格抽出ロジック                                          │
│  - 価格補正ロジック                                          │
│  - レスポンス解析                                            │
│  - Vision API連携                                            │
└─────────────────────────────────────────────────────────────┘
         ↑                    ↑                    ↑
         │                    │                    │
   VisionOcrService   RecipeParserService   HybridOcrService
```

### 1.2 リファクタリング後のアーキテクチャ

```
                    ┌────────────────────────┐
                    │   ChatGptService       │
                    │  (ファサード・約200行)  │
                    └───────────┬────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ↓                       ↓                       ↓
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│OpenAIClient  │      │PromptTemplate│      │ResponseParser│
│(API通信)     │      │(プロンプト)   │      │(解析)        │
└──────────────┘      └──────────────┘      └──────────────┘
                                │
                ┌───────────────┼───────────────┐
                ↓               ↓               ↓
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │PriceExtractor│ │PriceNormalizer│ │ChatGptModels │
        │(価格抽出)     │ │(価格補正)     │ │(データ型)    │
        └──────────────┘ └──────────────┘ └──────────────┘
                ↑                    ↑                    ↑
                │                    │                    │
          VisionOcrService   RecipeParserService   HybridOcrService
```

---

## 2. クラス設計

### 2.1 ChatGptService (ファサード)

**責務**: 各サービスを統合し、公開APIを提供

**ファイルパス**: `lib/services/chatgpt_service.dart`

**主要メソッド**:
```dart
class ChatGptService {
  final String apiKey;
  final OpenAIClient _client;
  final PromptTemplate _promptTemplate;
  final ResponseParser _responseParser;
  final PriceExtractor _priceExtractor;
  final PriceNormalizer _priceNormalizer;

  ChatGptService({String? apiKey})
      : apiKey = apiKey ?? openAIApiKey,
        _client = OpenAIClient(apiKey: apiKey ?? openAIApiKey),
        _promptTemplate = PromptTemplate(),
        _responseParser = ResponseParser(),
        _priceExtractor = PriceExtractor(),
        _priceNormalizer = PriceNormalizer();

  /// シンプル版：OCRテキストから商品名と税込価格を直接抽出
  Future<OcrItemResult?> extractProductInfo(String ocrText) async;

  /// Vision API版：画像から直接商品名と税込価格を抽出
  Future<OcrItemResult?> extractProductInfoFromImage(File image) async;

  /// 新仕様: 価格候補一覧を抽出
  Future<List<Map<String, dynamic>>> extractPriceCandidates(String ocrText) async;

  /// 古い仕様: 商品名と価格を抽出
  Future<ChatGptItemResult?> extractNameAndPrice(String ocrText) async;
}
```

**設計方針**:
- 既存の公開APIを維持（後方互換性）
- 内部実装は各専門クラスに委譲
- コンストラクタでDI（Dependency Injection）
- 約200行以内に収める

---

### 2.2 OpenAIClient (API通信層)

**責務**: OpenAI APIとの通信を抽象化

**ファイルパス**: `lib/services/chatgpt/openai_client.dart`

```dart
/// OpenAI APIクライアント
class OpenAIClient {
  final String apiKey;
  final http.Client _httpClient;

  OpenAIClient({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// チャット補完APIを呼び出す
  Future<OpenAIResponse> chatCompletion({
    required String model,
    required List<ChatMessage> messages,
    Map<String, dynamic>? responseFormat,
    int? maxTokens,
    double? temperature,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _executeWithRetry(
      () => _chatCompletionSingle(
        model: model,
        messages: messages,
        responseFormat: responseFormat,
        maxTokens: maxTokens,
        temperature: temperature,
        timeout: timeout,
      ),
      maxRetries: chatGptMaxRetries,
    );
  }

  /// リトライロジック付きでAPIを実行
  Future<T> _executeWithRetry<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await apiCall();
      } catch (e) {
        if (attempt < maxRetries) {
          final waitTime = attempt * 2;
          await Future.delayed(Duration(seconds: waitTime));
        } else {
          rethrow;
        }
      }
    }
    throw Exception('Retry exhausted');
  }

  /// チャット補完API呼び出し（単一実行）
  Future<OpenAIResponse> _chatCompletionSingle({
    required String model,
    required List<ChatMessage> messages,
    Map<String, dynamic>? responseFormat,
    int? maxTokens,
    double? temperature,
    required Duration timeout,
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = jsonEncode({
      'model': model,
      if (responseFormat != null) 'response_format': responseFormat,
      'messages': messages.map((m) => m.toJson()).toList(),
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
    });

    final response = await _httpClient
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: body,
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw OpenAIApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    return OpenAIResponse.fromJson(jsonDecode(response.body));
  }

  void dispose() {
    _httpClient.close();
  }
}

/// チャットメッセージ
class ChatMessage {
  final String role; // 'system' | 'user' | 'assistant'
  final dynamic content; // String or List<Map<String, dynamic>>

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

/// OpenAI APIレスポンス
class OpenAIResponse {
  final String id;
  final List<Choice> choices;
  final Usage? usage;

  OpenAIResponse({
    required this.id,
    required this.choices,
    this.usage,
  });

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) {
    return OpenAIResponse(
      id: json['id'] ?? '',
      choices: (json['choices'] as List?)
              ?.map((c) => Choice.fromJson(c))
              .toList() ??
          [],
      usage: json['usage'] != null ? Usage.fromJson(json['usage']) : null,
    );
  }

  String get content => choices.isNotEmpty
      ? choices.first.message.content
      : '';
}

class Choice {
  final Message message;
  final String finishReason;

  Choice({required this.message, required this.finishReason});

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      message: Message.fromJson(json['message']),
      finishReason: json['finish_reason'] ?? '',
    );
  }
}

class Message {
  final String role;
  final String content;

  Message({required this.role, required this.content});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
    );
  }
}

/// OpenAI APIエラー
class OpenAIApiException implements Exception {
  final int statusCode;
  final String message;

  OpenAIApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'OpenAIApiException($statusCode): $message';
}
```

**設計方針**:
- HTTPクライアントを注入可能（テスト容易性）
- リトライロジックを統一
- エラーハンドリングを統一
- 型安全なレスポンス解析

---

### 2.3 PromptTemplate (プロンプト管理)

**責務**: プロンプトのテンプレート管理とバージョン管理

**ファイルパス**: `lib/services/chatgpt/prompt_template.dart`

```dart
/// プロンプトテンプレート管理
class PromptTemplate {
  /// 商品名・価格抽出プロンプト（古い仕様）
  String getProductExtractionPrompt() {
    return '''あなたはOCRテキストから買い物用データを抽出するアシスタントです。
出力は必ずJSONのみ。商品名は商品の実際の名称のみ（メーカー名・産地情報・独立した型番は除外、商品名の一部として記載されている数量・種類の情報やアルファベット・英単語、商品名として記載されている型番は含める）で短く整形し、価格は日本円の整数のみで返してください。商品名が型番のみの場合は、その型番を商品名として使用してください。

【重要な指示】
1. OCRテキストには誤認識やノイズが含まれる可能性があります
2. 商品名と価格を正確に識別し、不要な情報は除外してください
3. 税込価格を最優先で抽出し、税抜価格の場合は明示してください
4. 信頼度が低い場合は適切にconfidenceを下げてください

【商品名抽出ルール】
- 商品の実際の名称を抽出（メーカー名も含める）
- 価格、説明文、プロモーション文言は除外
- 長すぎる商品名は適切に短縮
- 誤認識された文字は可能な限り修正
- メーカー名は商品名に含める（食品、服、日用品、電化製品など、すべてのメーカー名）
- 産地情報（「埼玉産」「北海道産」「国産」など）は商品名に含める
- 商品名の一部として記載されている数量・種類の情報（「10種の洋菓子ミックス」の「10種の」「本格レッドカレー」の「本格」など）は商品名に含める
- 独立して記載されている内容量は商品名に含めない
- 商品名に含まれるアルファベットや英単語は商品名の一部として含める
- 型番・モデル番号は商品名から除外
- ただし、商品名が型番のみの場合は、その型番を商品名として使用

【価格抽出ルール - 税込優先】
- 税込価格を最優先（「税込」「税込み」「税込価格」「税込(」「内税」のラベルを絶対重視）
- 複数の価格がある場合は、税込価格を優先し、次に高い価格を選択
- 参考価格として表示されている税込価格も優先（「参考税込」「参考」+「税込」）
- 小数点を含む価格は税込価格の可能性が非常に高い（例：181.44円、537.84円）
- 税抜価格の判定は厳密に行う（「税抜」「税抜き」「本体価格」「税別」「外税」の明確なラベルのみ）
- ラベルが不明確な場合は税込価格として扱う
- 取り消し線価格は除外

【税込価格の検出パターン】
1. 明確なラベル: 「税込」「税込み」「税込価格」「税込(」「内税」
2. 参考価格: 「参考税込」「参考」+「税込」「(税込 価格)」
3. 小数点価格: 181.44円、537.84円、298.00円など
4. 端数がある価格: 末尾に.44、.84、.46などの端数がある価格
5. 一般的な小売価格: 100円〜5000円の範囲で、端数がある価格

【税抜価格の判定基準】
- 明確に「税抜」「税抜き」「本体価格」「税別」「外税」と表示されている場合のみ
- ラベルが曖昧な場合は税込価格として扱う
- 推定は避け、明確な証拠がある場合のみ税抜と判定

【OCR誤認識修正】
- 末尾文字除去: 21492円)k → 21492円
- 小数点誤認識: 17064円 → 170.64円 → 170円
- 小数点誤認識（税込）: 税込14904円) → 税込149.04円 → 149円
- 小数点誤認識（税込価格）: 27864円 → 278.64円 → 278円
- 小数点誤認識（税込価格）: 17064円 → 170.64円 → 170円
- ハイフン誤認識: 170-64円 → 170.64円 → 170円
- 分離認識: 278円 + 46円 → 278.46円 → 278円
- 異常価格修正: 2149200円 → 21492円

【小数点価格の誤認識パターン】
- OCRで小数点が誤認識されて大きな数字になる場合がある
- 例：149.04円 → 14904円、181.44円 → 18144円、429.84円 → 42984円、278.64円 → 27864円、321.84円 → 32184円、149.04円 → 14904円、189.00円 → 18900円
- 税込価格で4桁以上の数字が検出された場合は小数点誤認識の可能性を考慮
- 整数部分が100円〜1000円の範囲で、小数部分が2桁以内の場合は修正を適用
- ¥記号付きの4桁以上の数字（例：¥4298）も小数点誤認識の可能性を考慮
- 「税込価格」ラベル付きの4桁以上の数字は特に小数点誤認識の可能性が高い

【confidence算出】
- 0.9-1.0: 明確な税込ラベルと価格、商品名が一致
- 0.7-0.8: 小数点価格など税込の証拠があるがラベル不明
- 0.5-0.6: 推測が必要だが合理的な結果
- 0.3以下: 信頼度が低い、不明な場合''';
  }

  /// 価格候補抽出プロンプト（新仕様）
  String getPriceCandidatesPrompt() {
    return '''あなたはOCRテキストから値札の「商品名」と「価格情報」を抽出するアシスタントです。
出力は必ずJSONのみ。

【出力仕様（配列）】
{
  "candidates": [
    {
      "商品名": string,
      "税抜価格": number | null,
      "税込価格": number | null,
      "税率": number | null
    }
  ]
}

【重要な指示】
1. 値札から読み取れるすべての価格候補を返す（重複は避ける）
2. 「税込」「内税」が明示なら税込価格として出力
3. 「税抜」「本体価格」があれば税抜価格として出力、税率表記（8%/10%/軽減税率など）があれば 0.08/0.10 として出力。なければ税率は null
4. 税率が明示されていなければ null を返す
5. 価格は日本円の整数（小数は四捨五入）
6. 単価文脈（円/100g など）や取り消し線価格、明らかなノイズは除外''';
  }

  /// Vision APIプロンプト（画像から商品情報抽出）
  String getVisionExtractionPrompt() {
    return '''あなたは値札画像から情報を読み取る専門家です。画像から「商品名」と「税込価格」を抽出してください。

出力形式（JSON）:
{
  "name": "商品名",
  "price": 税込価格（数値のみ）
}

重要な注意事項:
1. **税込価格を絶対優先**してください。「本体価格」「税抜」と書かれた価格ではなく、計算後の「税込」価格または「支払金額」を探してください。
2. 日本円の価格において、小数点は通常使用されませんが、稀に「115.45」のように誤認識されやすいフォントや表記があります。
   - もし「115.45」のように見えても、それは「115円」の誤りや、単価などの無関係な情報の可能性があります。
   - "円"の単位が付いている最も大きく表示されている価格が正解の可能性が高いです。
   - **4桁以上の価格（例：11545円）になる場合は、小数点の見落としがないか疑ってください。** 一般的なスーパーやコンビニの商品価格帯（50円〜3000円）を考慮してください。
3. 商品名はメーカー名を含めて簡潔に抽出してください。''';
  }

  /// ユーザープロンプトの構築（商品名・価格抽出）
  Map<String, dynamic> buildProductExtractionUserPrompt(String ocrText) {
    return {
      "instruction":
          "以下のOCRテキストから商品名と税込価格を抽出してJSONで返してください。税込価格を最優先で検出してください。商品名が型番のみの場合は、その型番を商品名として使用してください。",
      "rules": [
        "出力スキーマ: { product_name: string, price_jpy: integer, price_type: '税込'|'税抜'|'推定'|'不明', confidence: 0.0-1.0, raw_matches: [ ... ] }",
        "税込価格の絶対優先:",
        " - 「税込」「税込み」「税込価格」「税込(」「内税」のラベルがあれば必ずその価格を選択",
        " - 複数の価格がある場合は、税込価格を優先し、次に高い価格を選択",
        " - 「参考税込」「参考」+「税込」「(税込 価格)」のパターンも税込価格として優先",
        " - 小数点を含む価格（181.44円、537.84円、298.00円など）は税込価格として扱う",
        " - 端数がある価格（末尾に.44、.84、.46など）は税込価格の可能性が高い",
        " - ラベルが不明確な場合は税込価格として扱う",
        "税抜価格の厳密判定:",
        " - 「税抜」「税抜き」「本体価格」「税別」「外税」の明確なラベルのみ",
        " - ラベルが曖昧な場合は税込価格として扱う",
        " - 推定は避け、明確な証拠がある場合のみ税抜と判定",
        "OCR誤認識修正: (省略)",
        "商品名抽出: (省略)",
        "confidence算出: 税込ラベルの有無(+0.4), 小数点価格(+0.2), 文字列整合性(+0.2), 妥当性スコア(+0.2) で計算し0..1に正規化",
        "不明・低信頼時は price_jpy=0, price_type='不明', confidence<=0.5 とする",
        "必ずraw_matchesに検出した全価格文字列とそのラベル近接情報を入れて返す"
      ],
      'text': ocrText,
    };
  }

  /// ユーザープロンプトの構築（価格候補抽出）
  Map<String, dynamic> buildPriceCandidatesUserPrompt(String ocrText) {
    return {
      'instruction': 'OCRテキストから商品名と価格候補を抽出し、仕様通りにJSONで返答してください。',
      'text': ocrText,
      'schema': {
        'candidates': [
          {
            '商品名': 'string',
            '税抜価格': 'number|null',
            '税込価格': 'number|null',
            '税率': 'number|null'
          }
        ]
      }
    };
  }
}
```

**設計方針**:
- プロンプトをメソッドとして分離
- 将来的に外部ファイル化も可能
- バージョン管理を容易にする

---

### 2.4 PriceNormalizer (価格補正)

**責務**: OCRで誤認識された価格の補正

**ファイルパス**: `lib/services/chatgpt/price_normalizer.dart`

```dart
/// 価格の正規化・補正を行うクラス
class PriceNormalizer {
  /// 小数点誤認識の可能性を安全に判定する
  bool isLikelyDecimalMisread(int price, String ocrText) {
    // 基本的な条件チェック
    if (price < 1000 || price >= 100000) return false;

    // 税込価格ラベルが含まれているかチェック
    final hasTaxIncludedLabel = ocrText.contains('税込価格') ||
        ocrText.contains('(税込価格)') ||
        ocrText.contains('税込') ||
        ocrText.contains('(税込') ||
        ocrText.contains('【税込') ||
        ocrText.contains('税込〕');

    if (!hasTaxIncludedLabel) return false;

    // 価格の構造を分析
    final intPart = price ~/ 100;
    final decimalPart = price % 100;

    // 整数部分が妥当な範囲（100円〜1000円）で、小数部分が2桁以内の場合
    if (intPart < 100 || intPart > 1000 || decimalPart > 99) return false;

    // 特定の価格パターンの確認
    if (intPart == 278 && decimalPart <= 99) return true;
    if (intPart == 181 && decimalPart <= 99) return true;
    if (intPart == 149 && decimalPart <= 99) return true;
    if (intPart == 321 && decimalPart <= 99) return true;
    if (intPart == 429 && decimalPart <= 99) return true;
    if (intPart == 189 && decimalPart <= 99) return true;
    if (intPart == 170 && decimalPart <= 99) return true;

    // 一般的な小売価格の範囲で、端数がある場合
    if (intPart >= 100 && intPart <= 1000 && decimalPart > 0) {
      // 端数が一般的な税率計算に合致するかチェック
      final taxRate8 = (intPart * 0.08).round();
      final taxRate10 = (intPart * 0.10).round();

      if (decimalPart == taxRate8 || decimalPart == taxRate10) {
        return true;
      }
    }

    return false;
  }

  /// 小数点誤認識を修正（四捨五入）
  int correctDecimalMisread(int price) {
    final intPart = price ~/ 100;
    final decimalPart = price % 100;
    return ((intPart * 100 + decimalPart) / 100.0).round();
  }

  /// 近傍に税込ラベルが存在するか（±window文字の範囲で判定）
  bool hasTaxLabelNearby(String text, int start, int end, {int window = 12}) {
    final int from = (start - window).clamp(0, text.length);
    final int to = (end + window).clamp(0, text.length);
    final String area = text.substring(from, to);
    return area.contains('税込') ||
        area.contains('税込み') ||
        area.contains('税込価格') ||
        area.contains('内税');
  }

  /// 同一行に税込系ラベルが存在するかを検出
  bool hasTaxLabelInSameLine(String text, int index) {
    final int lineStart = text.lastIndexOf('\n', index);
    final int lineEnd = text.indexOf('\n', index);
    final int from = lineStart == -1 ? 0 : lineStart + 1;
    final int to = lineEnd == -1 ? text.length : lineEnd;
    final String line = text.substring(from, to);
    return line.contains('税込') ||
        line.contains('税込み') ||
        line.contains('税込価格') ||
        line.contains('内税');
  }

  /// 周辺が単価（100g/100ml/円/100g 等）文脈かを検出
  bool isUnitPriceContextNearby(String text, int start, int end,
      {int window = 48}) {
    final int from = (start - window).clamp(0, text.length);
    final int to = (end + window).clamp(0, text.length);
    final String area = text.substring(from, to);

    // よくある単価表現を網羅的に検出
    final List<RegExp> patterns = [
      RegExp(r"\b(100|200|300|400|500)\s*(g|ml|mL|L)\b"),
      RegExp(r"\b\d+\s*(g|ml|mL|L)\s*(当り|あたり)"),
      RegExp(r"(g|ml|mL|L)\s*(当り|あたり)"),
      RegExp(r"(当り|あたり)\s*\d+\.?\d*\s*円"),
      RegExp(r"円\s*/\s*\d+\s*(g|ml|mL|L)"),
      RegExp(r"/\s*\d+\s*(g|ml|mL|L)"),
      RegExp(r"\b\d+\s*(枚|本|個)\s*(当り|あたり)"),
      RegExp(r"(年)\s*(当り|あたり)"),
    ];

    for (final p in patterns) {
      if (p.hasMatch(area)) return true;
    }

    // 明示的な文字列キーワード
    final List<String> keywords = [
      '100g当り', '100g当たり', '100gあたり', '/100g', '円/100g',
      '100ml当り', '100ml当たり', '100mlあたり', '/100ml', '円/100ml',
      'g当り', 'g当たり', 'gあたり',
      'ml当り', 'ml当たり', 'mlあたり',
    ];
    for (final k in keywords) {
      if (area.contains(k)) return true;
    }
    return false;
  }

  /// 型変換ヘルパー
  int? toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      final asDouble = double.tryParse(s);
      if (asDouble != null) return asDouble.round();
      final asInt = int.tryParse(s);
      return asInt;
    }
    return null;
  }

  double? toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final s = v.replaceAll('%', '').trim();
      final asDouble = double.tryParse(s);
      if (asDouble == null) return null;
      // 8 or 10 のような整数が来た場合は 0.08 / 0.10 に解釈
      if (asDouble > 1.0) return (asDouble / 100.0);
      return asDouble;
    }
    return null;
  }
}
```

**設計方針**:
- 価格補正ロジックを独立させる
- テスト容易性を重視
- 副作用のないpure function

---

### 2.5 PriceExtractor (価格抽出)

**責務**: OCRテキストから価格を抽出し、税込/税抜を判定

**ファイルパス**: `lib/services/chatgpt/price_extractor.dart`

```dart
/// 価格抽出ロジック
class PriceExtractor {
  final PriceNormalizer _normalizer = PriceNormalizer();

  /// OCRテキストから整数価格を抽出
  List<PriceMatch> extractIntegerPrices(String ocrText) {
    final results = <PriceMatch>[];
    final pricePattern = RegExp(r'(\d+)\s*円');
    final matches = pricePattern.allMatches(ocrText);

    for (final match in matches) {
      final startIdx = match.start;
      final precededByDot = startIdx > 0 && ocrText[startIdx - 1] == '.';
      final precededByHyphen = startIdx > 0 && ocrText[startIdx - 1] == '-';
      final isUnit = _normalizer.isUnitPriceContextNearby(
          ocrText, match.start, match.end);

      if (precededByDot || precededByHyphen || isUnit) {
        continue;
      }

      final price = int.tryParse(match.group(1) ?? '');
      if (price != null && price > 0 && price <= 100000) {
        results.add(PriceMatch(
          price: price,
          startIndex: match.start,
          endIndex: match.end,
          rawText: match.group(0)!,
        ));
      }
    }

    return results;
  }

  /// OCRテキストから小数点価格を抽出（税込優先）
  List<PriceMatch> extractDecimalPrices(String ocrText) {
    final results = <PriceMatch>[];
    final decimalPricePattern = RegExp(r'(\d+)\.(\d{1,2})円');
    final matches = decimalPricePattern.allMatches(ocrText);

    for (final match in matches) {
      final intPart = int.tryParse(match.group(1) ?? '');
      final decimalPart = int.tryParse(match.group(2) ?? '');

      if (intPart != null &&
          decimalPart != null &&
          decimalPart <= 99 &&
          intPart >= 100) {
        final hasNearbyTax =
            _normalizer.hasTaxLabelNearby(ocrText, match.start, match.end);
        final hasSameLineTax =
            _normalizer.hasTaxLabelInSameLine(ocrText, match.start);
        final isUnit = _normalizer.isUnitPriceContextNearby(
            ocrText, match.start, match.end,
            window: 12);

        if ((hasSameLineTax || hasNearbyTax) && !isUnit) {
          final rounded = ((intPart * 100 + decimalPart) / 100.0).round();
          results.add(PriceMatch(
            price: rounded,
            startIndex: match.start,
            endIndex: match.end,
            rawText: match.group(0)!,
            isTaxIncluded: true,
          ));
        }
      }
    }

    return results;
  }

  /// OCRテキストからハイフン価格を抽出
  List<PriceMatch> extractHyphenPrices(String ocrText) {
    final results = <PriceMatch>[];
    final hyphenPricePattern = RegExp(r'(\d+)-(\d{1,2})円');
    final matches = hyphenPricePattern.allMatches(ocrText);

    for (final match in matches) {
      final intPart = int.tryParse(match.group(1) ?? '');
      final decimalPart = int.tryParse(match.group(2) ?? '');

      if (intPart != null && decimalPart != null && decimalPart <= 99) {
        final hasNearbyTax =
            _normalizer.hasTaxLabelNearby(ocrText, match.start, match.end);
        final isUnit = _normalizer.isUnitPriceContextNearby(
            ocrText, match.start, match.end,
            window: 12);

        if (hasNearbyTax && !isUnit) {
          results.add(PriceMatch(
            price: intPart,
            startIndex: match.start,
            endIndex: match.end,
            rawText: match.group(0)!,
            isTaxIncluded: true,
          ));
        }
      }
    }

    return results;
  }

  /// 最適な価格を選択（税込優先、高額優先）
  PriceMatch? selectBestPrice(List<PriceMatch> prices) {
    if (prices.isEmpty) return null;

    // 税込価格を優先
    final taxIncludedPrices =
        prices.where((p) => p.isTaxIncluded ?? false).toList();
    if (taxIncludedPrices.isNotEmpty) {
      taxIncludedPrices.sort((a, b) => b.price.compareTo(a.price));
      return taxIncludedPrices.first;
    }

    // 税込がない場合は高い価格を優先
    prices.sort((a, b) => b.price.compareTo(a.price));
    return prices.first;
  }
}

/// 価格マッチ結果
class PriceMatch {
  final int price;
  final int startIndex;
  final int endIndex;
  final String rawText;
  final bool? isTaxIncluded;

  PriceMatch({
    required this.price,
    required this.startIndex,
    required this.endIndex,
    required this.rawText,
    this.isTaxIncluded,
  });
}
```

**設計方針**:
- 価格抽出ロジックを独立させる
- 各抽出パターンを明確に分離
- テスト容易性を重視

---

### 2.6 ResponseParser (レスポンス解析)

**責務**: OpenAI APIのレスポンスを解析し、構造化データに変換

**ファイルパス**: `lib/services/chatgpt/response_parser.dart`

```dart
/// OpenAI APIレスポンスの解析
class ResponseParser {
  final PriceNormalizer _normalizer = PriceNormalizer();

  /// ChatGptItemResultを解析
  ChatGptItemResult? parseProductExtraction(String content, String ocrText) {
    try {
      final result = jsonDecode(content) as Map<String, dynamic>;

      final productName = result['product_name'] as String? ?? '';
      final priceJpy = result['price_jpy'] as int? ?? 0;
      final priceType = result['price_type'] as String? ?? '不明';
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final rawMatches = result['raw_matches'] as List<dynamic>? ?? [];

      // 税込価格の後処理
      String finalPriceType = priceType;
      int finalPrice = priceJpy;
      double finalConfidence = confidence;

      // 小数点誤認識の修正
      if (_normalizer.isLikelyDecimalMisread(finalPrice, ocrText)) {
        finalPrice = _normalizer.correctDecimalMisread(finalPrice);
        finalConfidence = (confidence + 0.3).clamp(0.0, 1.0);
        debugPrint('🔧 小数点誤認識修正: $priceJpy円 → $finalPrice円');
      }

      // 商品名が空の場合は除外
      if (productName.isEmpty) {
        debugPrint('⚠️ 商品名が空のため除外');
        return null;
      }

      // 価格が0の場合は、実際に0円の商品かどうかを確認
      if (finalPrice == 0) {
        if (productName.contains('無料') ||
            productName.contains('フリー') ||
            productName.contains('0円')) {
          debugPrint('💰 無料商品として認識: $productName');
        } else {
          debugPrint('⚠️ 価格が0円で、無料商品の可能性が低いため除外');
          return null;
        }
      }

      return ChatGptItemResult(
        name: productName,
        price: finalPrice,
        priceType: finalPriceType,
        confidence: finalConfidence,
        rawMatches: rawMatches,
      );
    } catch (e) {
      debugPrint('❌ ChatGPT結果のJSON解析に失敗: $e');
      return null;
    }
  }

  /// 価格候補リストを解析
  List<Map<String, dynamic>> parsePriceCandidates(String content) {
    try {
      final parsed = jsonDecode(content);
      List<dynamic> rawCandidates;

      if (parsed is Map<String, dynamic> && parsed['candidates'] is List) {
        rawCandidates = parsed['candidates'] as List<dynamic>;
      } else if (parsed is List) {
        rawCandidates = parsed;
      } else {
        debugPrint('⚠️ 期待形式と異なるJSONでした（新仕様）');
        return [];
      }

      final results = <Map<String, dynamic>>[];
      for (final c in rawCandidates) {
        if (c is Map<String, dynamic>) {
          final name = (c['商品名'] ?? c['name'] ?? '').toString();
          final ex = _normalizer.toIntOrNull(c['税抜価格']);
          final inc = _normalizer.toIntOrNull(c['税込価格']);
          final rate = _normalizer.toDoubleOrNull(c['税率']);
          if (name.isEmpty) continue;
          results.add({
            '商品名': name,
            '税抜価格': ex,
            '税込価格': inc,
            '税率': rate,
          });
        }
      }

      return results;
    } catch (e) {
      debugPrint('❌ ChatGPT結果のJSON解析に失敗（新仕様）: $e');
      return [];
    }
  }
}
```

**設計方針**:
- レスポンス解析を独立させる
- エラーハンドリングを統一
- テスト容易性を重視

---

## 3. データフロー

### 3.1 extractProductInfo（シンプル版）

```
OCRテキスト
    ↓
ChatGptService.extractProductInfo()
    ↓
PromptTemplate.getProductExtractionPrompt()
    ↓
OpenAIClient.chatCompletion()
    ↓ (OpenAI API呼び出し)
    ↓
ResponseParser.parseProductExtraction()
    ↓
PriceNormalizer.isLikelyDecimalMisread()
    ↓
OcrItemResult
```

### 3.2 extractProductInfoFromImage（Vision API版）

```
画像ファイル
    ↓
ChatGptService.extractProductInfoFromImage()
    ↓
PromptTemplate.getVisionExtractionPrompt()
    ↓
OpenAIClient.chatCompletion() (with Base64 image)
    ↓ (OpenAI Vision API呼び出し)
    ↓
ResponseParser.parseProductExtraction()
    ↓
OcrItemResult
```

### 3.3 extractPriceCandidates（新仕様）

```
OCRテキスト
    ↓
ChatGptService.extractPriceCandidates()
    ↓
PromptTemplate.getPriceCandidatesPrompt()
    ↓
OpenAIClient.chatCompletion()
    ↓ (OpenAI API呼び出し)
    ↓
ResponseParser.parsePriceCandidates()
    ↓
List<Map<String, dynamic>>
```

---

## 4. ファイル構成

```
lib/services/
├── chatgpt_service.dart          # ファサード（約200行）
└── chatgpt/
    ├── openai_client.dart        # API通信層（約150行）
    ├── prompt_template.dart      # プロンプト管理（約200行）
    ├── price_normalizer.dart     # 価格補正（約150行）
    ├── price_extractor.dart      # 価格抽出（約150行）
    ├── response_parser.dart      # レスポンス解析（約100行）
    └── models.dart               # データモデル（約50行）

test/services/
└── chatgpt/
    ├── openai_client_test.dart
    ├── prompt_template_test.dart
    ├── price_normalizer_test.dart
    ├── price_extractor_test.dart
    ├── response_parser_test.dart
    └── chatgpt_service_test.dart # 統合テスト
```

---

## 5. マイグレーション戦略

### 5.1 段階的移行

1. **フェーズ1**: 新クラスの作成と単体テスト
2. **フェーズ2**: ChatGptServiceに新クラスを統合（内部実装のみ変更）
3. **フェーズ3**: 既存テストの実行と動作確認
4. **フェーズ4**: 依存サービス（VisionOcrService等）の動作確認
5. **フェーズ5**: 本番環境デプロイ

### 5.2 ロールバック計画

- 問題発生時は即座にgit revertでロールバック
- Feature Flagを使用して段階的にリリース（推奨）
- 旧実装をコメントアウトで残す（一時的）

---

## 6. パフォーマンス考慮事項

### 6.1 メモリ使用量

- クラスのインスタンス生成を最小限に
- プロンプトテンプレートはシングルトン化を検討
- 大きなプロンプト文字列は遅延初期化

### 6.2 API呼び出し回数

- リファクタリング前と同じ回数を維持
- キャッシュ機能は別Issueで実装

### 6.3 レスポンス時間

- 既存と同等またはそれ以上を維持
- 不要な処理を削減

---

## 7. セキュリティ考慮事項

- APIキーの取り扱いを厳重に
- ログ出力時にAPIキーをマスク
- HTTPクライアントのタイムアウトを適切に設定

---

## 8. 今後の拡張性

### 8.1 他のLLMサービスへの対応

- OpenAIClient → LLMClientインターフェースに抽象化
- AnthropicClient, GeminiClient等の実装を追加

### 8.2 プロンプトの改善

- A/Bテストによるプロンプト最適化
- ユーザーフィードバックに基づく改善

### 8.3 キャッシュ機能

- レスポンスのキャッシュ
- プロンプトテンプレートのキャッシュ
