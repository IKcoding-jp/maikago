/// ネイティブプラットフォーム用のスタブ実装
/// Webプラットフォームでは web_utils_web.dart が使用される
library;

/// モバイルWebかどうかを判定（ネイティブでは常にfalse）
bool isMobileWeb() {
  return false;
}
