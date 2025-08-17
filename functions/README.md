この Cloud Function は、ファミリー（group）作成時に該当メンバー全員のサブスクリプションを `family` としてマークします。

デプロイ手順:
1. Firebase CLI をセットアップしログインします。
2. `cd functions` を実行してディレクトリに移動します。
3. `npm install` を実行して依存関係をインストールします。
4. `firebase deploy --only functions:applyFamilyPlanToGroup` を実行してデプロイします。

注意:
- Firestore のセキュリティルールによりクライアントからの直接更新が制限されている場合、この関数が必要になります。
- 関数は `families/{familyId}` ドキュメントが作成されたときにトリガーされます。


