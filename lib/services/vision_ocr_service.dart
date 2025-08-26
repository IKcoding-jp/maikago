import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';
import 'package:image/image.dart' as img;
import 'package:maikago/services/chatgpt_service.dart';
import 'package:maikago/services/cloud_functions_service.dart';
import 'package:maikago/services/security_audit_service.dart';
import 'package:maikago/services/tax_utils.dart';
import 'package:maikago/services/user_tax_history_service.dart';

class OcrItemResult {
  final String name;
  final int price;
  OcrItemResult({required this.name, required this.price});
}

/// OCR処理の進行状況を表す列挙型
enum OcrProgressStep {
  initializing,
  imageOptimization,
  cloudFunctionsCall,
  visionApiCall,
  textExtraction,
  dataProcessing,
  completed,
  failed,
}

/// OCR処理の進行状況コールバック
typedef OcrProgressCallback = void Function(
    OcrProgressStep step, String message);

class VisionOcrService {
  final String apiKey;
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  final ChatGptService _chatGptService = ChatGptService();
  final SecurityAuditService _securityAudit = SecurityAuditService();

  VisionOcrService({String? apiKey}) : apiKey = apiKey ?? googleVisionApiKey;

  /// ChatGPT候補からアプリ仕様に沿って「必ず税込価格のみ」を計算し、最適な1件を選ぶ
  Future<OcrItemResult?> _selectFinalFromCandidates(
      List<Map<String, dynamic>> candidates) async {
    if (candidates.isEmpty) return null;

    OcrItemResult? best;
    for (final c in candidates) {
      final name = (c['商品名'] ?? c['name'] ?? '').toString();
      if (name.isEmpty) continue;

      final int? taxExcluded = _toIntOrNull(c['税抜価格']);
      final int? taxIncluded = _toIntOrNull(c['税込価格']);
      double? rate = _toDoubleOrNull(c['税率']);

      // ユーザー上書きがあればそれを最優先（税込価格が明示されている場合はそのまま採用）
      final double? userOverride = await UserTaxHistoryService.getTaxRate(name);

      int? finalPrice;
      if (taxIncluded != null && taxIncluded > 0) {
        finalPrice = taxIncluded;
        debugPrint('✅ 候補(明示税込) name=$name, 税込=$finalPrice');
      } else if (taxExcluded != null && taxExcluded > 0) {
        double appliedRate =
            userOverride ?? rate ?? (TaxUtils.isFood(name) ? 0.08 : 0.10);
        finalPrice = (taxExcluded * (1 + appliedRate)).round();
        debugPrint(
            '🧮 候補(税抜→税込換算) name=$name, 本体=$taxExcluded, 率=${appliedRate.toStringAsFixed(2)} → 税込=$finalPrice');
      } else {
        continue; // 価格情報がない候補はスキップ
      }

      if (best == null || finalPrice > best.price) {
        best = OcrItemResult(name: name, price: finalPrice);
      }
    }

    return best;
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      final d = double.tryParse(s);
      if (d != null) return d.round();
      return int.tryParse(s);
    }
    return null;
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final s = v.replaceAll('%', '').trim();
      final d = double.tryParse(s);
      if (d == null) return null;
      if (d > 1.0) return d / 100.0; // 8 → 0.08
      return d;
    }
    return null;
  }

  /// Cloud Functionsを使用した画像解析（推奨）
  Future<OcrItemResult?> detectItemFromImageWithCloudFunctions(File image,
      {OcrProgressCallback? onProgress}) async {
    try {
      onProgress?.call(
          OcrProgressStep.cloudFunctionsCall, 'Cloud Functionsで解析中...');
      debugPrint('🔥 Cloud Functionsを使用した画像解析開始');

      // 画像をbase64エンコード
      onProgress?.call(OcrProgressStep.imageOptimization, '画像をエンコード中...');
      final resizedBytes = await _resizeImage(image);
      final b64 = base64Encode(resizedBytes);

      // Cloud Functionsを呼び出し
      onProgress?.call(
          OcrProgressStep.cloudFunctionsCall, 'Cloud FunctionsでOCR解析中...');
      final result = await _cloudFunctions.analyzeImage(b64);

      if (result['success'] == true) {
        final ocrText = result['ocrText'] as String? ?? '';
        debugPrint('📝 Cloud Functions OCR結果: $ocrText');

        // OCRテキストが空の場合は失敗
        if (ocrText.isEmpty) {
          onProgress?.call(OcrProgressStep.failed, 'テキストが検出されませんでした');
          debugPrint('⚠️ Cloud Functions: テキストが検出されませんでした');
          return null;
        }

        onProgress?.call(OcrProgressStep.dataProcessing, 'ChatGPTで商品情報を解析中...');

        // 新仕様: ChatGPTから価格候補を取得
        final candidates =
            await _chatGptService.extractPriceCandidates(ocrText);

        if (candidates.isNotEmpty) {
          // 候補をポスト処理して最終税込価格を算出
          final selected = await _selectFinalFromCandidates(candidates);
          if (selected != null) {
            onProgress?.call(OcrProgressStep.completed, 'Cloud Functions解析完了');
            debugPrint(
                '✅ Cloud Functions解析成功(新仕様): name=${selected.name}, price=${selected.price}');
            return selected;
          }
        }
      }

      onProgress?.call(OcrProgressStep.failed, 'Cloud Functions解析失敗');
      debugPrint('⚠️ Cloud Functions解析結果が不正です: $result');
      return null;
    } catch (e) {
      onProgress?.call(OcrProgressStep.failed, 'Cloud Functionsエラー');
      debugPrint('❌ Cloud Functions解析エラー: $e');
      // フォールバック: 従来のVision APIを使用
      debugPrint('🔄 従来のVision APIにフォールバック');
      return detectItemFromImage(image, onProgress: onProgress);
    }
  }

  /// 従来のVision APIを使用した画像解析（フォールバック用）
  Future<OcrItemResult?> detectItemFromImage(File image,
      {OcrProgressCallback? onProgress}) async {
    // セキュリティ監査の記録
    _securityAudit.recordVisionApiCall();

    if (apiKey.isEmpty) {
      onProgress?.call(OcrProgressStep.failed, 'Vision APIキーが未設定です');
      debugPrint(
        '⚠️ Vision APIキーが未設定です。--dart-define=GOOGLE_VISION_API_KEY=... を指定してください',
      );
      return null;
    }

    try {
      onProgress?.call(OcrProgressStep.visionApiCall, 'Vision APIで解析中...');

      // 画像を前処理＋リサイズしてファイルサイズを削減
      final resizedBytes = await _resizeImage(image);
      final b64 = base64Encode(resizedBytes);

      final url = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
      );
      final body = jsonEncode({
        'requests': [
          {
            'image': {'content': b64},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'},
            ],
            'imageContext': {
              'languageHints': ['ja', 'en'],
            },
          },
        ],
      });

      debugPrint(
          '📸 Vision APIへリクエスト送信中... (画像サイズ: ${resizedBytes.length} bytes)');

      // タイムアウト時間を短縮（30秒 → 15秒）
      final resp = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        onProgress?.call(
            OcrProgressStep.failed, 'Vision APIエラー: HTTP ${resp.statusCode}');
        debugPrint('❌ Vision APIエラー: HTTP ${resp.statusCode} ${resp.body}');
        return null;
      }

      onProgress?.call(OcrProgressStep.textExtraction, 'テキストを抽出中...');

      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      final responses = (jsonMap['responses'] as List?) ?? const [];
      if (responses.isEmpty) {
        onProgress?.call(OcrProgressStep.failed, 'Vision APIレスポンスが空でした');
        debugPrint('⚠️ Vision APIレスポンスが空でした');
        return null;
      }

      final fullText = (responses.first['fullTextAnnotation']?['text']
              as String?) ??
          (responses.first['textAnnotations']?[0]?['description'] as String?);

      if (fullText == null || fullText.trim().isEmpty) {
        onProgress?.call(OcrProgressStep.failed, 'テキスト抽出に失敗しました');
        debugPrint('⚠️ テキスト抽出に失敗しました');
        return null;
      }

      debugPrint('🔎 抽出テキスト:\n$fullText');

      onProgress?.call(OcrProgressStep.dataProcessing, 'ChatGPTで商品情報を解析中...');

      // 新仕様: ChatGPTで価格候補を抽出
      try {
        final chat = ChatGptService();
        final candidates = await chat.extractPriceCandidates(fullText);
        if (candidates.isNotEmpty) {
          final selected = await _selectFinalFromCandidates(candidates);
          if (selected != null) {
            onProgress?.call(OcrProgressStep.completed, 'ChatGPT解析完了');
            debugPrint(
                '✅ ChatGPT解析成功(新仕様): name=${selected.name}, price=${selected.price}');
            return selected;
          }
        }
      } catch (e) {
        debugPrint('⚠️ ChatGPT解析呼び出し失敗(新仕様): $e');
      }

      onProgress?.call(OcrProgressStep.failed, '商品情報の抽出に失敗しました');
      debugPrint('⚠️ ChatGPTによる商品情報の抽出に失敗しました');
      return null;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        onProgress?.call(OcrProgressStep.failed, 'タイムアウト: ネットワーク接続を確認してください');
        debugPrint('⏰ Vision APIタイムアウト: ネットワーク接続またはAPI応答が遅延しています');
        debugPrint('💡 対策: インターネット接続を確認し、しばらく待ってから再試行してください');
      } else {
        onProgress?.call(OcrProgressStep.failed, 'Vision APIエラーが発生しました');
        debugPrint('❌ Vision APIエラー: $e');
      }
      return null;
    }
  }

  /// 画像を前処理＋リサイズして最適化（精度向上版）
  Future<Uint8List> _resizeImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        debugPrint('⚠️ 画像のデコードに失敗しました');
        return bytes;
      }

      // EXIFの向きを反映してから処理
      img.Image working = img.bakeOrientation(originalImage);

      // グレースケール化 + コントラスト強調 + 軽いシャープ処理
      try {
        working = img.grayscale(working);
        // コントラストをやや強める（1.0 = 無変化）
        // image 4.x の adjustColor を想定
        working = img.adjustColor(working, contrast: 1.15);
        // シャープ処理は環境差異が大きいためスキップ（必要なら別実装に差し替え）
      } catch (_) {
        // ランタイム差異でAPIが存在しない場合はそのまま進行
      }

      // より積極的なリサイズで処理速度とOCR安定性を両立
      const maxSize = maxImageSize; // 設定ファイルから取得
      const quality = imageQuality; // 設定ファイルから取得

      if (working.width > maxSize || working.height > maxSize) {
        // アスペクト比を保持してリサイズ
        final aspectRatio = working.width / working.height;
        int newWidth, newHeight;

        if (aspectRatio > 1) {
          // 横長画像
          newWidth = maxSize;
          newHeight = (maxSize / aspectRatio).round();
        } else {
          // 縦長画像
          newHeight = maxSize;
          newWidth = (maxSize * aspectRatio).round();
        }

        final resizedImage = img.copyResize(
          working,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        final resizedBytes = img.encodeJpg(resizedImage, quality: quality);
        debugPrint(
            '📏 画像を最適化（前処理＋リサイズ）: ${originalImage.width}x${originalImage.height} → ${resizedImage.width}x${resizedImage.height} (${bytes.length} → ${resizedBytes.length} bytes)');
        return resizedBytes;
      }

      // 元画像が小さい場合でも品質を最適化
      if (bytes.length > 500000) {
        // 500KB以上の場合
        final optimizedBytes = img.encodeJpg(working, quality: quality);
        debugPrint(
            '📏 画像品質を最適化: ${bytes.length} → ${optimizedBytes.length} bytes');
        return optimizedBytes;
      }

      // 前処理のみ反映
      final preprocessed = img.encodeJpg(working, quality: quality);
      return preprocessed;
    } catch (e) {
      debugPrint('⚠️ 画像リサイズエラー: $e');
      return await image.readAsBytes();
    }
  }
}
