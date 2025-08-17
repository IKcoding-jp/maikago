@echo off
REM Firestoreセキュリティルールデプロイスクリプト（Windows版）
REM 使用方法: deploy-rules.bat [PROJECT_ID]

setlocal enabledelayedexpansion

REM プロジェクトIDの設定
if "%~1"=="" (
    echo 使用方法: %0 [PROJECT_ID]
    echo 例: %0 your-project-id
    exit /b 1
)

set PROJECT_ID=%~1

echo 🚀 Firestoreセキュリティルールをデプロイ中...
echo プロジェクトID: %PROJECT_ID%

REM Firebase CLIがインストールされているかチェック
firebase --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Firebase CLIがインストールされていません。
    echo 以下のコマンドでインストールしてください:
    echo npm install -g firebase-tools
    exit /b 1
)

REM ログイン状態をチェック
firebase projects:list >nul 2>&1
if errorlevel 1 (
    echo 🔐 Firebaseにログインしてください...
    firebase login
)

REM プロジェクトが存在するかチェック
firebase projects:list | findstr "%PROJECT_ID%" >nul
if errorlevel 1 (
    echo ❌ プロジェクト '%PROJECT_ID%' が見つかりません。
    echo 利用可能なプロジェクト:
    firebase projects:list
    exit /b 1
)

REM firebase.jsonファイルが存在するかチェック
if not exist "firebase.json" (
    echo 📝 firebase.jsonファイルを作成中...
    (
        echo {
        echo   "firestore": {
        echo     "rules": "firestore.rules",
        echo     "indexes": "firestore.indexes.json"
        echo   }
        echo }
    ) > firebase.json
)

REM セキュリティルールをデプロイ
echo 📤 セキュリティルールをデプロイ中...
firebase deploy --only firestore:rules --project "%PROJECT_ID%"

if errorlevel 1 (
    echo ❌ デプロイに失敗しました。
    exit /b 1
)

echo ✅ セキュリティルールのデプロイが完了しました！
echo.
echo 📋 デプロイされたルールの概要:
echo   - ユーザー認証: 自分のデータのみアクセス可能
echo   - ファミリー共有: ファミリーメンバーのみアクセス可能
echo   - 送信型共有: 送信者・受信者のみアクセス可能
echo   - リアルタイム共有: 作成者・共有対象者のみアクセス可能
echo   - 通知機能: 通知の所有者のみアクセス可能
echo   - 匿名ユーザー: 匿名データは誰でもアクセス可能
echo.
echo 🔒 セキュリティルールが正常に適用されました。

pause
