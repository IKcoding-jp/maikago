import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/item.dart';
import '../models/shop.dart';
import '../providers/data_provider.dart';
import '../services/voice_parser.dart';
import '../drawer/settings/settings_persistence.dart';

class VoiceInputButton extends StatefulWidget {
  final String shopId;
  final bool autoStart;
  final Color? color;
  const VoiceInputButton({
    super.key,
    required this.shopId,
    this.autoStart = false,
    this.color,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  bool _persistent = false; // タップで常時オンにするフラグ
  String _activationMode = 'toggle'; // 'toggle' or 'hold'
  bool _isHolding = false; // 長押し中かどうか

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // 動作モードを読み込み
    _loadActivationMode();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startListening();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 必要な時のみ設定を再読み込み（頻繁な呼び出しを避ける）
    // 設定変更は明示的に呼び出すか、initStateで十分
  }

  @override
  void didUpdateWidget(covariant VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 親の再構築（設定画面から戻るなど）時に最新の設定を反映
    _loadActivationMode();
  }

  Future<void> _loadActivationMode() async {
    try {
      final mode = await SettingsPersistence.loadVoiceActivationMode();
      if (mounted) {
        setState(() {
          _activationMode = (mode == 'hold') ? 'hold' : 'toggle';
        });
      }
    } catch (e) {
      // エラーは無視（デフォルト値を使用）
    }
  }

  /// 外部から設定を再読み込みするためのメソッド
  void reloadActivationMode() {
    _loadActivationMode();
  }

  Future<void> _startListening() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          // 状態変化を反映
          final finished = status == 'done' || status == 'notListening';
          if (finished) {
            final shouldContinue =
                _persistent || (_activationMode == 'hold' && _isHolding);
            if (shouldContinue) {
              // 少し待ってから再開
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted &&
                    (_persistent ||
                        (_activationMode == 'hold' && _isHolding))) {
                  try {
                    _listen();
                  } catch (_) {}
                }
              });
            } else {
              if (mounted) setState(() => _isListening = false);
            }
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

    // まず全文に対して削除/購入/取り消し命令がないか確認
    final globalParsed = VoiceParser.parse(text);
    if (globalParsed.action == 'delete_item' ||
        globalParsed.action == 'mark_purchased' ||
        globalParsed.action == 'mark_unpurchased' ||
        globalParsed.action == 'undo_last') {
      final shop = dataProvider.shops.firstWhere(
        (s) => s.id == widget.shopId,
        orElse: () => Shop(id: '0', name: 'デフォルト', items: []),
      );
      final normTarget = globalParsed.name.trim();
      if (normTarget.isEmpty) return;
      Item? found;
      try {
        found = shop.items.firstWhere(
          (it) => it.name.trim().toLowerCase() == normTarget.toLowerCase(),
        );
      } catch (_) {
        found = null;
      }
      if (found == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('該当するアイテムが見つかりませんでした: ${globalParsed.name}'),
            ),
          );
        }
        return;
      }

      if (globalParsed.action == 'mark_purchased') {
        final updated = found.copyWith(isChecked: true);
        if (autoAdd) {
          try {
            await dataProvider.updateItem(updated);
          } catch (_) {}
        } else {
          if (!mounted) return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('確認'),
              content: Text('"${found!.name}" を購入済みにしますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('購入済みにする'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            try {
              await dataProvider.updateItem(updated);
            } catch (_) {}
          }
        }
        return;
      }

      if (globalParsed.action == 'mark_unpurchased') {
        final updated = found.copyWith(isChecked: false);
        if (autoAdd) {
          try {
            await dataProvider.updateItem(updated);
          } catch (_) {}
        } else {
          if (!mounted) return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('確認'),
              content: Text('"${found!.name}" を未購入にしますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('未購入にする'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            try {
              await dataProvider.updateItem(updated);
            } catch (_) {}
          }
        }
        return;
      }

      // delete_item
      if (autoAdd) {
        try {
          await dataProvider.deleteItem(found.id);
        } catch (_) {}
      } else {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('確認'),
            content: Text('"${found!.name}" を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            await dataProvider.deleteItem(found.id);
          } catch (_) {}
        }
      }
      return;
    }

    // 取り消しアクションの処理
    if (globalParsed.action == 'undo_last') {
      if (!mounted) return;

      // 最後に追加された項目を取得
      final shop = dataProvider.shops.firstWhere(
        (s) => s.id == widget.shopId,
        orElse: () => Shop(id: '0', name: 'デフォルト', items: []),
      );

      if (shop.items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('取り消す項目がありません')));
        }
        return;
      }

      // 作成日時でソートして最新の項目を取得
      final sortedItems = List.from(shop.items)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final lastItem = sortedItems.first;

      if (autoAdd) {
        try {
          await dataProvider.deleteItem(lastItem.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('「${lastItem.name}」を取り消しました')),
            );
          }
        } catch (_) {}
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('取り消し確認'),
            content: Text('最後に追加された「${lastItem.name}」を取り消しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('取り消し'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            await dataProvider.deleteItem(lastItem.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${lastItem.name}」を取り消しました')),
              );
            }
          } catch (_) {}
        }
      }
      return;
    }
    for (final part in parts) {
      final parsed = VoiceParser.parse(part);
      if (parsed.name.isEmpty) continue;

      // まず既存アイテムを探して編集するか判定
      final shop = dataProvider.shops.firstWhere(
        (s) => s.id == widget.shopId,
        orElse: () => Shop(id: '0', name: 'デフォルト', items: []),
      );

      // 名前の正規化用ヘルパー
      String normalizeName(String n) => n
          .replaceAll(
            RegExp(r'[^\w\u3000-\u303F\u3040-\u30FF\u4E00-\u9FFF]'),
            '',
          )
          .toLowerCase();

      Item? existing;
      try {
        final normTarget = normalizeName(parsed.name);
        existing = shop.items.firstWhere(
          (it) => normalizeName(it.name) == normTarget,
        );
      } catch (_) {
        existing = null;
      }

      // 既存が見つかった場合は新規追加を行わず、編集フィールドがあれば更新する
      final hasEditField =
          parsed.price > 0 || parsed.quantity != 0 || parsed.discount > 0.0;
      if (existing != null) {
        if (hasEditField) {
          final updated = existing.copyWith(
            price: parsed.price > 0 ? parsed.price : existing.price,
            quantity: parsed.quantity != 0
                ? parsed.quantity
                : existing.quantity,
            discount: parsed.discount > 0.0
                ? parsed.discount
                : existing.discount,
          );
          try {
            await dataProvider.updateItem(updated);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${updated.name}」を更新しました')),
              );
            }
          } catch (_) {}
        }
        continue; // 既存アイテムが見つかったら追加はしない
      }

      // 既存アイテムが無い場合は新規追加の流れ
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
        if (!mounted) return;
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
    final size = active ? 64.0 : 56.0;
    final shadow = active
        ? [
            BoxShadow(
              color: bg.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
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
            ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2)
            : null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _activationMode == 'hold'
            ? (details) async {
                // 押下で即時開始（押している間のみ継続）
                _persistent = false;
                _isHolding = true;
                if (!_isListening) {
                  await _startListening();
                }
              }
            : null,
        onTapUp: _activationMode == 'hold'
            ? (details) {
                // 指を離したら停止
                _isHolding = false;
                _stopListening();
              }
            : null,
        onTapCancel: _activationMode == 'hold'
            ? () {
                _isHolding = false;
                _stopListening();
              }
            : null,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            active ? Icons.mic : Icons.mic_none,
            size: active ? 30 : 28,
          ),
          color: fg,
          tooltip: _activationMode == 'hold'
              ? null
              : (active ? '音声入力（オン）' : '音声入力（切り替え）'),
          onPressed: _activationMode == 'hold'
              ? null
              : () async {
                  // 切り替えモード: タップで常時モードのオン/オフ切替
                  if (!_persistent) {
                    _persistent = true;
                    await _startListening();
                  } else {
                    _persistent = false;
                    _stopListening();
                  }
                },
        ),
      ),
    );
  }
}
