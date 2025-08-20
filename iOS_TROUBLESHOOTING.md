# iOS版トラブルシューティングガイド

## iOS版でアプリがクラッシュする場合の対処法

### 1. 開発環境の確認
macOS環境で以下のコマンドを実行して、FlutterとiOSの開発環境が正しく設定されているか確認してください：

```bash
flutter doctor -v
```

### 2. iOSシミュレーターでのテスト
XcodeがインストールされたmacOS環境で以下の手順を実行：

```bash
# iOSシミュレーターの起動
flutter emulators --launch apple_ios_simulator

# アプリのビルドと実行
flutter run --verbose
```

### 3. ログの確認
アプリがクラッシュした場合は、以下の方法で詳細ログを確認：

```bash
# コンソールアプリでクラッシュログを確認
# Xcode → Window → Devices and Simulators → 該当デバイス → View Device Logs
```

### 4. 一般的なiOSクラッシュの原因と解決策

#### Firebase設定の問題
- `GoogleService-Info.plist`ファイルが正しく配置されているか確認
- FirebaseコンソールでiOSアプリが正しく設定されているか確認
- バンドルIDが一致しているか確認

#### 広告SDKの問題
- `Info.plist`の`GADApplicationIdentifier`が正しいか確認
- 広告ネットワークの設定が正しいか確認

#### パーミッションの問題
- 必要なパーミッションが`Info.plist`に追加されているか確認
- カメラ、マイク、フォトライブラリの使用許可が適切に設定されているか確認

#### メモリの問題
- 大きな画像ファイルや動画ファイルが適切に解放されているか確認
- メモリリークがないか確認

### 5. ビルド時のエラーハンドリング

#### Xcodeでのビルド
```bash
# プロジェクトのクリーン
flutter clean

# iOS依存関係の再構築
cd ios
pod install
cd ..

# リリースビルド
flutter build ios --release --verbose
```

#### Podfileの問題解決
iOSの`Podfile`で以下を確認：
- `platform :ios, '16.0'`が設定されている
- `use_frameworks!`と`use_modular_headers!`が設定されている
- デプロイメントターゲットが正しい

### 6. 設定ファイルの確認項目

#### Info.plistの必須項目
```xml
<!-- カメラ使用許可 -->
<key>NSCameraUsageDescription</key>
<string>QRコードスキャンのためカメラを使用します</string>

<!-- マイク使用許可 -->
<key>NSMicrophoneUsageDescription</key>
<string>音声入力のためマイクを使用します</string>

<!-- フォトライブラリ使用許可 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>画像の選択・保存のためフォトライブラリにアクセスします</string>

<!-- ネットワーク通信許可 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 7. 緊急時の対応

アプリが起動しない場合は：

1. **強制終了と再起動**
   - アプリを完全に終了
   - デバイスの再起動
   - アプリの再インストール

2. **設定のリセット**
   - SharedPreferencesのクリア
   - アプリの再インストール

3. **システムログの確認**
   - Xcodeのコンソールログを確認
   - iOSデバイスのコンソールログを確認

### 8. デバッグモードでの実行

```bash
# デバッグモードで実行（詳細ログ出力）
flutter run --debug --verbose

# 特定のiOSデバイスを指定
flutter run --device-id <device_id>
```

### 9. よくあるエラーメッセージと対処法

#### "FirebaseApp.configure() failed"
- GoogleService-Info.plistファイルの確認
- Firebaseプロジェクトの設定確認

#### "MobileAds.initialize() failed"
- 広告IDの確認
- ネットワーク接続の確認

#### "SharedPreferences.setString() failed"
- iOSのサンドボックス権限の確認
- ファイルシステムのアクセス権確認

## サポートが必要な場合

上記の対処法で解決しない場合は：

1. コンソールログを収集
2. 使用しているiOSのバージョンとデバイス情報を記録
3. Flutter doctorの出力結果を共有
4. Xcodeのビルドログを共有

これらの情報があれば、より具体的な解決策を提供できます。
