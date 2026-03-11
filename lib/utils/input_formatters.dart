import 'package:flutter/services.dart';

/// 先頭ゼロを許可しないフォーマッター
///
/// 例: "01" → "1", "007" → "7"
/// "0" 単体は許可する（[allowSingleZero] が true の場合）
TextInputFormatter noLeadingZeroFormatter({bool allowSingleZero = false}) {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (allowSingleZero && newValue.text == '0') return newValue;
    if (newValue.text.startsWith('0') && newValue.text.length > 1) {
      return TextEditingValue(
        text: newValue.text.substring(1),
        selection: TextSelection.collapsed(
          offset: newValue.text.length - 1,
        ),
      );
    }
    return newValue;
  });
}
