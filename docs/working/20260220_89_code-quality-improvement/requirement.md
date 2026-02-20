# 要件定義 — Issue #89: コード品質改善

## 概要

AI生成コードに特徴的な重複・ボイラープレート・エラーハンドリング不備を改善する。

## 背景

バイブコーディングにより「動くが冗長」なコードが蓄積。カメラ画面の重複、settings_persistenceの同一パターン反復が技術的負債の中心。

## 要件一覧

### High

| ID | 要件 | 対象ファイル |
|----|------|------------|
| H-1 | カメラ画面の統合（95%重複解消） | `camera_screen.dart`, `enhanced_camera_screen.dart` |
| H-2 | ハードコードバージョン番号の修正 | `version_notification_service.dart:46`, `release_history_screen.dart:43` |

### Medium

| ID | 要件 | 対象ファイル |
|----|------|------------|
| M-1 | settings_persistence のジェネリックヘルパー共通化 | `settings_persistence.dart` |
| M-2 | 空catchブロック / エラー握りつぶしの修正（6+箇所） | 複数ファイル |
| M-3 | donation_screen の冗長switch文をMap定義に統一 | `donation_screen.dart` |

### Low（今回スコープ外）

| ID | 要件 | 備考 |
|----|------|------|
| L-1 | 無意味なリトライロジック修正 | camera_screen.dart:188-199 |
| L-2 | コメント言語の日本語統一 | 全体 |
| L-3 | withValues(alpha:) 149箇所のテーマ統合 | 大規模、別Issue推奨 |
| L-4 | 500行超ファイルの分割検討（14ファイル） | 大規模、別Issue推奨 |

## 受入基準

- [x] カメラ画面が1ファイルに統合され、既存機能が維持される
- [x] バージョン番号がハードコードされていない（定数化）
- [x] settings_persistence の重複パターンがジェネリックヘルパーで共通化
- [x] 全空catchブロックに適切なログ記録が追加
- [x] donation_screen のswitch文がMapに統一
- [x] `flutter analyze` エラーなし
- [x] `flutter test` 全テスト通過
