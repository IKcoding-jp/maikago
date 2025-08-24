#!/usr/bin/env python3
"""
TensorFlow Lite変換スクリプト
訓練済みのKerasモデルをTensorFlow Lite形式に変換します。
"""

import tensorflow as tf
import numpy as np
import os
import json
from pathlib import Path
import argparse

def load_trained_model(model_path):
    """
    訓練済みモデルを読み込み
    """
    print(f"📦 モデルを読み込み中: {model_path}")
    model = tf.keras.models.load_model(model_path)
    print(f"✅ モデル読み込み完了")
    print(f"📊 モデル概要:")
    model.summary()
    return model

def convert_to_tflite(model, output_path, optimize=True):
    """
    モデルをTensorFlow Lite形式に変換
    """
    print(f"🔄 TensorFlow Lite形式に変換中...")
    
    # コンバーター作成
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    if optimize:
        # 最適化オプション
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        print("⚡ 最適化を有効にしました")
    
    # 変換実行
    tflite_model = converter.convert()
    
    # ファイルに保存
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    # ファイルサイズを確認
    file_size = os.path.getsize(output_path)
    file_size_mb = file_size / (1024 * 1024)
    
    print(f"✅ TensorFlow Liteモデルを保存しました: {output_path}")
    print(f"📏 ファイルサイズ: {file_size_mb:.2f} MB")
    
    return output_path

def create_labels_file(label_mapping, output_path):
    """
    ラベルファイルを作成
    """
    print(f"🏷️ ラベルファイルを作成中...")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        for label_id, label_info in label_mapping.items():
            label_key = label_info['label_key']
            f.write(f"{label_key}\n")
    
    print(f"✅ ラベルファイルを保存しました: {output_path}")
    return output_path

def create_model_info(model, label_mapping, output_path):
    """
    モデル情報ファイルを作成
    """
    print(f"📋 モデル情報ファイルを作成中...")
    
    # モデルの入力・出力情報を取得
    input_shape = model.input_shape
    output_shape = model.output_shape
    
    model_info = {
        "input_shape": list(input_shape),
        "output_shape": list(output_shape),
        "num_classes": len(label_mapping),
        "labels": [label_info['label_key'] for label_info in label_mapping.values()],
        "model_type": "product_recognition",
        "version": "1.0.0",
        "description": "まいカゴ商品認識モデル"
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(model_info, f, ensure_ascii=False, indent=2)
    
    print(f"✅ モデル情報ファイルを保存しました: {output_path}")
    return output_path

def test_tflite_model(tflite_path, test_image_path=None):
    """
    TensorFlow Liteモデルのテスト
    """
    print(f"🧪 TensorFlow Liteモデルをテスト中...")
    
    # インタープリターを作成
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    # 入力・出力の詳細を取得
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"📥 入力詳細: {input_details}")
    print(f"📤 出力詳細: {output_details}")
    
    # テスト用のダミー入力を作成
    input_shape = input_details[0]['shape']
    test_input = np.random.random(input_shape).astype(np.float32)
    
    # 推論実行
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    
    # 結果を取得
    output_data = interpreter.get_tensor(output_details[0]['index'])
    
    print(f"✅ テスト推論完了")
    print(f"📊 出力形状: {output_data.shape}")
    print(f"📊 出力サンプル: {output_data[0][:5]}")  # 最初の5つの値を表示
    
    return True

def main():
    parser = argparse.ArgumentParser(description="KerasモデルをTensorFlow Lite形式に変換")
    parser.add_argument("--model-path", default="best_model.h5", help="訓練済みモデルパス")
    parser.add_argument("--output-dir", default="../assets/models", help="出力ディレクトリ")
    parser.add_argument("--dataset-info", default="../dataset/dataset_info.json", help="データセット情報ファイル")
    parser.add_argument("--no-optimize", action="store_true", help="最適化を無効にする")
    
    args = parser.parse_args()
    
    # 出力ディレクトリ作成
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # データセット情報読み込み
    if Path(args.dataset_info).exists():
        with open(args.dataset_info, 'r', encoding='utf-8') as f:
            dataset_info = json.load(f)
        
        # ラベルマッピング作成
        label_mapping = {}
        label_id = 0
        
        for category_name, category_info in dataset_info['categories'].items():
            for product_name in category_info['products']:
                # 価格は簡易的に設定（実際の使用では正確な価格を使用）
                price = 100 + label_id * 50
                label_key = f"{product_name}_{price}"
                label_mapping[label_id] = {
                    "name": product_name,
                    "price": price,
                    "category": category_name,
                    "label_key": label_key
                }
                label_id += 1
    else:
        print(f"⚠️ データセット情報ファイルが見つかりません: {args.dataset_info}")
        print("デフォルトのラベルマッピングを使用します")
        label_mapping = {i: {"label_key": f"product_{i}_100"} for i in range(20)}
    
    # モデル読み込み
    if not Path(args.model_path).exists():
        print(f"❌ モデルファイルが見つかりません: {args.model_path}")
        return
    
    model = load_trained_model(args.model_path)
    
    # TensorFlow Lite形式に変換
    tflite_path = output_dir / "product_ocr_model.tflite"
    convert_to_tflite(model, tflite_path, optimize=not args.no_optimize)
    
    # ラベルファイル作成
    labels_path = output_dir / "product_labels.txt"
    create_labels_file(label_mapping, labels_path)
    
    # モデル情報ファイル作成
    info_path = output_dir / "model_info.json"
    create_model_info(model, label_mapping, info_path)
    
    # テスト実行
    test_tflite_model(tflite_path)
    
    print(f"\n🎉 変換完了！")
    print(f"📁 出力ディレクトリ: {output_dir}")
    print(f"📦 TensorFlow Liteモデル: {tflite_path}")
    print(f"🏷️ ラベルファイル: {labels_path}")
    print(f"📋 モデル情報: {info_path}")

if __name__ == "__main__":
    main()
