# タスクリスト

## フェーズ1: 調査
- [ ] Web版でダイアログの表示幅を実機確認
- [ ] `showDialog`/`showModalBottomSheet`の使用箇所をGrepで検索
- [ ] `lib/screens/main/dialogs/`内のダイアログ一覧確認

## フェーズ2: 修正
- [ ] 方針選択:
  - A: 各ダイアログ内に`ConstrainedBox(maxWidth: 800)`を追加
  - B: `showDialog`のラッパー関数を作成して横幅制限を統一
  - C: `MaterialApp.builder`内でOverlay も含めた制限を実装
- [ ] 選択した方針で全ダイアログ・ボトムシートを修正

## フェーズ3: 確認
- [ ] Web版で全ダイアログの表示を確認
- [ ] モバイル版で動作に影響がないことを確認

## 依存関係
- フェーズ1 → フェーズ2 → フェーズ3（順次実行）
