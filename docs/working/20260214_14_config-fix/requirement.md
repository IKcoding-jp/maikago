# 要件定義: config.dartの設定値修正

## Issue
- **番号**: #14
- **タイトル**: fix: config.dartの設定値修正（OpenAIモデル名・広告初期化遅延）
- **ラベル**: bug

## 背景

`config.dart`に複数の設定値の問題がある。

## 要件

### 1. OpenAIモデル名の修正

- **現状**: `lib/config.dart:101` で `defaultValue: 'gpt-5-nano'` が設定されている
- **問題**: `gpt-5-nano` は実在しないモデル名
- **要件**: 実在するモデル名に変更する（例: `gpt-4o-mini`）
- **影響範囲**: `chatgpt_service.dart`, `product_name_summarizer_service.dart` で参照

### 2. 広告初期化遅延の改善

- **現状**: `lib/main.dart:192` で `Future.delayed(Duration(milliseconds: 10000))` による10秒固定遅延
- **問題**: ハードコードされた10秒遅延は過剰で、UXに影響する可能性がある
- **要件**: 適切な値に調整またはイベント駆動に変更

## 受け入れ基準

- [ ] OpenAIモデル名が実在するモデルに変更されている
- [ ] 広告初期化の遅延が適切な値に調整されている
- [ ] `flutter analyze` が通過する
- [ ] 既存テストが通過する
