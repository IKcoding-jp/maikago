#!/usr/bin/env python3
"""
EfficientDet-Lite0 棚札検出モデル学習スクリプト
"""

import tensorflow as tf
import numpy as np
import os
import json
from pathlib import Path
import matplotlib.pyplot as plt
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Input, Conv2D, MaxPooling2D, Flatten
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint

def load_coco_annotations(annotation_path):
    """COCO形式のアノテーションファイルを読み込み"""
    with open(annotation_path, 'r', encoding='utf-8') as f:
        annotations = json.load(f)
    return annotations

def create_efficientdet_lite0_model(num_classes, img_size=(512, 512)):
    """EfficientDet-Lite0ベースの検出モデルを作成"""
    # EfficientNetB0をベースとして使用
    base_model = EfficientNetB0(
        weights='imagenet',
        include_top=False,
        input_shape=(*img_size, 3)
    )
    
    # ベースモデルを凍結
    base_model.trainable = False
    
    # 検出ヘッドを追加
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(1024, activation='relu')(x)
    x = Dropout(0.5)(x)
    x = Dense(512, activation='relu')(x)
    x = Dropout(0.3)(x)
    
    # 各クラスの検出出力
    outputs = []
    for i in range(num_classes):
        class_output = Dense(4, name=f'bbox_{i}')(x)  # x, y, w, h
        confidence_output = Dense(1, activation='sigmoid', name=f'confidence_{i}')(x)
        outputs.extend([class_output, confidence_output])
    
    model = Model(inputs=base_model.input, outputs=outputs)
    return model

def create_data_generator(annotations, img_dir, batch_size=8, img_size=(512, 512)):
    """データジェネレーターを作成"""
    def generator():
        while True:
            # バッチサイズ分のデータを選択
            batch_indices = np.random.choice(len(annotations['images']), batch_size)
            
            batch_images = []
            batch_targets = []
            
            for idx in batch_indices:
                img_info = annotations['images'][idx]
                img_path = Path(img_dir) / img_info['file_name']
                
                if not img_path.exists():
                    continue
                
                # 画像読み込み・前処理
                img = tf.keras.preprocessing.image.load_img(img_path, target_size=img_size)
                img_array = tf.keras.preprocessing.image.img_to_array(img)
                img_array = img_array / 255.0
                
                # アノテーション取得
                img_annotations = [ann for ann in annotations['annotations'] if ann['image_id'] == img_info['id']]
                
                # ターゲット作成
                targets = []
                for class_id in range(len(annotations['categories'])):
                    class_annotations = [ann for ann in img_annotations if ann['category_id'] == class_id]
                    
                    if class_annotations:
                        # 最初のアノテーションを使用
                        bbox = class_annotations[0]['bbox']
                        # 正規化
                        bbox = [bbox[0]/img_size[0], bbox[1]/img_size[1], 
                               bbox[2]/img_size[0], bbox[3]/img_size[1]]
                        confidence = 1.0
                    else:
                        bbox = [0, 0, 0, 0]
                        confidence = 0.0
                    
                    targets.extend(bbox + [confidence])
                
                batch_images.append(img_array)
                batch_targets.append(targets)
            
            if batch_images:
                yield np.array(batch_images), np.array(batch_targets)
    
    return generator

def train_model(model, train_generator, val_generator, epochs=100):
    """モデルを訓練"""
    # コールバック
    callbacks = [
        EarlyStopping(
            monitor='val_loss',
            patience=15,
            restore_best_weights=True
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=8,
            min_lr=1e-7
        ),
        ModelCheckpoint(
            'best_shelf_detector.h5',
            monitor='val_loss',
            save_best_only=True,
            verbose=1
        )
    ]
    
    # モデルコンパイル
    model.compile(
        optimizer=Adam(learning_rate=1e-4),
        loss='mse',
        metrics=['mae']
    )
    
    # 訓練実行
    history = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=epochs,
        callbacks=callbacks,
        verbose=1,
        steps_per_epoch=50,
        validation_steps=10
    )
    
    return history, model

def convert_to_tflite(model, output_path):
    """モデルをTensorFlow Lite形式に変換"""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"✅ TensorFlow Liteモデルを保存しました: {output_path}")

def main():
    dataset_path = Path("shelf_tag_dataset")
    
    # アノテーションファイル読み込み
    train_annotations = load_coco_annotations(dataset_path / "annotations" / "train_annotations.json")
    val_annotations = load_coco_annotations(dataset_path / "annotations" / "val_annotations.json")
    
    num_classes = len(train_annotations['categories'])
    print(f"🎯 検出クラス数: {num_classes}")
    
    # データジェネレーター作成
    train_generator = create_data_generator(
        train_annotations, 
        dataset_path / "train",
        batch_size=8
    )
    val_generator = create_data_generator(
        val_annotations,
        dataset_path / "validation", 
        batch_size=8
    )
    
    # モデル作成
    model = create_efficientdet_lite0_model(num_classes)
    print("✅ モデルを作成しました")
    
    # 訓練実行
    print("🚀 訓練を開始します...")
    history, trained_model = train_model(model, train_generator, val_generator)
    
    # モデル保存
    trained_model.save('shelf_detector_model.h5')
    print("✅ 訓練済みモデルを保存しました")
    
    # TensorFlow Lite変換
    convert_to_tflite(trained_model, 'shelf_detector_model.tflite')
    
    # 訓練履歴プロット
    plt.figure(figsize=(12, 4))
    plt.subplot(1, 2, 1)
    plt.plot(history.history['loss'], label='訓練損失')
    plt.plot(history.history['val_loss'], label='検証損失')
    plt.title('モデル損失')
    plt.xlabel('エポック')
    plt.ylabel('損失')
    plt.legend()
    
    plt.subplot(1, 2, 2)
    plt.plot(history.history['mae'], label='訓練MAE')
    plt.plot(history.history['val_mae'], label='検証MAE')
    plt.title('平均絶対誤差')
    plt.xlabel('エポック')
    plt.ylabel('MAE')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig('training_history.png', dpi=300, bbox_inches='tight')
    plt.show()

if __name__ == "__main__":
    main()
