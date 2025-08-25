import 'env.dart';

// セキュリティ設定とビルド時注入パラメータ
// - 目的: ソースコードに秘匿情報（広告IDなど）をハードコードしない
// - 方法: Flutter の --dart-define 経由でビルド時に注入
// - 安全性の根拠: 署名済みバイナリからの抽出難度はあるものの、リポジトリに平文を残さないことで露出面を削減

/// AdMob インタースティシャル広告ユニットID
/// 既定値は Google の公開テストID（秘密情報ではない）
const String adInterstitialUnitId = String.fromEnvironment(
  'ADMOB_INTERSTITIAL_AD_UNIT_ID',
  defaultValue: 'ca-app-pub-3940256099942544/1033173712',
);

/// AdMob バナー広告ユニットID
/// 既定値は Google の公開テストID（秘密情報ではない）
const String adBannerUnitId = String.fromEnvironment(
  'ADMOB_BANNER_AD_UNIT_ID',
  defaultValue: 'ca-app-pub-3940256099942544/6300978111',
);

/// クライアントから寄付状態（donations）を書き込むことを許可するか
/// 既定は false（禁止）。サーバー側（Cloud Functions等）からのみ書き込みを許可する前提。
/// セキュリティ根拠: 不正なクライアントによる寄付特典の自己付与を防止
const bool allowClientDonationWrite = bool.fromEnvironment(
  'MAIKAGO_ALLOW_CLIENT_DONATION_WRITE',
  defaultValue: false,
);

/// 特別寄付者のメールアドレス（開発者用）
/// 本番環境では空文字列に設定し、開発時のみ使用
/// セキュリティ根拠: ハードコードされた値を排除し、環境別に管理可能にする
const String specialDonorEmail = String.fromEnvironment(
  'MAIKAGO_SPECIAL_DONOR_EMAIL',
  defaultValue: '',
);

/// デバッグモードの有効化
/// 本番環境では false に設定し、詳細なログ出力を無効化
/// セキュリティ根拠: 本番環境での情報漏洩を防止
const bool enableDebugMode = bool.fromEnvironment(
  'MAIKAGO_ENABLE_DEBUG_MODE',
  defaultValue: false,
);

/// セキュリティレベル設定
/// - 'strict': 最も厳格なセキュリティ設定
/// - 'normal': 通常のセキュリティ設定
/// - 'relaxed': 開発用の緩いセキュリティ設定
const String securityLevel = String.fromEnvironment(
  'MAIKAGO_SECURITY_LEVEL',
  defaultValue: 'normal',
);

/// クライアントからサブスクリプション状態（subscriptions）を書き込むことを許可するか
/// 既定は false（禁止）。サーバー側（Cloud Functions等）からのみ書き込みを許可する前提。
/// セキュリティ根拠: 不正なクライアントによるサブスクリプション特典の自己付与を防止
const bool allowClientSubscriptionWrite = bool.fromEnvironment(
  'MAIKAGO_ALLOW_CLIENT_SUBSCRIPTION_WRITE',
  defaultValue: false,
);

/// 寄付用のプロダクトIDリスト
/// Google Play Consoleで設定した課金アイテムのプロダクトID
const List<String> donationProductIds = [
  'donation_300', // 300円
  'donation_500', // 500円
  'donation_1000', // 1000円
  'donation_2000', // 2000円
  'donation_5000', // 5000円
  'donation_10000', // 10000円
];

/// Google Cloud Vision APIキー
/// 本番環境では環境変数から読み込むことを推奨
const String googleVisionApiKey = Env.googleVisionApiKey;

/// OpenAI APIキー（ChatGPT整形用）
const String openAIApiKey = Env.openAIApiKey;

/// OpenAI モデル名（JSONモード対応の軽量モデルを既定に）
const String openAIModel = String.fromEnvironment(
  'OPENAI_MODEL',
  defaultValue: 'gpt-5-nano',
);
