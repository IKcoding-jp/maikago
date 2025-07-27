# まいカゴ アプリリリース準備チェックリスト

## ✅ 完了済み項目

### コード品質の改善
- [x] print文の削除（本番環境対応）
- [x] 非推奨API（withOpacity）の修正
- [x] 基本的なコード品質チェック

### 設定の修正
- [x] Android Application ID を `com.example.maikago` に変更
- [x] iOS Bundle Display Name を「まいカゴ」に変更
- [x] 広告IDにTODOコメントを追加

## 🔄 リリース前に必要な作業

### 1. 広告IDの設定（重要）
- [ ] Google AdMobで本番用の広告IDを取得
- [ ] `android/app/src/main/AndroidManifest.xml` の広告IDを本番用に変更
- [ ] `ios/Runner/Info.plist` の広告IDを本番用に変更
- [ ] `lib/widgets/ad_banner.dart` のバナー広告IDを本番用に変更

### 2. 署名設定（重要）
- [ ] Android用のリリースキーストアを作成
- [ ] `android/app/build.gradle.kts` の署名設定を本番用に変更
- [ ] iOS用の証明書とプロビジョニングプロファイルを設定

### 3. プライバシーポリシー
- [ ] プライバシーポリシーを作成
- [ ] アプリ内にプライバシーポリシーへのリンクを追加
- [ ] Google Play ConsoleとApp Store Connectにプライバシーポリシーを登録

### 4. アプリストア用の準備
- [ ] アプリアイコンの高解像度版（1024x1024）
- [ ] スクリーンショット（複数サイズ）
- [ ] アプリ説明文の作成
- [ ] キーワードの設定

### 5. テスト
- [ ] リリースビルドでの動作確認
- [ ] 複数デバイスでのテスト
- [ ] オフライン時の動作確認
- [ ] 広告表示の確認

### 6. Firebase設定
- [ ] 本番環境用のFirebaseプロジェクト設定
- [ ] Firestoreセキュリティルールの最終確認
- [ ] Google Sign-Inの本番用設定

## 📋 リリース手順

### Google Play Store
1. Google Play Consoleでアプリを作成
2. APKまたはAABファイルをアップロード
3. ストア情報を入力
4. プライバシーポリシーを設定
5. 審査を申請

### App Store
1. App Store Connectでアプリを作成
2. Xcodeでアーカイブを作成
3. App Store Connectにアップロード
4. ストア情報を入力
5. 審査を申請

## 🚨 注意事項

- 広告IDは必ず本番用に変更してください
- 署名キーは安全に保管してください
- プライバシーポリシーは必須です
- 初回リリースは審査に時間がかかる場合があります

## 📞 サポート

問題が発生した場合は、開発者に連絡してください。 