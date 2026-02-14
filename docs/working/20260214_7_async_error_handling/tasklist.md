# タスクリスト

## フェーズ1: 調査
- [ ] `void.*async`パターンの全箇所をGrepで検索
- [ ] `catch (_)`パターンの全箇所をGrepで検索
- [ ] `catch (e)`でログのみの箇所を洗い出し

## フェーズ2: 修正
- [ ] `lib/main.dart:205` - `_checkForUpdatesInBackground`を`Future<void>`に変更
- [ ] `lib/main.dart:213` - `_initializeVersionNotification`を`Future<void>`に変更
- [ ] その他の`void` async関数を修正
- [ ] `lib/services/vision_ocr_service.dart:167`等の`catch (_)`にログ追加
- [ ] 重要な例外（API呼び出し失敗等）のリスロー判断

## フェーズ3: 確認
- [ ] `flutter analyze`でエラーがないこと
- [ ] 各修正箇所の動作確認

## 依存関係
- フェーズ1 → フェーズ2 → フェーズ3（順次実行）
