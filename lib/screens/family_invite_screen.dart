import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';
import '../services/user_display_service.dart';

class FamilyInviteScreen extends StatefulWidget {
  const FamilyInviteScreen({super.key});

  @override
  State<FamilyInviteScreen> createState() => _FamilyInviteScreenState();
}

class _FamilyInviteScreenState extends State<FamilyInviteScreen> {
  final UserDisplayService _userDisplayService = UserDisplayService();
  final Map<String, String> _displayNames = {};
  bool _isLoadingDisplayNames = false;

  @override
  void initState() {
    super.initState();

    // 表示名の初期化
    _loadDisplayNames();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 依存関係が変更された際に表示名を再読み込み
    _loadDisplayNames();
  }

  /// 表示名を読み込み
  Future<void> _loadDisplayNames() async {
    if (_isLoadingDisplayNames) return;

    setState(() {
      _isLoadingDisplayNames = true;
    });

    try {
      // 現在のユーザーIDを取得
      final currentUserId = _userDisplayService.getCurrentUserId();
      if (currentUserId.isNotEmpty) {
        // 現在のユーザーの表示名を取得（キャッシュ優先）
        final currentDisplayName =
            await _userDisplayService.getUserDisplayName(currentUserId);
        if (mounted) {
          setState(() {
            _displayNames[currentUserId] = currentDisplayName;
          });
        }
      }
    } catch (e) {
      debugPrint('表示名読み込みエラー: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDisplayNames = false;
        });
      }
    }
  }

  /// ファミリーメンバーの表示名を読み込み
  Future<void> _loadFamilyMemberDisplayNames(List<String> memberIds) async {
    if (memberIds.isEmpty) return;

    try {
      debugPrint('🔍 ファミリーメンバー表示名読み込み開始: $memberIds');

      // 各メンバーの表示名を個別に取得（キャッシュ優先）
      for (final memberId in memberIds) {
        final displayName =
            await _userDisplayService.getUserDisplayName(memberId);
        if (mounted) {
          setState(() {
            _displayNames[memberId] = displayName;
          });
        }
        debugPrint('🔍 メンバー表示名取得: $memberId -> $displayName');
      }

      debugPrint('🔍 表示名を更新しました: $_displayNames');
    } catch (e) {
      debugPrint('❌ ファミリーメンバー表示名読み込みエラー: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _buildQrPayload(String ownerUserId) {
    // バージョン付きスキームでエンコード
    final payload = 'maikago://family_invite?v=1&owner=$ownerUserId';
    debugPrint('🔍 QRコードペイロード生成: $payload');
    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final ownerId = auth.userId;
    debugPrint('🔍 オーナーID: $ownerId');

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ファミリー招待QR'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<SubscriptionService>(
            builder: (context, sub, _) {
              final members = sub.familyMembers;
              final max = sub.getMaxFamilyMembers();
              final currentUserId = auth.userId;
              final isFamilyPlanActive =
                  sub.currentPlan?.isFamilyPlan == true &&
                      sub.isSubscriptionActive;

              // ファミリープランが有効な場合のみオーナー（自分）を含める
              final allMembers =
                  isFamilyPlanActive ? [currentUserId, ...members] : members;

              // ファミリーメンバーの表示名を読み込み（非同期で実行）
              if (members.isNotEmpty) {
                _loadFamilyMemberDisplayNames(members);
              }

              debugPrint(
                  '🔍 ファミリーメンバー表示: オーナー=$currentUserId, メンバー=$members, 全員=$allMembers, ファミリープラン有効=$isFamilyPlanActive');
              debugPrint('🔍 現在の表示名マップ: $_displayNames');

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 情報カード
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surface,
                            theme.colorScheme.surface.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow
                                .withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isFamilyPlanActive
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.1)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.family_restroom,
                              color: isFamilyPlanActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFamilyPlanActive
                                      ? 'ファミリー招待'
                                      : 'ファミリープランが必要',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isFamilyPlanActive
                                      ? 'このQRを家族が読み取ると、ファミリープランの特典を共有できます（最大$max人）'
                                      : 'ファミリープランに加入すると、家族と特典を共有できます',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // QRコードエリア
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.surface,
                                theme.colorScheme.surface
                                    .withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: isFamilyPlanActive
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 32,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: 220,
                                      height: 220,
                                      child: PrettyQrView.data(
                                        data: _buildQrPayload(ownerId),
                                        decoration: const PrettyQrDecoration(
                                          shape: PrettyQrSmoothSymbol(
                                            roundFactor: 0,
                                          ),
                                        ),
                                        errorCorrectLevel:
                                            QrErrorCorrectLevel.M,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'スキャンして参加',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.lock,
                                        size: 48,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'ファミリープランが必要',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ファミリープランに加入すると\nQRコードが表示されます',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // メンバー情報
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surface,
                            theme.colorScheme.surface.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow
                                .withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.people,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'メンバー数: ${allMembers.length} / $max',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (allMembers.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.group,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '参加中のメンバー',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...allMembers
                                      .map((m) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: m == currentUserId
                                                        ? theme
                                                            .colorScheme.primary
                                                            .withValues(
                                                                alpha: 0.1)
                                                        : theme.colorScheme
                                                            .onSurface
                                                            .withValues(
                                                                alpha: 0.05),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    m == currentUserId
                                                        ? Icons.person_pin
                                                        : Icons.person,
                                                    size: 14,
                                                    color: m == currentUserId
                                                        ? theme
                                                            .colorScheme.primary
                                                        : theme.colorScheme
                                                            .onSurface
                                                            .withValues(
                                                                alpha: 0.7),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    _getDisplayName(
                                                        m, currentUserId),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: m ==
                                                              currentUserId
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: theme
                                                          .colorScheme.onSurface
                                                          .withValues(
                                                              alpha: m ==
                                                                      currentUserId
                                                                  ? 1.0
                                                                  : 0.8),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// ユーザーの表示名を取得
  String _getDisplayName(String userId, String currentUserId) {
    debugPrint('🔍 表示名取得: userId=$userId, currentUserId=$currentUserId');
    debugPrint('🔍 現在の表示名マップ: $_displayNames');

    final displayName = _displayNames[userId];
    debugPrint('🔍 取得した表示名: $displayName');

    if (displayName != null && displayName.isNotEmpty) {
      final result =
          userId == currentUserId ? '$displayName (あなた)' : displayName;
      debugPrint('🔍 表示名結果: $result');
      return result;
    }

    // 表示名が見つからない場合は短縮されたユーザーIDを返す
    final shortId = _getShortUserId(userId);
    final result = userId == currentUserId ? '$shortId (あなた)' : shortId;
    debugPrint('🔍 短縮ID結果: $result');
    return result;
  }

  /// ユーザーIDを短縮して表示用に整形
  String _getShortUserId(String userId) {
    if (userId.length <= 8) {
      return userId;
    }
    return '${userId.substring(0, 4)}...${userId.substring(userId.length - 4)}';
  }
}
