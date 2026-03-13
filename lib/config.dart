// セキュリティ設定とビルド時注入パラメータ
// - 目的: ソースコードに秘匿情報（広告IDなど）をハードコードしない
// - 方法: Flutter の --dart-define 経由でビルド時に注入
// - 安全性の根拠: 署名済みバイナリからの抽出難度はあるものの、リポジトリに平文を残さないことで露出面を削減

// AdMob テスト用ID（Google公式）
// 本番IDは env.json または --dart-define で注入
const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// AdMob バナー広告ユニットID（デフォルトはテスト用ID）
const String adBannerUnitId = String.fromEnvironment(
  'ADMOB_BANNER_AD_UNIT_ID',
  defaultValue: _testBannerAdUnitId,
);

/// デバッグモードの有効化
/// 本番環境では false に設定し、詳細なログ出力を無効化
/// セキュリティ根拠: 本番環境での情報漏洩を防止
const bool configEnableDebugMode = bool.fromEnvironment(
  'MAIKAGO_ENABLE_DEBUG_MODE',
  defaultValue: false,
);

/// ログ出力レベル（verbose, debug, info, warning, error）
/// デフォルト: info（info以上を表示）
/// 詳細ログが必要な場合: --dart-define=MAIKAGO_LOG_LEVEL=debug
const String configLogLevel = String.fromEnvironment(
  'MAIKAGO_LOG_LEVEL',
  defaultValue: 'info',
);

/// デバッグ時でも広告を強制表示するフラグ（プレミアム判定を無視）
const bool configForceShowAdsInDebug = bool.fromEnvironment(
  'MAIKAGO_FORCE_SHOW_ADS_IN_DEBUG',
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

/// OpenAI モデル名（JSONモード対応の軽量モデルを既定に）
const String openAIModel = String.fromEnvironment(
  'OPENAI_MODEL',
  defaultValue: 'gpt-4o-mini',
);

/// 画像解析の高速化設定
/// 画像解析のタイムアウト時間（秒）
const int imageAnalysisTimeoutSeconds = int.fromEnvironment(
  'IMAGE_ANALYSIS_TIMEOUT_SECONDS',
  defaultValue: 20,
);

/// Cloud Functionsのタイムアウト時間（秒）
const int cloudFunctionsTimeoutSeconds = int.fromEnvironment(
  'CLOUD_FUNCTIONS_TIMEOUT_SECONDS',
  defaultValue: 30, // シンプル版のため30秒に延長
);

/// Vision APIのタイムアウト時間（秒）
const int visionApiTimeoutSeconds = int.fromEnvironment(
  'VISION_API_TIMEOUT_SECONDS',
  defaultValue: 15, // 高速化のため25秒から15秒に短縮
);

/// ChatGPT APIのタイムアウト時間（秒）
const int chatGptTimeoutSeconds = int.fromEnvironment(
  'CHATGPT_TIMEOUT_SECONDS',
  defaultValue: 30, // タイムアウトエラー対策のため30秒に延長
);

/// ChatGPT APIの最大リトライ回数
const int chatGptMaxRetries = int.fromEnvironment(
  'CHATGPT_MAX_RETRIES',
  defaultValue: 3,
);

/// 画像最適化の最大サイズ（ピクセル）
const int maxImageSize = int.fromEnvironment(
  'MAX_IMAGE_SIZE',
  defaultValue: 800, // シンプル版のため800に戻す（OCR精度向上）
);

/// 画像品質（0-100）
const int imageQuality = int.fromEnvironment(
  'IMAGE_QUALITY',
  defaultValue: 85, // 75から85に増加（OCR精度向上）
);
