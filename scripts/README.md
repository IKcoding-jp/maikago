# TensorFlow Lite Model Creator

このディレクトリには、まいカゴアプリ用のTensorFlow Liteモデルを作成するスクリプトが含まれています。

## 🚀 セットアップ

### 1. Python環境の準備

```bash
# Python 3.8以上が必要
python --version

# 仮想環境の作成（推奨）
python -m venv venv
source venv/bin/activate  # Linux/Mac
# または
venv\Scripts\activate     # Windows
```

### 2. 依存関係のインストール

```bash
pip install -r requirements.txt
```

## 📦 モデルの作成

### 基本的な使用方法

```bash
cd scripts
python create_tflite_model.py
```

### 出力ファイル

実行後、以下のファイルが生成されます：

- `../assets/models/product_ocr_model.tflite` - TensorFlow Liteモデルファイル
- `../assets/models/product_labels.txt` - 商品ラベルファイル
- `../assets/models/model_info.json` - モデル情報ファイル

## 🎯 モデルの仕様

### 入力
- 画像サイズ: 224x224ピクセル
- チャンネル: RGB (3チャンネル)
- データ型: float32

### 出力
- 分類確率: 20クラスの確率分布
- データ型: float32

### アーキテクチャ
- CNN (Convolutional Neural Network)
- 4つの畳み込み層
- バッチ正規化
- ドロップアウト
- 全結合層

## 🔧 カスタマイズ

### クラス数の変更

`create_tflite_model.py`の`num_classes`変数を変更してください。

### ラベルの変更

`sample_labels`リストを実際の商品名と価格に変更してください。

### モデルアーキテクチャの変更

`create_product_recognition_model()`関数を修正してください。

## 📊 データセットの準備

実際の使用では、以下の手順でデータセットを準備してください：

1. **画像収集**: スーパーの商品画像を撮影
2. **ラベル付け**: 商品名と価格を付与
3. **前処理**: 画像のリサイズと正規化
4. **データ分割**: 訓練・検証・テストデータに分割

## 🚨 注意事項

- 現在のモデルはダミーデータで訓練されています
- 実際の使用では、本物の商品画像で再訓練が必要です
- モデルサイズは約2-5MB程度になります
- 推論時間はデバイスによって異なります

## 🔄 モデルの更新

モデルを更新する場合は、以下の手順で行ってください：

1. 新しいデータセットで再訓練
2. モデルの精度を評価
3. TensorFlow Lite形式に変換
4. アプリに組み込み

## 📝 ライセンス

このスクリプトはMITライセンスの下で提供されています。
