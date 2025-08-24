#!/usr/bin/env python3
"""
TensorFlow Lite Model Creator for Product Recognition
This script creates a simple CNN model for product recognition and converts it to TensorFlow Lite format.
"""

import tensorflow as tf
import numpy as np
import os
import json

def create_product_recognition_model(num_classes=20):
    """
    商品認識用のCNNモデルを作成
    
    Args:
        num_classes: 分類する商品クラス数
    
    Returns:
        tf.keras.Model: 訓練可能なモデル
    """
    
    model = tf.keras.Sequential([
        # 入力層: 224x224x3 RGB画像
        tf.keras.layers.Input(shape=(224, 224, 3)),
        
        # 畳み込み層1
        tf.keras.layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.MaxPooling2D((2, 2)),
        
        # 畳み込み層2
        tf.keras.layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.MaxPooling2D((2, 2)),
        
        # 畳み込み層3
        tf.keras.layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.MaxPooling2D((2, 2)),
        
        # 畳み込み層4
        tf.keras.layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.MaxPooling2D((2, 2)),
        
        # 全結合層
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(num_classes, activation='softmax')
    ])
    
    return model

def create_sample_data(num_classes=20, samples_per_class=100):
    """
    サンプルデータを生成（実際の使用では、本物の商品画像を使用）
    
    Args:
        num_classes: クラス数
        samples_per_class: クラスごとのサンプル数
    
    Returns:
        tuple: (X_train, y_train, X_test, y_test)
    """
    
    # ダミーデータを生成（実際の使用では本物の画像を使用）
    total_samples = num_classes * samples_per_class
    X_train = np.random.rand(total_samples, 224, 224, 3).astype(np.float32)
    y_train = np.random.randint(0, num_classes, total_samples)
    
    # テストデータ
    test_samples = num_classes * 20
    X_test = np.random.rand(test_samples, 224, 224, 3).astype(np.float32)
    y_test = np.random.randint(0, num_classes, test_samples)
    
    # One-hot encoding
    y_train = tf.keras.utils.to_categorical(y_train, num_classes)
    y_test = tf.keras.utils.to_categorical(y_test, num_classes)
    
    return X_train, y_train, X_test, y_test

def train_model(model, X_train, y_train, X_test, y_test, epochs=10):
    """
    モデルを訓練
    
    Args:
        model: 訓練するモデル
        X_train, y_train: 訓練データ
        X_test, y_test: テストデータ
        epochs: 訓練エポック数
    
    Returns:
        tf.keras.Model: 訓練済みモデル
    """
    
    # モデルのコンパイル
    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # 早期停止
    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=3,
        restore_best_weights=True
    )
    
    # モデルの訓練
    history = model.fit(
        X_train, y_train,
        validation_data=(X_test, y_test),
        epochs=epochs,
        batch_size=32,
        callbacks=[early_stopping],
        verbose=1
    )
    
    return model

def convert_to_tflite(model, output_path):
    """
    モデルをTensorFlow Lite形式に変換
    
    Args:
        model: 変換するモデル
        output_path: 出力ファイルパス
    """
    
    # TensorFlow Liteコンバーター
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # 最適化オプション
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # 量子化（オプション）
    # converter.representative_dataset = representative_dataset_gen
    
    # 変換実行
    tflite_model = converter.convert()
    
    # ファイルに保存
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"✅ TensorFlow Liteモデルを保存しました: {output_path}")

def create_labels_file(labels, output_path):
    """
    ラベルファイルを作成
    
    Args:
        labels: ラベルのリスト
        output_path: 出力ファイルパス
    """
    
    with open(output_path, 'w', encoding='utf-8') as f:
        for label in labels:
            f.write(f"{label}\n")
    
    print(f"✅ ラベルファイルを保存しました: {output_path}")

def main():
    """メイン関数"""
    
    print("🚀 TensorFlow Liteモデル作成開始")
    
    # 設定
    num_classes = 20
    model_output_path = "../assets/models/product_ocr_model.tflite"
    labels_output_path = "../assets/models/product_labels.txt"
    
    # 出力ディレクトリの作成
    os.makedirs(os.path.dirname(model_output_path), exist_ok=True)
    
    # サンプルラベル（実際の使用では本物の商品名を使用）
    sample_labels = [
        "新たまねぎ小箱_298",
        "トマト_198",
        "キャベツ_158",
        "にんじん_98",
        "じゃがいも_128",
        "たまねぎ_88",
        "ピーマン_78",
        "きゅうり_68",
        "なす_98",
        "白菜_198",
        "ブロッコリー_158",
        "アスパラガス_298",
        "しいたけ_128",
        "えのきたけ_98",
        "しめじ_88",
        "まいたけ_108",
        "えりんぎ_158",
        "まつたけ_598",
        "しめじ_88",
        "えのきたけ_98"
    ]
    
    # モデルの作成
    print("📦 モデルを作成中...")
    model = create_product_recognition_model(num_classes)
    
    # サンプルデータの生成
    print("📊 サンプルデータを生成中...")
    X_train, y_train, X_test, y_test = create_sample_data(num_classes)
    
    # モデルの訓練
    print("🎯 モデルを訓練中...")
    trained_model = train_model(model, X_train, y_train, X_test, y_test, epochs=5)
    
    # TensorFlow Lite形式に変換
    print("🔄 TensorFlow Lite形式に変換中...")
    convert_to_tflite(trained_model, model_output_path)
    
    # ラベルファイルの作成
    print("🏷️ ラベルファイルを作成中...")
    create_labels_file(sample_labels, labels_output_path)
    
    # モデル情報の保存
    model_info = {
        "input_shape": [1, 224, 224, 3],
        "output_shape": [1, num_classes],
        "num_classes": num_classes,
        "labels": sample_labels
    }
    
    info_path = "../assets/models/model_info.json"
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(model_info, f, ensure_ascii=False, indent=2)
    
    print(f"✅ モデル情報を保存しました: {info_path}")
    print("🎉 TensorFlow Liteモデル作成完了！")

if __name__ == "__main__":
    main()
