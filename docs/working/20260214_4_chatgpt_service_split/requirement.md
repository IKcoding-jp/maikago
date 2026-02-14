# Issue #4: ChatGPTサービスの責務分割

**Issue番号**: #4
**作成日**: 2026-02-14
**ラベル**: refactor, critical
**優先度**: High
**関連ファイル**: `lib/services/chatgpt_service.dart`

## 概要

`ChatGptService`クラス（約1,487行）は複数の責務を担っており、単一責任原則に違反している。OpenAI APIの呼び出し、価格解析ロジック、OCRテキスト処理、レシピ解析など、異なる関心事が混在しているため、保守性・テスト容易性・拡張性が低下している。

## 現状の問題点

### 1. 責務の混在
現在の`ChatGptService`は以下の複数の責務を担っている：

- **OpenAI API通信**: HTTP通信、認証、エラーハンドリング、リトライロジック
- **価格抽出ロジック**: OCRテキストからの価格候補抽出、税込/税抜判定
- **価格補正ロジック**: 小数点誤認識修正、ハイフン価格修正、単価文脈除外
- **プロンプト管理**: システムプロンプト、ユーザープロンプトの組み立て
- **レスポンス解析**: JSON解析、候補選択、信頼度計算
- **画像解析**: Vision API連携、Base64エンコーディング

### 2. コードの肥大化

- **総行数**: 1,487行（コメント含む）
- **メソッド数**: 14メソッド（うち4つがpublic API）
- **システムプロンプト**: 400行以上の長大なプロンプト文字列
- **価格補正ロジック**: 600行以上の複雑な条件分岐

### 3. テスト困難性

- 各ロジックが密結合しており、単体テストが困難
- API呼び出しとビジネスロジックの分離ができていない
- モックやスタブの作成が難しい
- 価格補正ロジックの個別テストができない

### 4. 拡張困難性

- 新しい価格抽出ルールの追加が困難
- プロンプトの変更時に影響範囲が不明確
- API仕様変更への対応が複雑
- 他のLLMサービスへの切り替えが困難

## 要件定義

### 機能要件

#### FR-1: API通信の抽象化
- OpenAI APIとの通信を抽象化し、他のLLMサービスへの切り替えを容易にする
- リトライロジック、タイムアウト処理、エラーハンドリングを共通化する
- APIキーの管理を一元化する

#### FR-2: 価格抽出ロジックの分離
- OCRテキストからの価格抽出ロジックを独立したサービスに分離
- 税込/税抜判定ロジックを明確化
- 価格候補の選択ロジックを分離

#### FR-3: 価格補正ロジックの分離
- 小数点誤認識修正を独立した関数に分離
- ハイフン価格修正を独立した関数に分離
- 単価文脈判定を独立した関数に分離
- 各補正ロジックの優先度を明確化

#### FR-4: プロンプト管理の分離
- システムプロンプトを外部ファイルまたは専用クラスで管理
- プロンプトのバージョン管理を可能にする
- プロンプトのテンプレート化を実現

#### FR-5: レスポンス解析の分離
- JSON解析ロジックを独立したクラスに分離
- 信頼度計算を明確化
- エラーハンドリングを統一

### 非機能要件

#### NFR-1: 後方互換性の維持
- 既存の`ChatGptService`の公開APIを維持
- 呼び出し側のコード変更を最小限に抑える
- 段階的な移行を可能にする

#### NFR-2: パフォーマンスの維持
- リファクタリング前と同等以上のパフォーマンスを維持
- API呼び出し回数を増加させない
- メモリ使用量を大幅に増加させない

#### NFR-3: テスト容易性の向上
- 各クラス・メソッドの単体テストが可能
- モック・スタブの作成が容易
- テストカバレッジを80%以上に向上

#### NFR-4: 保守性の向上
- 各クラスの責務を明確化
- 1クラス500行以内を目標
- 1メソッド50行以内を目標

## 成功基準

1. **コード品質**
   - 各クラスが単一責任原則に従っている
   - 循環的複雑度が10以下
   - コードの重複が5%以下

2. **テストカバレッジ**
   - 単体テストカバレッジ80%以上
   - 統合テストで既存機能の動作を確認
   - 価格抽出の精度が低下していない

3. **パフォーマンス**
   - API呼び出し時間が10%以上増加しない
   - メモリ使用量が20%以上増加しない
   - レスポンス時間が10%以上増加しない

4. **保守性**
   - 新しい価格抽出ルールの追加が30分以内で可能
   - プロンプトの変更が15分以内で可能
   - コードレビュー時の理解時間が50%短縮

## 制約事項

1. **技術的制約**
   - Dart 3.0.0以上
   - Flutter SDKのバージョンを維持
   - 既存のパッケージ（http, flutter）を使用

2. **互換性制約**
   - OpenAI API仕様（gpt-4o-mini）との互換性維持
   - Vision API（DOCUMENT_TEXT_DETECTION）との互換性維持
   - 既存のOcrItemResultモデルとの互換性維持

3. **運用制約**
   - 本番環境へのデプロイ前に十分なテストを実施
   - 段階的なリリース（Feature Flag使用を推奨）
   - ロールバック計画を準備

## スコープ外

以下は本リファクタリングのスコープ外とする：

1. **OpenAI API仕様の変更**
   - モデルの変更（gpt-4o-mini → 他モデル）
   - プロンプトの大幅な改善
   - 新機能の追加

2. **UI/UXの変更**
   - ユーザーインターフェースの変更
   - エラーメッセージの変更
   - 進捗表示の変更

3. **他サービスへの影響**
   - `VisionOcrService`のリファクタリング
   - `RecipeParserService`のリファクタリング
   - `HybridOcrService`のリファクタリング

4. **新機能の追加**
   - 他のLLMサービスへの対応
   - 価格抽出精度の向上
   - キャッシュ機能の追加

## 依存関係

### 呼び出し元（3ファイル）
1. `lib/services/vision_ocr_service.dart`
   - `ChatGptService.extractProductInfo()`を使用

2. `lib/services/recipe_parser_service.dart`
   - `ChatGptService`のコンストラクタでDIされて使用

3. `lib/services/hybrid_ocr_service.dart`
   - `ChatGptService.extractProductInfoFromImage()`を使用

### 依存先
- `dart:convert`, `dart:io`（標準ライブラリ）
- `package:http/http.dart`（HTTP通信）
- `package:flutter/foundation.dart`（debugPrint等）
- `package:maikago/config.dart`（設定値）
- `package:maikago/services/vision_ocr_service.dart`（OcrItemResult型）

## 関連Issue

- Issue #3: DataProviderの責務分割（類似のリファクタリング）
- Issue #7: 非同期エラーハンドリングの統一（エラー処理の統一化）
- Issue #8: APIキーのサーバー移行（セキュリティ改善）

## 参考資料

- [Clean Architecture in Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [SOLID Principles in Dart](https://dart.academy/solid-principles-in-dart/)
- [Effective Dart: Design](https://dart.dev/guides/language/effective-dart/design)
