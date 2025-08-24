#!/usr/bin/env python3
"""
棚札レイアウト検出システム セットアップスクリプト
"""

import os
import json
from pathlib import Path
from datetime import datetime

def create_detection_classes():
    """検出クラスの定義"""
    return {
        "NAME": {"id": 0, "description": "商品名・売り名"},
        "PRICE_BASE": {"id": 1, "description": "本体価格（税抜）"},
        "PRICE_TAX": {"id": 2, "description": "税込価格"},
        "NOTE": {"id": 3, "description": "販促文・注意書き・スローガン"},
        "UNIT": {"id": 4, "description": "単位・数量表記"},
        "SYMBOL": {"id": 5, "description": "記号・表記"}
    }

def create_dataset_structure(base_path="shelf_tag_dataset"):
    """データセット構造作成"""
    dataset_path = Path(base_path)
    for subdir in ["train", "validation", "test", "annotations", "models", "dictionaries"]:
        (dataset_path / subdir).mkdir(parents=True, exist_ok=True)
    return dataset_path

def main():
    print("🚀 棚札検出システムをセットアップ中...")
    
    dataset_path = create_dataset_structure()
    classes = create_detection_classes()
    
    # 設定ファイル作成
    config = {
        "dataset_path": str(dataset_path),
        "classes": classes,
        "created_at": datetime.now().isoformat(),
        "version": "1.0.0"
    }
    
    with open(dataset_path / "config.json", 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=2)
    
    print(f"✅ セットアップ完了: {dataset_path}")

if __name__ == "__main__":
    main()
