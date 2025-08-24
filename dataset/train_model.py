#!/usr/bin/env python3
"""
実際のデータセットでモデルを訓練するスクリプト
"""

import tensorflow as tf
import numpy as np
import os
import json
from pathlib import Path
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
import matplotlib.pyplot as plt

def load_dataset_info(dataset_path):
    """
    データセット情報を読み込み
    """
    info_path = Path(dataset_path) / "dataset_info.json"
    with open(info_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def create_data_generators(dataset_path, img_size=(224, 224), batch_size=32):
    """
    データジェネレーターを作成
    """
    # データ拡張（訓練用）
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest'
    )
    
    # 検証用（拡張なし）
    val_datagen = ImageDataGenerator(rescale=1./255)
    
    # ジェネレーター作成
    train_generator = train_datagen.flow_from_directory(
        Path(dataset_path) / "train",
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical'
    )
    
    val_generator = val_datagen.flow_from_directory(
        Path(dataset_path) / "validation",
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical'
    )
    
    return train_generator, val_generator

def create_model(num_classes, img_size=(224, 224)):
    """
    転移学習を使用したモデルを作成
    """
    # MobileNetV2をベースモデルとして使用
    base_model = MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(*img_size, 3)
    )
    
    # ベースモデルを凍結
    base_model.trainable = False
    
    # 新しい分類層を追加
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(1024, activation='relu')(x)
    x = Dropout(0.5)(x)
    x = Dense(512, activation='relu')(x)
    x = Dropout(0.3)(x)
    predictions = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=base_model.input, outputs=predictions)
    
    return model

def train_model(model, train_generator, val_generator, epochs=50):
    """
    モデルを訓練
    """
    # コールバック
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-7
        ),
        tf.keras.callbacks.ModelCheckpoint(
            'best_model.h5',
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]
    
    # モデルコンパイル
    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # 訓練実行
    history = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=epochs,
        callbacks=callbacks,
        verbose=1
    )
    
    return history, model

def plot_training_history(history):
    """
    訓練履歴をプロット
    """
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))
    
    # 精度
    ax1.plot(history.history['accuracy'], label='訓練精度')
    ax1.plot(history.history['val_accuracy'], label='検証精度')
    ax1.set_title('モデル精度')
    ax1.set_xlabel('エポック')
    ax1.set_ylabel('精度')
    ax1.legend()
    
    # 損失
    ax2.plot(history.history['loss'], label='訓練損失')
    ax2.plot(history.history['val_loss'], label='検証損失')
    ax2.set_title('モデル損失')
    ax2.set_xlabel('エポック')
    ax2.set_ylabel('損失')
    ax2.legend()
    
    plt.tight_layout()
    plt.savefig('training_history.png', dpi=300, bbox_inches='tight')
    plt.show()

def main():
    dataset_path = "..\dataset"
    
    # データセット情報読み込み
    dataset_info = load_dataset_info(dataset_path)
    print(f"📊 データセット情報: {dataset_info}")
    
    # データジェネレーター作成
    train_generator, val_generator = create_data_generators(dataset_path)
    num_classes = len(train_generator.class_indices)
    
    print(f"🎯 分類クラス数: {num_classes}")
    print(f"📸 訓練サンプル数: {train_generator.samples}")
    print(f"🔍 検証サンプル数: {val_generator.samples}")
    
    # モデル作成
    model = create_model(num_classes)
    print("✅ モデルを作成しました")
    
    # 訓練実行
    print("🚀 訓練を開始します...")
    history, trained_model = train_model(model, train_generator, val_generator)
    
    # 訓練履歴をプロット
    plot_training_history(history)
    
    # 最終評価
    val_loss, val_accuracy = trained_model.evaluate(val_generator)
    print(f"📊 最終検証精度: {val_accuracy:.4f}")
    print(f"📊 最終検証損失: {val_loss:.4f}")
    
    # モデル保存
    trained_model.save('trained_model.h5')
    print("✅ 訓練済みモデルを保存しました: trained_model.h5")

if __name__ == "__main__":
    main()
