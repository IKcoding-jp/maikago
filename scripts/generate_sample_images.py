#!/usr/bin/env python3
"""
サンプル画像生成スクリプト
テスト用のダミー画像を生成して、データセット構造を確認します。
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFont
import os
from pathlib import Path
import json
import random

def create_sample_image(product_name, price, size=(224, 224)):
    """
    商品名と価格を含むサンプル画像を作成
    """
    # 背景色をランダムに選択
    bg_colors = [
        (255, 255, 255),  # 白
        (240, 248, 255),  # アリスブルー
        (255, 250, 240),  # フローラルホワイト
        (245, 245, 245),  # ホワイトスモーク
        (248, 248, 255),  # ゴーストホワイト
    ]
    bg_color = random.choice(bg_colors)
    
    # 画像作成
    img = Image.new('RGB', size, bg_color)
    draw = ImageDraw.Draw(img)
    
    # フォントサイズを調整
    try:
        # 日本語フォントを試行
        font_large = ImageFont.truetype("arial.ttf", 24)
        font_small = ImageFont.truetype("arial.ttf", 18)
    except:
        # フォールバック
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # 商品名を描画
    text_color = (50, 50, 50)
    text_bbox = draw.textbbox((0, 0), product_name, font=font_large)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    
    x = (size[0] - text_width) // 2
    y = size[1] // 3
    draw.text((x, y), product_name, fill=text_color, font=font_large)
    
    # 価格を描画
    price_text = f"¥{price}"
    price_bbox = draw.textbbox((0, 0), price_text, font=font_small)
    price_width = price_bbox[2] - price_bbox[0]
    
    price_x = (size[0] - price_width) // 2
    price_y = y + text_height + 20
    draw.text((price_x, price_y), price_text, fill=(255, 0, 0), font=font_small)
    
    # 装飾的な枠を追加
    border_color = (200, 200, 200)
    draw.rectangle([10, 10, size[0]-10, size[1]-10], outline=border_color, width=2)
    
    return img

def generate_sample_dataset(dataset_path, num_samples_per_product=5):
    """
    サンプルデータセットを生成
    """
    dataset_path = Path(dataset_path)
    
    # データセット情報を読み込み
    info_path = dataset_path / "dataset_info.json"
    with open(info_path, 'r', encoding='utf-8') as f:
        dataset_info = json.load(f)
    
    categories = dataset_info['categories']
    
    print(f"🎨 サンプル画像を生成中...")
    print(f"📊 商品数: {dataset_info['total_products']}")
    print(f"📸 商品あたりのサンプル数: {num_samples_per_product}")
    
    total_generated = 0
    
    # 各カテゴリと商品に対して画像を生成
    for category_name, category_info in categories.items():
        print(f"\n📦 カテゴリ: {category_name}")
        
        for product_name in category_info['products']:
            # 価格を取得（簡易的な方法）
            price = random.randint(50, 500)
            
            print(f"  🥬 {product_name}: ¥{price}")
            
            # 訓練データディレクトリ
            train_dir = dataset_path / "train" / category_name / product_name
            train_dir.mkdir(parents=True, exist_ok=True)
            
            # 検証データディレクトリ
            val_dir = dataset_path / "validation" / category_name / product_name
            val_dir.mkdir(parents=True, exist_ok=True)
            
            # テストデータディレクトリ
            test_dir = dataset_path / "test" / category_name / product_name
            test_dir.mkdir(parents=True, exist_ok=True)
            
            # サンプル画像を生成
            for i in range(num_samples_per_product):
                # 画像を生成
                img = create_sample_image(product_name, price)
                
                # ファイル名を決定
                filename = f"{i:03d}.jpg"
                
                # データ分割（70% 訓練, 20% 検証, 10% テスト）
                if i < int(num_samples_per_product * 0.7):
                    save_path = train_dir / filename
                elif i < int(num_samples_per_product * 0.9):
                    save_path = val_dir / filename
                else:
                    save_path = test_dir / filename
                
                # 画像を保存
                img.save(save_path, 'JPEG', quality=95)
                total_generated += 1
    
    print(f"\n✅ サンプル画像生成完了！")
    print(f"📸 総生成数: {total_generated}枚")
    
    # 統計情報を表示
    print(f"\n📊 データセット統計:")
    for split in ['train', 'validation', 'test']:
        split_path = dataset_path / split
        total_files = sum(len(list((split_path / category / product).glob('*.jpg'))) 
                         for category in categories.keys() 
                         for product in categories[category]['products'])
        print(f"  {split}: {total_files}枚")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="サンプル画像を生成")
    parser.add_argument("--dataset-path", default="../dataset", help="データセットパス")
    parser.add_argument("--samples", type=int, default=5, help="商品あたりのサンプル数")
    
    args = parser.parse_args()
    
    if not Path(args.dataset_path).exists():
        print(f"❌ データセットディレクトリが見つかりません: {args.dataset_path}")
        print("先に collect_dataset.py を実行してください")
        return
    
    generate_sample_dataset(args.dataset_path, args.samples)

if __name__ == "__main__":
    main()
