#!/usr/bin/env python3
"""
棚札検出用TensorFlow Liteモデル作成スクリプト
EfficientDet-Lite0ベースのオブジェクト検出モデルを作成
"""

import os
import sys
import json
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
import matplotlib.pyplot as plt

def create_shelf_detector_model():
    """棚札検出用のCNNモデルを作成"""
    print("🔧 棚札検出モデルを作成中...")
    
    # EfficientNetB0をベースに使用（軽量で高精度）
    base_model = EfficientNetB0(
        weights='imagenet',
        include_top=False,
        input_shape=(224, 224, 3)
    )
    
    # 転移学習のため、ベースモデルを凍結
    base_model.trainable = False
    
    # カスタムヘッドを追加
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(1024, activation='relu')(x)
    x = Dropout(0.5)(x)
    x = Dense(512, activation='relu')(x)
    x = Dropout(0.3)(x)
    
    # 出力層（棚札要素の分類）
    # NAME, PRICE_BASE, PRICE_TAX, NOTE, UNIT, SYMBOL
    num_classes = 6
    output = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=base_model.input, outputs=output)
    
    # モデルをコンパイル
    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    print("✅ 棚札検出モデル作成完了")
    return model

def create_sample_dataset():
    """サンプルデータセットを作成（実際の使用では本物のデータを使用）"""
    print("📊 サンプルデータセットを作成中...")
    
    # サンプル画像生成（実際の使用では本物の棚札画像を使用）
    num_samples = 1000
    img_size = 224
    
    # ランダムな画像データを生成
    X_train = np.random.rand(num_samples, img_size, img_size, 3)
    X_val = np.random.rand(num_samples // 4, img_size, img_size, 3)
    X_test = np.random.rand(num_samples // 4, img_size, img_size, 3)
    
    # ランダムなラベルを生成
    y_train = np.random.randint(0, 6, (num_samples,))
    y_val = np.random.randint(0, 6, (num_samples // 4,))
    y_test = np.random.randint(0, 6, (num_samples // 4,))
    
    # ワンホットエンコーディング
    y_train = tf.keras.utils.to_categorical(y_train, 6)
    y_val = tf.keras.utils.to_categorical(y_val, 6)
    y_test = tf.keras.utils.to_categorical(y_test, 6)
    
    print(f"✅ データセット作成完了: 訓練={len(X_train)}, 検証={len(X_val)}, テスト={len(X_test)}")
    return X_train, y_train, X_val, y_val, X_test, y_test

def train_model(model, X_train, y_train, X_val, y_val):
    """モデルを訓練"""
    print("🎯 モデル訓練開始...")
    
    # データ拡張
    data_augmentation = keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.1),
        layers.RandomZoom(0.1),
        layers.RandomContrast(0.1),
    ])
    
    # コールバック
    callbacks = [
        keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
        keras.callbacks.ReduceLROnPlateau(factor=0.5, patience=3),
    ]
    
    # 訓練
    history = model.fit(
        data_augmentation(X_train),
        y_train,
        validation_data=(X_val, y_val),
        epochs=20,
        batch_size=32,
        callbacks=callbacks,
        verbose=1
    )
    
    print("✅ モデル訓練完了")
    return history

def convert_to_tflite(model, output_path):
    """モデルをTensorFlow Lite形式に変換"""
    print("🔄 TensorFlow Lite形式に変換中...")
    
    # コンバーターを作成
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # 最適化オプションを設定
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    # 変換
    tflite_model = converter.convert()
    
    # 保存
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"✅ TensorFlow Liteモデル保存完了: {output_path}")

def create_labels_file(output_path):
    """ラベルファイルを作成"""
    print("🏷️ ラベルファイルを作成中...")
    
    labels = [
        "NAME",
        "PRICE_BASE", 
        "PRICE_TAX",
        "NOTE",
        "UNIT",
        "SYMBOL"
    ]
    
    with open(output_path, 'w', encoding='utf-8') as f:
        for label in labels:
            f.write(f"{label}\n")
    
    print(f"✅ ラベルファイル保存完了: {output_path}")

def create_model_info(output_path):
    """モデル情報ファイルを作成"""
    print("📋 モデル情報ファイルを作成中...")
    
    model_info = {
        "name": "Shelf Tag Detector",
        "version": "1.0.0",
        "description": "棚札要素検出モデル（EfficientNetB0ベース）",
        "input_shape": [224, 224, 3],
        "num_classes": 6,
        "classes": ["NAME", "PRICE_BASE", "PRICE_TAX", "NOTE", "UNIT", "SYMBOL"],
        "model_type": "classification",
        "framework": "tensorflow",
        "created_date": "2024-01-01"
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(model_info, f, indent=2, ensure_ascii=False)
    
    print(f"✅ モデル情報ファイル保存完了: {output_path}")

def main():
    """メイン処理"""
    print("🚀 棚札検出TensorFlow Liteモデル作成開始")
    
    # 出力ディレクトリを作成
    output_dir = "../assets/models"
    os.makedirs(output_dir, exist_ok=True)
    
    # モデル作成
    model = create_shelf_detector_model()
    
    # データセット作成
    X_train, y_train, X_val, y_val, X_test, y_test = create_sample_dataset()
    
    # モデル訓練
    history = train_model(model, X_train, y_train, X_val, y_val)
    
    # TensorFlow Lite形式に変換
    tflite_path = os.path.join(output_dir, "shelf_detector_model.tflite")
    convert_to_tflite(model, tflite_path)
    
    # ラベルファイル作成
    labels_path = os.path.join(output_dir, "shelf_detector_labels.txt")
    create_labels_file(labels_path)
    
    # モデル情報ファイル作成
    info_path = os.path.join(output_dir, "shelf_detector_info.json")
    create_model_info(info_path)
    
    # モデル概要を表示
    print("\n📊 モデル概要:")
    model.summary()
    
    print(f"\n📁 出力ファイル:")
    print(f"  - モデル: {tflite_path}")
    print(f"  - ラベル: {labels_path}")
    print(f"  - 情報: {info_path}")
    
    print("\n🎉 棚札検出TensorFlow Liteモデル作成完了！")

if __name__ == "__main__":
    main()
