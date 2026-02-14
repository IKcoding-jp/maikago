# 設計書: Issue #10

## 変更対象ファイル

### 1. `lib/config.dart`
- **変更箇所**: L38 `defaultValue: true` → `defaultValue: false`
- **影響**: デバッグモードがデフォルトで無効化される。開発時は`--dart-define`で明示的に有効化が必要

### 2. `lib/services/chatgpt_service.dart`
- **変更箇所1**: L30-35 コンストラクタ内のAPIキー状態確認ログ → 削除
- **変更箇所2**: L349 エラー時のAPIキーログ → 削除
- **変更箇所3**: L773 エラー時のAPIキーログ → 削除
- **方針**: APIキーの値（部分含む）をログ出力する行を削除。キーの長さ・空チェックのログも不要（機密情報の存在有無が推測可能なため）

### 3. `lib/services/product_name_summarizer_service.dart`
- **変更箇所1**: L16-20 APIキー状態確認ログ → 削除
- **変更箇所2**: L160 エラー時のAPIキーログ → 削除

## 既存のセキュリティ機構

`DebugService`は`kDebugMode && !kReleaseMode && configEnableDebugMode`の3条件で制御しているが、問題の`debugPrint`呼び出しは`DebugService`を経由せず直接呼ばれている。Flutterの`debugPrint`はリリースビルドでは出力されないが、防御的にAPIキー関連のログ自体を削除するのが適切。

## 非変更事項

- CI/CD設定: 現状`--dart-define`によるデバッグモード制御は設定されていないが、デフォルト値を`false`にすることで本番安全性は確保される。CI/CD側の変更は本Issueのスコープ外とする
