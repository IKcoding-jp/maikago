import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_theme.dart';
import 'settings_persistence.dart';
import '../../services/voice_parser.dart';

class ExcludedWordsScreen extends StatefulWidget {
  const ExcludedWordsScreen({super.key});

  @override
  State<ExcludedWordsScreen> createState() => _ExcludedWordsScreenState();
}

class _ExcludedWordsScreenState extends State<ExcludedWordsScreen> {
  final TextEditingController _addWordController = TextEditingController();
  List<String> _userExcludedWords = [];
  bool _isLoading = true;

  // 長文除外設定
  bool _longTextExclusionEnabled = true;
  int _longTextThreshold = 25;
  bool _conversationalTextExclusionEnabled = true;

  // デフォルト除外ワード（ハードコード）
  static const List<String> _defaultExcludedWords = [
    // 価格関連
    '安い', '高い', '安価', '高価', '安いです', '高いです', '安いね', '高いね',
    '安いよ', '高いよ', '安いな', '高いな', '安いわ', '高いわ', '安いかも', '高いかも',

    // 感嘆詞・感動詞
    'すごい', 'すごいね', 'すごいよ', 'すごいな', 'すごいわ', 'すごいです', 'すごいですね', 'すごいですよ',
    'わあ', 'わー', 'うわー', 'おお', 'おー', 'やった', 'やったー', 'やったね', 'やったよ',
    'いいね', 'いいよ', 'いいな', 'いいわ', 'いいです', 'いいですね', 'いいですよ',
    'すばらしい', 'すばらしいね', 'すばらしいです', 'すばらしいですね',
    'きれい', 'きれいね', 'きれいです', 'きれいですね',
    'かわいい', 'かわいいね', 'かわいいです', 'かわいいですね',
    'かっこいい', 'かっこいいね', 'かっこいいです', 'かっこいいですね',

    // 指示代名詞・場所
    'あれ', 'これ', 'それ', 'どれ', 'あそこ', 'ここ', 'そこ', 'どこ',
    'あの', 'この', 'その', 'どの', 'あいつ', 'こいつ', 'そいつ', 'どいつ',
    'あちら', 'こちら', 'そちら', 'どちら', 'あっち', 'こっち', 'そっち', 'どっち',

    // 肯定・否定
    'いいえ', 'いえ', 'いや', 'いやいや', 'はい', 'うん', 'ううん', 'いえいえ',
    'そう', 'そうそう', 'そうですね', 'そうだね', 'そうよ', 'そうだよ',
    'ちがう', 'ちがいます', 'ちがうよ', 'ちがいますよ',

    // 曖昧表現
    'なんか', 'なんだか', 'なんとなく', 'ちょっと', 'ちょい', 'ちょっとだけ',
    'まあ', 'まあまあ', 'まあね', 'なんとなく', 'なんかね', 'なんかよ',
    'あのね', 'あのさ', 'あのさあ', 'あのねえ', 'あのさあね',

    // 時間・頻度
    'いつも', 'いつでも', 'いつか', 'いつでも', 'いつもね', 'いつもよ',
    'よく', 'よくね', 'よくよ', 'よくです', 'よくですね',
    'たまに', 'たまにね', 'たまによ', 'たまにです', 'たまにですね',
    'ときどき', 'ときどきね', 'ときどきよ', 'ときどきです', 'ときどきですね',

    // 程度・状態
    'とても', 'とてもね', 'とてもよ', 'とてもです', 'とてもですね',
    'すごく', 'すごくね', 'すごくよ', 'すごくです', 'すごくですね',
    'めっちゃ', 'めっちゃね', 'めっちゃよ', 'めっちゃです', 'めっちゃですね',
    'かなり', 'かなりね', 'かなりよ', 'かなりです', 'かなりですね',
    'わりと', 'わりとね', 'わりとよ', 'わりとです', 'わりとですね',

    // 感情・反応
    'うれしい', 'うれしいね', 'うれしいよ', 'うれしいです', 'うれしいですね',
    'たのしい', 'たのしいね', 'たのしいよ', 'たのしいです', 'たのしいですね',
    'おもしろい', 'おもしろいね', 'おもしろいよ', 'おもしろいです', 'おもしろいですね',
    'びっくり', 'びっくりした', 'びっくりです', 'びっくりですね',
    'おどろいた', 'おどろいたね', 'おどろいたよ', 'おどろいたです', 'おどろいたですね',

    // 評価・感想
    'おいしい', 'おいしいね', 'おいしいよ', 'おいしいです', 'おいしいですね',
    'まずい', 'まずいね', 'まずいよ', 'まずいです', 'まずいですね',
    'やわらかい', 'やわらかいね', 'やわらかいよ', 'やわらかいです', 'やわらかいですね',
    'かたい', 'かたいね', 'かたいよ', 'かたいです', 'かたいですね',
    'あたたかい', 'あたたかいね', 'あたたかいよ', 'あたたかいです', 'あたたかいですね',
    'つめたい', 'つめたいね', 'つめたいよ', 'つめたいです', 'つめたいですね',

    // 一般的な形容詞
    '大きい', '大きいね', '大きいよ', '大きいです', '大きいですね',
    '小さい', '小さいね', '小さいよ', '小さいです', '小さいですね',
    '新しい', '新しいね', '新しいよ', '新しいです', '新しいですね',
    '古い', '古いね', '古いよ', '古いです', '古いですね',
    '軽い', '軽いね', '軽いよ', '軽いです', '軽いですね',
    '重い', '重いね', '重いよ', '重いです', '重いですね',

    // 接続詞・副詞
    'でも', 'でもね', 'でもよ', 'でもです', 'でもですね',
    'だけど', 'だけどね', 'だけどよ', 'だけどです', 'だけどですね',
    'しかし', 'しかしね', 'しかしよ', 'しかしです', 'しかしですね',
    'やっぱり', 'やっぱりね', 'やっぱりよ', 'やっぱりです', 'やっぱりですね',
    'やはり', 'やはりね', 'やはりよ', 'やはりです', 'やはりですね',

    // その他の一般的な表現
    'あのさ', 'あのね', 'あのさあ', 'あのねえ',
    'そうそう', 'そうだそうだ', 'そうそうね', 'そうそうよ',
    'なるほど', 'なるほどね', 'なるほどよ', 'なるほどです', 'なるほどですね',
    'そうですね', 'そうだね', 'そうよ', 'そうだよ',
  ];

  @override
  void initState() {
    super.initState();
    _loadExcludedWords();
  }

  @override
  void dispose() {
    _addWordController.dispose();
    super.dispose();
  }

  Future<void> _loadExcludedWords() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final words = await SettingsPersistence.loadExcludedWords();

      if (mounted) {
        setState(() {
          _userExcludedWords = words;
          _isLoading = false;
        });
        // VoiceParserに除外ワードを設定
        VoiceParser.setExcludedWords(_userExcludedWords);

        // 長文除外設定を読み込み
        _loadLongTextExclusionSettings();
      }
    } catch (e) {
      debugPrint('除外ワード読み込みエラー: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('除外ワードの読み込みに失敗しました: $e')));
      }
    }
  }

  void _loadLongTextExclusionSettings() {
    try {
      final settings = VoiceParser.getLongTextExclusionSettings();
      setState(() {
        _longTextExclusionEnabled = settings['enabled'] ?? true;
        _longTextThreshold = settings['threshold'] ?? 25;
        _conversationalTextExclusionEnabled =
            settings['conversationalEnabled'] ?? true;
      });
    } catch (e) {
      debugPrint('長文除外設定読み込みエラー: $e');
    }
  }

  Future<void> _addExcludedWord(String word) async {
    if (word.trim().isEmpty) return;

    final trimmedWord = word.trim();
    if (_userExcludedWords.contains(trimmedWord)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('既に登録されているワードです')));
      }
      return;
    }

    setState(() {
      _userExcludedWords.add(trimmedWord);
    });

    try {
      await SettingsPersistence.saveExcludedWords(_userExcludedWords);
      VoiceParser.setExcludedWords(_userExcludedWords);
      _addWordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"$trimmedWord" を除外ワードに追加しました')));
      }
    } catch (e) {
      setState(() {
        _userExcludedWords.remove(trimmedWord);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('除外ワードの保存に失敗しました: $e')));
      }
    }
  }

  Future<void> _removeExcludedWord(String word) async {
    setState(() {
      _userExcludedWords.remove(word);
    });

    try {
      await SettingsPersistence.saveExcludedWords(_userExcludedWords);
      VoiceParser.setExcludedWords(_userExcludedWords);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"$word" を除外ワードから削除しました')));
      }
    } catch (e) {
      setState(() {
        _userExcludedWords.add(word);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('除外ワードの削除に失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('除外ワード設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SettingsState>(
        builder: (context, settingsState, child) {
          try {
            final theme = _getCurrentTheme(settingsState);

            return Container(
              color: theme.scaffoldBackgroundColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // 説明カード
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '除外ワードについて',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '音声入力で商品以外の言葉が認識されるのを防ぐため、除外したいワードを登録できます。\n\n例：「安い」「高い」「すごい」などの形容詞や感嘆詞\n\nまた、長文の会話や文章も自動的に除外されます。',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // デフォルト除外ワード表示
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'デフォルト除外ワード（変更不可）',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // 価格関連の代表例
                                    _buildWordTag('安い', Colors.red[100]!),
                                    _buildWordTag('高い', Colors.red[100]!),

                                    // 感嘆詞・感動詞の代表例
                                    _buildWordTag('すごい', Colors.blue[100]!),
                                    _buildWordTag('わあ', Colors.blue[100]!),

                                    // 指示代名詞の代表例
                                    _buildWordTag('あれ', Colors.green[100]!),
                                    _buildWordTag('これ', Colors.green[100]!),

                                    // 肯定・否定の代表例
                                    _buildWordTag('はい', Colors.orange[100]!),
                                    _buildWordTag('いいえ', Colors.orange[100]!),

                                    // 曖昧表現の代表例
                                    _buildWordTag('なんか', Colors.purple[100]!),
                                    _buildWordTag('ちょっと', Colors.purple[100]!),

                                    // 時間・頻度の代表例
                                    _buildWordTag('いつも', Colors.teal[100]!),
                                    _buildWordTag('よく', Colors.teal[100]!),

                                    // 程度・状態の代表例
                                    _buildWordTag('とても', Colors.indigo[100]!),
                                    _buildWordTag('すごく', Colors.indigo[100]!),

                                    // 感情・反応の代表例
                                    _buildWordTag('うれしい', Colors.pink[100]!),
                                    _buildWordTag('たのしい', Colors.pink[100]!),

                                    // 評価・感想の代表例
                                    _buildWordTag('おいしい', Colors.amber[100]!),
                                    _buildWordTag('まずい', Colors.amber[100]!),

                                    // 一般的な形容詞の代表例
                                    _buildWordTag('大きい', Colors.cyan[100]!),
                                    _buildWordTag('小さい', Colors.cyan[100]!),

                                    // 接続詞・副詞の代表例
                                    _buildWordTag('でも', Colors.lime[100]!),
                                    _buildWordTag('だけど', Colors.lime[100]!),

                                    // その他の一般的な表現の代表例
                                    _buildWordTag('なるほど', Colors.brown[100]!),
                                    _buildWordTag('そうそう', Colors.brown[100]!),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '他 ${_defaultExcludedWords.length - 24} 個のワード',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 長文除外設定
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.text_fields,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '長文除外設定',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '会話や長い文章を商品リストから自動的に除外します。商品名が誤って除外されることを防ぐため、数量や価格が含まれる場合は除外しません。',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  title: const Text('長文を自動除外'),
                                  subtitle: const Text('会話や長い文章を商品リストから除外'),
                                  value: _longTextExclusionEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _longTextExclusionEnabled = value;
                                    });
                                    VoiceParser.setLongTextExclusionSettings(
                                      enabled: value,
                                    );
                                  },
                                ),
                                if (_longTextExclusionEnabled) ...[
                                  ListTile(
                                    title: const Text('文字数閾値'),
                                    subtitle: Text(
                                      '$_longTextThreshold文字以上を長文として除外',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            if (_longTextThreshold > 15) {
                                              setState(() {
                                                _longTextThreshold -= 5;
                                              });
                                              VoiceParser.setLongTextExclusionSettings(
                                                threshold: _longTextThreshold,
                                              );
                                            }
                                          },
                                        ),
                                        Text('$_longTextThreshold'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              _longTextThreshold += 5;
                                            });
                                            VoiceParser.setLongTextExclusionSettings(
                                              threshold: _longTextThreshold,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SwitchListTile(
                                    title: const Text('会話文を除外'),
                                    subtitle: const Text(
                                      '「なんだろうな」「だよね」などの会話表現を除外',
                                    ),
                                    value: _conversationalTextExclusionEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _conversationalTextExclusionEnabled =
                                            value;
                                      });
                                      VoiceParser.setLongTextExclusionSettings(
                                        conversationalEnabled: value,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ユーザー除外ワード追加
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '除外ワードを追加',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _addWordController,
                                        decoration: InputDecoration(
                                          hintText: '除外したいワードを入力',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                        onSubmitted: _addExcludedWord,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _addExcludedWord(
                                        _addWordController.text,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor:
                                            theme.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('追加'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ユーザー除外ワード一覧
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.list,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '追加した除外ワード',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_userExcludedWords.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.inbox_outlined,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '追加した除外ワードはありません',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...(_userExcludedWords.map(
                                    (word) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(word),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () =>
                                              _removeExcludedWord(word),
                                          color: Colors.red[400],
                                        ),
                                      ),
                                    ),
                                  )),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            );
          } catch (e) {
            debugPrint('除外ワード設定画面エラー: $e');
            return Container(
              color: Colors.grey[100],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('画面の読み込みに失敗しました', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                      'アプリを再起動してください',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildWordTag(String word, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  ThemeData _getCurrentTheme(SettingsState settingsState) {
    try {
      return SettingsTheme.generateTheme(
        selectedTheme: settingsState.selectedTheme,
        selectedFont: settingsState.selectedFont,
        fontSize: settingsState.selectedFontSize,
      );
    } catch (e) {
      debugPrint('テーマ生成エラー: $e');
      // フォールバックテーマを返す
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      );
    }
  }
}
