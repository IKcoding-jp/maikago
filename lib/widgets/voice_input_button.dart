import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/item.dart';
import '../providers/data_provider.dart';
import '../services/voice_parser.dart';
import '../drawer/settings/settings_persistence.dart';

class VoiceInputButton extends StatefulWidget {
  final String shopId;
  final bool autoStart;
  final Color? color;
  const VoiceInputButton({
    Key? key,
    required this.shopId,
    this.autoStart = false,
    this.color,
  }) : super(key: key);

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  bool _persistent = false; // タップで常時オンにするフラグ

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startListening();
      });
    }
  }

  Future<void> _startListening() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          // 状態変化を反映
          if ((status == 'done' || status == 'notListening') && !_persistent) {
            if (mounted) setState(() => _isListening = false);
          }
          // persistent モードなら自動的に再リッスンする
          if ((status == 'done' || status == 'notListening') && _persistent) {
            // 少し待ってから再開
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _persistent) {
                try {
                  _listen();
                } catch (_) {}
              }
            });
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
          final msg = error.toString();
          final lower = msg.toLowerCase();

          // ユーザーが何も喋らなかった等の一時的なエラーは無視
          final ignorePatterns = [
            'no match',
            'no speech',
            'no_speech',
            'speech timeout',
            'timeout',
            'not listening',
            'listening timed out',
            'no audio',
            'no input',
          ];
          for (final p in ignorePatterns) {
            if (lower.contains(p)) {
              debugPrint('speech_to_text transient error ignored: $msg');
              return;
            }
          }

          // 権限や重大なエラーのみ通知
          if (lower.contains('permission') ||
              lower.contains('denied') ||
              lower.contains('not-allowed') ||
              lower.contains('microphone')) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('音声認識エラー: $msg')));
          } else {
            debugPrint('speech_to_text error ignored: $msg');
          }
        },
      );
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('音声認識を初期化できません。マイク権限を確認してください')),
          );
        }
        return;
      }
      setState(() => _isListening = true);
      _listen();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('音声認識の初期化に失敗しました: $e')));
      }
    }
  }

  void _listen() {
    _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
        if (result.finalResult) {
          _onRecognized(_lastWords);
        }
      },
    );
    if (mounted) setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _onRecognized(String text) async {
    if (text.trim().isEmpty) return;

    // 簡易パース: 「と」「、」「および」で分割して複数項目対応
    final parts = text
        .split(RegExp(r'、|と|および|,'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final dataProvider = context.read<DataProvider>();
    final autoAdd = await SettingsPersistence.loadVoiceAutoAddEnabled();

    for (final part in parts) {
      final parsed = VoiceParser.parse(part);
      if (parsed.name.isEmpty) continue;

      // フィルター: 明らかに商品名ではない短すぎる/長すぎる/会話文っぽい入力を除外
      final rawName = parsed.name.trim();
      final nameNoPunct = rawName.replaceAll(RegExp(r'[。．\.\,、！!？?（）()\[\]「」『』\s]+'), '');

      // 短すぎる（1文字など）は除外
      if (nameNoPunct.length <= 1) {
        debugPrint('voice input ignored: too short -> "$rawName"');
        continue;
      }

      // 長文や会話（非常に長い、単語数が多い）は除外
      if (rawName.length > 60) {
        debugPrint('voice input ignored: too long -> length=${rawName.length}');
        continue;
      }
      final words = rawName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (words.length > 6) {
        debugPrint('voice input ignored: looks like conversation -> words=${words.length}');
        continue;
      }

      // 会話フレーズに含まれる語は除外（例: ありがとう、おはよう 等）
      final convoPatterns = RegExp(r'(ありがとう|おはよう|こんばんは|どういたしまして|そうですか|そうですね|いいえ|うん|ええ|なるほど|わかった|ちょっと|あとで)');
      if (convoPatterns.hasMatch(rawName)) {
        debugPrint('voice input ignored: conversational phrase -> "$rawName"');
        continue;
      }

      final item = Item(
        id: '',
        name: parsed.name,
        quantity: parsed.quantity == 0 ? 1 : parsed.quantity,
        price: parsed.price,
        discount: parsed.discount,
        shopId: widget.shopId,
      );

      if (autoAdd) {
        try {
          await dataProvider.addItem(item);
        } catch (_) {}
      } else {
        if (!context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('追加確認'),
            content: Text(
              '「${item.name}」 個数:${item.quantity} 単価:${item.price} 円 割引:${(item.discount * 100).toStringAsFixed(0)}% を追加しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('追加'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            await dataProvider.addItem(item);
          } catch (_) {}
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FAB風の小さな丸ボタンでプラスと見た目を揃える
    final bg = widget.color ?? Theme.of(context).colorScheme.primary;
    final fg = Theme.of(context).colorScheme.onPrimary;

    // 有効状態の視覚変化: 大きめ、強いシャドウ、白い縁取り
    final active = _isListening || _persistent;
    final size = active ? 48.0 : 40.0;
    final shadow = active
        ? [
            BoxShadow(
              color: bg.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: shadow,
        border: active
            ? Border.all(color: Colors.white.withOpacity(0.85), width: 2)
            : null,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(active ? Icons.mic : Icons.mic_none, size: active ? 22 : 20),
        color: fg,
        tooltip: active ? '音声入力（オン）' : '音声入力',
        onPressed: () async {
          // タップで常時モードのオン/オフを切替
          if (!_persistent) {
            _persistent = true;
            await _startListening();
          } else {
            // persistent モードをオフにして停止
            _persistent = false;
            _stopListening();
          }
        },
      ),
    );
  }
}
