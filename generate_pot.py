#!/usr/bin/env python3
"""
ARBファイルからpotファイルを生成するスクリプト
Windows環境でFlutterアプリの国際化用potファイルを作成します
"""

import json
import os
import sys
from datetime import datetime

def create_pot_from_arb(arb_file_path, pot_file_path):
    """ARBファイルからpotファイルを生成"""
    
    try:
        with open(arb_file_path, 'r', encoding='utf-8') as f:
            arb_data = json.load(f)
    except FileNotFoundError:
        print(f"エラー: ARBファイルが見つかりません: {arb_file_path}")
        return False
    except json.JSONDecodeError as e:
        print(f"エラー: ARBファイルのJSON形式が不正です: {e}")
        return False
    
    # potファイルのヘッダー
    pot_header = f'''# Copyright (C) {datetime.now().year} Maikago
# This file is distributed under the same license as the Maikago package.
msgid ""
msgstr ""
"Project-Id-Version: Maikago 0.7.0\\n"
"Report-Msgid-Bugs-To: \\n"
"POT-Creation-Date: {datetime.now().strftime('%Y-%m-%d %H:%M%z')}\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"Language: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"

'''
    
    pot_content = pot_header
    
    # ARBファイルの各エントリを処理
    for key, value in arb_data.items():
        # メタデータ（@で始まるキー）はスキップ
        if key.startswith('@') or key.startswith('@@'):
            continue
        
        # 文字列値のみを処理
        if isinstance(value, str):
            # 改行文字をエスケープ
            escaped_value = value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
            
            # 複数行の場合は適切にフォーマット
            if '\n' in value:
                lines = escaped_value.split('\\n')
                pot_content += f'msgid "{lines[0]}"\n'
                for line in lines[1:]:
                    pot_content += f'       "{line}"\n'
                pot_content += 'msgstr ""\n\n'
            else:
                pot_content += f'msgid "{escaped_value}"\n'
                pot_content += 'msgstr ""\n\n'
    
    # potファイルを保存
    try:
        with open(pot_file_path, 'w', encoding='utf-8') as f:
            f.write(pot_content)
        print(f"✅ potファイルが正常に生成されました: {pot_file_path}")
        return True
    except Exception as e:
        print(f"エラー: potファイルの保存に失敗しました: {e}")
        return False

def main():
    """メイン関数"""
    print("🌐 Flutterアプリ用potファイル生成ツール")
    print("=" * 50)
    
    # ファイルパスを設定
    arb_file_path = "lib/l10n/app_en.arb"
    pot_file_path = "lib/l10n/app.pot"
    
    # ARBファイルの存在確認
    if not os.path.exists(arb_file_path):
        print(f"❌ ARBファイルが見つかりません: {arb_file_path}")
        print("先にARBファイルを作成してください。")
        return False
    
    # potファイルを生成
    success = create_pot_from_arb(arb_file_path, pot_file_path)
    
    if success:
        print("\n📋 生成されたpotファイルの内容:")
        print("-" * 30)
        try:
            with open(pot_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                print(content[:1000] + "..." if len(content) > 1000 else content)
        except Exception as e:
            print(f"ファイル内容の表示に失敗: {e}")
    
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
