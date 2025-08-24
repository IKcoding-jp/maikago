#!/usr/bin/env python3
"""
データセット収集スクリプト
実際の商品画像を収集して、訓練用データセットを作成します。
"""

import os
import json
import shutil
from pathlib import Path
import argparse
from datetime import datetime

def create_dataset_structure(base_path="dataset"):
    """
    データセットのディレクトリ構造を作成
    """
    dataset_path = Path(base_path)
    
    # メインディレクトリ
    train_path = dataset_path / "train"
    val_path = dataset_path / "validation"
    test_path = dataset_path / "test"
    
    # ディレクトリ作成
    for path in [train_path, val_path, test_path]:
        path.mkdir(parents=True, exist_ok=True)
    
    print(f"✅ データセット構造を作成しました: {dataset_path}")
    return dataset_path

def create_product_categories():
    """
    商品カテゴリの定義
    """
    categories = {
        "vegetables": {
            "新たまねぎ小箱": {"price": 298, "description": "新玉ねぎ小箱"},
            "トマト": {"price": 198, "description": "トマト"},
            "キャベツ": {"price": 158, "description": "キャベツ"},
            "にんじん": {"price": 98, "description": "にんじん"},
            "じゃがいも": {"price": 128, "description": "じゃがいも"},
            "たまねぎ": {"price": 88, "description": "たまねぎ"},
            "ピーマン": {"price": 78, "description": "ピーマン"},
            "きゅうり": {"price": 68, "description": "きゅうり"},
            "なす": {"price": 98, "description": "なす"},
            "白菜": {"price": 198, "description": "白菜"},
        },
        "mushrooms": {
            "しいたけ": {"price": 128, "description": "しいたけ"},
            "えのきたけ": {"price": 98, "description": "えのきたけ"},
            "しめじ": {"price": 88, "description": "しめじ"},
            "まいたけ": {"price": 108, "description": "まいたけ"},
            "えりんぎ": {"price": 158, "description": "えりんぎ"},
            "まつたけ": {"price": 598, "description": "まつたけ"},
        },
        "fruits": {
            "りんご": {"price": 158, "description": "りんご"},
            "バナナ": {"price": 98, "description": "バナナ"},
            "みかん": {"price": 128, "description": "みかん"},
            "ぶどう": {"price": 298, "description": "ぶどう"},
        }
    }
    
    return categories

def create_dataset_info(categories, dataset_path):
    """
    データセット情報ファイルを作成
    """
    info = {
        "created_at": datetime.now().isoformat(),
        "total_categories": len(categories),
        "total_products": sum(len(products) for products in categories.values()),
        "categories": {},
        "dataset_path": str(dataset_path),
        "image_size": [224, 224, 3],
        "format": "RGB"
    }
    
    # カテゴリ情報を追加
    for category_name, products in categories.items():
        info["categories"][category_name] = {
            "count": len(products),
            "products": list(products.keys())
        }
    
    # 情報ファイルを保存
    info_path = dataset_path / "dataset_info.json"
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(info, f, ensure_ascii=False, indent=2)
    
    print(f"✅ データセット情報を保存しました: {info_path}")
    return info

def create_label_mapping(categories):
    """
    ラベルマッピングファイルを作成
    """
    label_mapping = {}
    label_id = 0
    
    for category_name, products in categories.items():
        for product_name, product_info in products.items():
            label_key = f"{product_name}_{product_info['price']}"
            label_mapping[label_id] = {
                "name": product_name,
                "price": product_info['price'],
                "category": category_name,
                "description": product_info['description'],
                "label_key": label_key
            }
            label_id += 1
    
    return label_mapping

def create_upload_script(dataset_path, categories):
    """
    画像アップロード用のスクリプトを作成
    """
    script_content = f'''#!/usr/bin/env python3
"""
画像アップロードスクリプト
実際の商品画像をデータセットに追加します。
"""

import os
import shutil
from pathlib import Path
import argparse

def upload_images(source_dir, dataset_path, category, product):
    """
    画像をデータセットにアップロード
    """
    source_path = Path(source_dir)
    target_path = Path(dataset_path) / "train" / category / product
    
    if not source_path.exists():
        print(f"❌ ソースディレクトリが見つかりません: {{source_path}}")
        return
    
    # ターゲットディレクトリ作成
    target_path.mkdir(parents=True, exist_ok=True)
    
    # 画像ファイルをコピー
    image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
    copied_count = 0
    
    for ext in image_extensions:
        for image_file in source_path.glob(f"*{{ext}}"):
            if image_file.is_file():
                target_file = target_path / f"{{copied_count:03d}}{{ext}}"
                shutil.copy2(image_file, target_file)
                copied_count += 1
                print(f"📸 {{image_file.name}} → {{target_file.name}}")
    
    print(f"✅ {{copied_count}}個の画像をアップロードしました: {{target_path}}")

def main():
    parser = argparse.ArgumentParser(description="商品画像をデータセットにアップロード")
    parser.add_argument("source_dir", help="画像が格納されているディレクトリ")
    parser.add_argument("category", help="商品カテゴリ (vegetables, mushrooms, fruits)")
    parser.add_argument("product", help="商品名")
    parser.add_argument("--dataset-path", default="{dataset_path}", help="データセットパス")
    
    args = parser.parse_args()
    
    # 利用可能なカテゴリと商品を表示
    categories = {categories}
    
    if args.category not in categories:
        print(f"❌ 無効なカテゴリ: {{args.category}}")
        print(f"利用可能なカテゴリ: {{list(categories.keys())}}")
        return
    
    if args.product not in categories[args.category]:
        print(f"❌ 無効な商品: {{args.product}}")
        print(f"利用可能な商品: {{list(categories[args.category].keys())}}")
        return
    
    upload_images(args.source_dir, args.dataset_path, args.category, args.product)

if __name__ == "__main__":
    main()
'''
    
    script_path = dataset_path / "upload_images.py"
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    # 実行権限を付与（Unix系システム）
    os.chmod(script_path, 0o755)
    
    print(f"✅ アップロードスクリプトを作成しました: {script_path}")
    return script_path

def create_training_script(dataset_path, label_mapping):
    """
    訓練用スクリプトを作成
    """
    script_content = f'''#!/usr/bin/env python3
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
    dataset_path = "{dataset_path}"
    
    # データセット情報読み込み
    dataset_info = load_dataset_info(dataset_path)
    print(f"📊 データセット情報: {{dataset_info}}")
    
    # データジェネレーター作成
    train_generator, val_generator = create_data_generators(dataset_path)
    num_classes = len(train_generator.class_indices)
    
    print(f"🎯 分類クラス数: {{num_classes}}")
    print(f"📸 訓練サンプル数: {{train_generator.samples}}")
    print(f"🔍 検証サンプル数: {{val_generator.samples}}")
    
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
    print(f"📊 最終検証精度: {{val_accuracy:.4f}}")
    print(f"📊 最終検証損失: {{val_loss:.4f}}")
    
    # モデル保存
    trained_model.save('trained_model.h5')
    print("✅ 訓練済みモデルを保存しました: trained_model.h5")

if __name__ == "__main__":
    main()
'''
    
    script_path = dataset_path / "train_model.py"
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    os.chmod(script_path, 0o755)
    
    print(f"✅ 訓練スクリプトを作成しました: {script_path}")
    return script_path

def create_readme(dataset_path, categories, label_mapping):
    """
    READMEファイルを作成
    """
    readme_content = f'''# まいカゴ 商品認識データセット

## 📊 データセット概要

- **作成日**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **総商品数**: {len(label_mapping)}
- **カテゴリ数**: {len(categories)}
- **画像サイズ**: 224x224 RGB

## 🗂️ ディレクトリ構造

```
{dataset_path}/
├── train/           # 訓練データ
├── validation/      # 検証データ
├── test/           # テストデータ
├── dataset_info.json
├── upload_images.py
├── train_model.py
└── README.md
```

## 📦 商品カテゴリ

### 野菜類 (vegetables)
{chr(10).join([f"- {product}: ¥{info['price']} - {info['description']}" for product, info in categories['vegetables'].items()])}

### きのこ類 (mushrooms)
{chr(10).join([f"- {product}: ¥{info['price']} - {info['description']}" for product, info in categories['mushrooms'].items()])}

### 果物類 (fruits)
{chr(10).join([f"- {product}: ¥{info['price']} - {info['description']}" for product, info in categories['fruits'].items()])}

## 🚀 使用方法

### 1. 画像のアップロード

```bash
python upload_images.py <画像ディレクトリ> <カテゴリ> <商品名>
```

例:
```bash
python upload_images.py ./images/onion vegetables 新たまねぎ小箱
```

### 2. モデルの訓練

```bash
python train_model.py
```

### 3. データセット情報の確認

```bash
python -c "import json; print(json.dumps(json.load(open('dataset_info.json')), indent=2, ensure_ascii=False))"
```

## 📋 画像収集ガイドライン

### 撮影条件
- **照明**: 自然光または明るい室内照明
- **角度**: 商品が正面から見える角度
- **背景**: シンプルな背景（白または薄い色）
- **距離**: 商品が画面の70%以上を占める

### 必要な画像数
- **訓練データ**: 各商品につき50-100枚
- **検証データ**: 各商品につき10-20枚
- **テストデータ**: 各商品につき5-10枚

### 画像形式
- **形式**: JPG, PNG, BMP
- **解像度**: 最低224x224ピクセル
- **ファイル名**: 連番（001.jpg, 002.jpg, ...）

## 🔧 カスタマイズ

### 新しい商品の追加

1. `categories`辞書に新しい商品を追加
2. 対応するディレクトリを作成
3. 画像をアップロード
4. モデルを再訓練

### データ拡張の調整

`train_model.py`の`ImageDataGenerator`パラメータを調整:

```python
train_datagen = ImageDataGenerator(
    rotation_range=20,      # 回転角度
    width_shift_range=0.2,  # 水平シフト
    height_shift_range=0.2, # 垂直シフト
    zoom_range=0.2,         # ズーム範囲
    horizontal_flip=True,   # 水平反転
)
```

## 📈 パフォーマンス目標

- **訓練精度**: 95%以上
- **検証精度**: 90%以上
- **推論時間**: 1秒以内
- **モデルサイズ**: 10MB以下

## 🚨 注意事項

- 画像の著作権に注意してください
- 個人情報が含まれていないことを確認してください
- 定期的にデータセットをバックアップしてください
- 訓練前に十分なデータがあることを確認してください
'''
    
    readme_path = dataset_path / "README.md"
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    print(f"✅ READMEファイルを作成しました: {readme_path}")

def main():
    parser = argparse.ArgumentParser(description="データセット収集システムをセットアップ")
    parser.add_argument("--output", default="dataset", help="出力ディレクトリ")
    
    args = parser.parse_args()
    
    print("🚀 データセット収集システムをセットアップ中...")
    
    # データセット構造作成
    dataset_path = create_dataset_structure(args.output)
    
    # 商品カテゴリ定義
    categories = create_product_categories()
    
    # データセット情報作成
    dataset_info = create_dataset_info(categories, dataset_path)
    
    # ラベルマッピング作成
    label_mapping = create_label_mapping(categories)
    
    # アップロードスクリプト作成
    upload_script = create_upload_script(dataset_path, categories)
    
    # 訓練スクリプト作成
    training_script = create_training_script(dataset_path, label_mapping)
    
    # README作成
    create_readme(dataset_path, categories, label_mapping)
    
    print("\n🎉 データセット収集システムのセットアップが完了しました！")
    print(f"\n📁 データセットディレクトリ: {dataset_path}")
    print(f"📝 使用方法: {dataset_path}/README.md を参照してください")
    print(f"📸 画像アップロード: python {upload_script} <画像ディレクトリ> <カテゴリ> <商品名>")
    print(f"🎯 モデル訓練: python {training_script}")

if __name__ == "__main__":
    main()
