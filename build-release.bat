@echo off
REM まいカゴ リリースビルドスクリプト
REM 使用方法: build-release.bat

echo まいカゴ リリースビルドを開始します...

REM 環境変数の設定例（実際の値に置き換えてください）
REM set ADMOB_INTERSTITIAL_AD_UNIT_ID="ca-app-pub-xxx/yyy"
REM set ADMOB_BANNER_AD_UNIT_ID="ca-app-pub-xxx/zzz"
REM set MAIKAGO_ALLOW_CLIENT_DONATION_WRITE="false"
REM set MAIKAGO_SPECIAL_DONOR_EMAIL=""
REM set MAIKAGO_ENABLE_DEBUG_MODE="false"
REM set MAIKAGO_SECURITY_LEVEL="strict"

REM 本番（PowerShell）での実行例:
REM setx ADMOB_INTERSTITIAL_AD_UNIT_ID "ca-app-pub-xxx/yyy"
REM setx ADMOB_BANNER_AD_UNIT_ID "ca-app-pub-xxx/zzz"
REM setx MAIKAGO_ALLOW_CLIENT_DONATION_WRITE "false"
REM setx MAIKAGO_SPECIAL_DONOR_EMAIL ""
REM setx MAIKAGO_ENABLE_DEBUG_MODE "false"
REM setx MAIKAGO_SECURITY_LEVEL "strict"
REM 新しいシェルで
REM flutter build apk --release --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=%ADMOB_INTERSTITIAL_AD_UNIT_ID% --dart-define=ADMOB_BANNER_AD_UNIT_ID=%ADMOB_BANNER_AD_UNIT_ID% --dart-define=MAIKAGO_ALLOW_CLIENT_DONATION_WRITE=%MAIKAGO_ALLOW_CLIENT_DONATION_WRITE% --dart-define=MAIKAGO_SPECIAL_DONOR_EMAIL=%MAIKAGO_SPECIAL_DONOR_EMAIL% --dart-define=MAIKAGO_ENABLE_DEBUG_MODE=%MAIKAGO_ENABLE_DEBUG_MODE% --dart-define=MAIKAGO_SECURITY_LEVEL=%MAIKAGO_SECURITY_LEVEL%

echo リリースビルドを実行中...
flutter build apk --release ^
  --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=%ADMOB_INTERSTITIAL_AD_UNIT_ID% ^
  --dart-define=ADMOB_BANNER_AD_UNIT_ID=%ADMOB_BANNER_AD_UNIT_ID% ^
  --dart-define=MAIKAGO_ALLOW_CLIENT_DONATION_WRITE=%MAIKAGO_ALLOW_CLIENT_DONATION_WRITE% ^
  --dart-define=MAIKAGO_SPECIAL_DONOR_EMAIL=%MAIKAGO_SPECIAL_DONOR_EMAIL% ^
  --dart-define=MAIKAGO_ENABLE_DEBUG_MODE=%MAIKAGO_ENABLE_DEBUG_MODE% ^
  --dart-define=MAIKAGO_SECURITY_LEVEL=%MAIKAGO_SECURITY_LEVEL%

if %ERRORLEVEL% EQU 0 (
    echo ビルドが正常に完了しました！
    echo APKファイル: build/app/outputs/flutter-apk/app-release.apk
) else (
    echo ビルドに失敗しました。エラーを確認してください。
    exit /b 1
)

echo.
echo セキュリティ設定確認:
echo - 広告ID: %ADMOB_INTERSTITIAL_AD_UNIT_ID%
echo - 寄付書き込み許可: %MAIKAGO_ALLOW_CLIENT_DONATION_WRITE%
echo - 特別寄付者: %MAIKAGO_SPECIAL_DONOR_EMAIL%
echo - デバッグモード: %MAIKAGO_ENABLE_DEBUG_MODE%
echo - セキュリティレベル: %MAIKAGO_SECURITY_LEVEL%
echo.
echo ビルド完了！