#!/bin/bash

# Firestoreセキュリティルールデプロイスクリプト
# 使用方法: ./deploy-rules.sh [PROJECT_ID]

set -e

# プロジェクトIDの設定
if [ -z "$1" ]; then
    echo "使用方法: $0 [PROJECT_ID]"
    echo "例: $0 your-project-id"
    exit 1
fi

PROJECT_ID=$1

echo "🚀 Firestoreセキュリティルールをデプロイ中..."
echo "プロジェクトID: $PROJECT_ID"

# Firebase CLIがインストールされているかチェック
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLIがインストールされていません。"
    echo "以下のコマンドでインストールしてください:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# ログイン状態をチェック
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Firebaseにログインしてください..."
    firebase login
fi

# プロジェクトが存在するかチェック
if ! firebase projects:list | grep -q "$PROJECT_ID"; then
    echo "❌ プロジェクト '$PROJECT_ID' が見つかりません。"
    echo "利用可能なプロジェクト:"
    firebase projects:list
    exit 1
fi

# firebase.jsonファイルが存在するかチェック
if [ ! -f "firebase.json" ]; then
    echo "📝 firebase.jsonファイルを作成中..."
    cat > firebase.json << EOF
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
EOF
fi

# セキュリティルールをデプロイ
echo "📤 セキュリティルールをデプロイ中..."
firebase deploy --only firestore:rules --project "$PROJECT_ID"

echo "✅ セキュリティルールのデプロイが完了しました！"
echo ""
echo "📋 デプロイされたルールの概要:"
echo "  - ユーザー認証: 自分のデータのみアクセス可能"
echo "  - ファミリー共有: ファミリーメンバーのみアクセス可能"
echo "  - 送信型共有: 送信者・受信者のみアクセス可能"
echo "  - リアルタイム共有: 作成者・共有対象者のみアクセス可能"
echo "  - 通知機能: 通知の所有者のみアクセス可能"
echo "  - 匿名ユーザー: 匿名データは誰でもアクセス可能"
echo ""
echo "🔒 セキュリティルールが正常に適用されました。"
