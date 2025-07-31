@echo off
echo リリースビルドを開始します...

REM 環境変数を設定
call android\app\set-env.bat

REM Flutterのクリーンビルド
flutter clean
flutter pub get

REM リリースビルド（APK）
echo APKをビルド中...
flutter build apk --release

REM リリースビルド（AAB）
echo AABをビルド中...
flutter build appbundle --release

echo ビルドが完了しました！
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo AAB: build\app\outputs\bundle\release\app-release.aab