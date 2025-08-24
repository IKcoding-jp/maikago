#!/usr/bin/env python3
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
        print(f"❌ ソースディレクトリが見つかりません: {source_path}")
        return
    
    # ターゲットディレクトリ作成
    target_path.mkdir(parents=True, exist_ok=True)
    
    # 画像ファイルをコピー
    image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
    copied_count = 0
    
    for ext in image_extensions:
        for image_file in source_path.glob(f"*{ext}"):
            if image_file.is_file():
                target_file = target_path / f"{copied_count:03d}{ext}"
                shutil.copy2(image_file, target_file)
                copied_count += 1
                print(f"📸 {image_file.name} → {target_file.name}")
    
    print(f"✅ {copied_count}個の画像をアップロードしました: {target_path}")

def main():
    parser = argparse.ArgumentParser(description="商品画像をデータセットにアップロード")
    parser.add_argument("source_dir", help="画像が格納されているディレクトリ")
    parser.add_argument("category", help="商品カテゴリ (vegetables, mushrooms, fruits)")
    parser.add_argument("product", help="商品名")
    parser.add_argument("--dataset-path", default="..\dataset", help="データセットパス")
    
    args = parser.parse_args()
    
    # 利用可能なカテゴリと商品を表示
    categories = {'vegetables': {'新たまねぎ小箱': {'price': 298, 'description': '新玉ねぎ小箱'}, 'トマト': {'price': 198, 'description': 'トマト'}, 'キャベツ': {'price': 158, 'description': 'キャベツ'}, 'にんじん': {'price': 98, 'description': 'にんじん'}, 'じゃがいも': {'price': 128, 'description': 'じゃがいも'}, 'たまねぎ': {'price': 88, 'description': 'たまねぎ'}, 'ピーマン': {'price': 78, 'description': 'ピーマン'}, 'きゅうり': {'price': 68, 'description': 'きゅうり'}, 'なす': {'price': 98, 'description': 'なす'}, '白菜': {'price': 198, 'description': '白菜'}}, 'mushrooms': {'しいたけ': {'price': 128, 'description': 'しいたけ'}, 'えのきたけ': {'price': 98, 'description': 'えのきたけ'}, 'しめじ': {'price': 88, 'description': 'しめじ'}, 'まいたけ': {'price': 108, 'description': 'まいたけ'}, 'えりんぎ': {'price': 158, 'description': 'えりんぎ'}, 'まつたけ': {'price': 598, 'description': 'まつたけ'}}, 'fruits': {'りんご': {'price': 158, 'description': 'りんご'}, 'バナナ': {'price': 98, 'description': 'バナナ'}, 'みかん': {'price': 128, 'description': 'みかん'}, 'ぶどう': {'price': 298, 'description': 'ぶどう'}}}
    
    if args.category not in categories:
        print(f"❌ 無効なカテゴリ: {args.category}")
        print(f"利用可能なカテゴリ: {list(categories.keys())}")
        return
    
    if args.product not in categories[args.category]:
        print(f"❌ 無効な商品: {args.product}")
        print(f"利用可能な商品: {list(categories[args.category].keys())}")
        return
    
    upload_images(args.source_dir, args.dataset_path, args.category, args.product)

if __name__ == "__main__":
    main()
