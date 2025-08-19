@echo off
chcp 65001 >nul
echo 🌐 Flutterアプリ用potファイル生成ツール
echo ==================================================
echo.

REM Pythonが利用可能かチェック
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Pythonが見つかりません。
    echo Pythonをインストールしてから再実行してください。
    echo https://www.python.org/downloads/
    pause
    exit /b 1
)

REM ARBファイルの存在確認
if not exist "lib\l10n\app_en.arb" (
    echo ❌ ARBファイルが見つかりません: lib\l10n\app_en.arb
    echo 先にARBファイルを作成してください。
    pause
    exit /b 1
)

echo 📁 ARBファイルを確認中...
echo ✅ lib\l10n\app_en.arb が見つかりました

echo.
echo 🔧 potファイルを生成中...
python generate_pot.py

if errorlevel 1 (
    echo.
    echo ❌ potファイルの生成に失敗しました。
    pause
    exit /b 1
)

echo.
echo 📋 生成されたファイル:
if exist "lib\l10n\app.pot" (
    echo ✅ lib\l10n\app.pot
    echo.
    echo 📊 ファイル情報:
    for %%A in ("lib\l10n\app.pot") do (
        echo サイズ: %%~zA バイト
        echo 更新日時: %%~tA
    )
) else (
    echo ❌ lib\l10n\app.pot が見つかりません
)

echo.
echo 🎉 potファイルの生成が完了しました！
echo.
echo 📝 使用方法:
echo 1. 翻訳者はこのpotファイルをpoファイルに変換
echo 2. 翻訳作業を実施
echo 3. poファイルをmoファイルにコンパイル
echo 4. Flutterアプリに組み込み
echo.
pause
