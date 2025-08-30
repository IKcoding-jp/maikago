import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';

class FamilyInviteScreen extends StatefulWidget {
  const FamilyInviteScreen({super.key});

  @override
  State<FamilyInviteScreen> createState() => _FamilyInviteScreenState();
}

class _FamilyInviteScreenState extends State<FamilyInviteScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // パルスアニメーション
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // フェードアニメーション
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // アニメーション開始
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
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

    // テーマに基づいた色の選択
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // グラデーション色の定義
    final gradientColors = isDark
        ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
        : [const Color(0xFF667eea), const Color(0xFF764ba2)];

    final dotColor = isDark ? Colors.white : const Color(0xFF0A285F);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ファミリー招待QR'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
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

              debugPrint(
                  '🔍 ファミリーメンバー表示: オーナー=$currentUserId, メンバー=$members, 全員=$allMembers, ファミリープラン有効=$isFamilyPlanActive');
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 情報カード
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFamilyPlanActive
                                ? [
                                    Colors.orange.shade50,
                                    Colors.orange.shade100,
                                  ]
                                : [
                                    Colors.grey.shade50,
                                    Colors.grey.shade100,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFamilyPlanActive
                                ? Colors.orange.shade200
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isFamilyPlanActive
                                      ? Colors.orange
                                      : Colors.grey)
                                  .withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isFamilyPlanActive
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.family_restroom,
                                color: isFamilyPlanActive
                                    ? Colors.orange
                                    : Colors.grey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                      color: isFamilyPlanActive
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isFamilyPlanActive
                                        ? 'このQRを家族が読み取ると、ファミリープランの特典を共有できます（最大$max人）'
                                        : 'ファミリープランに加入すると、家族と特典を共有できます',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: (isFamilyPlanActive
                                              ? Colors.orange
                                              : Colors.grey)
                                          .shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // QRコードエリア
                    Expanded(
                      child: Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isFamilyPlanActive
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isFamilyPlanActive
                                          ? [
                                              Colors.white,
                                              Colors.grey.shade50,
                                            ]
                                          : [
                                              Colors.grey.shade100,
                                              Colors.grey.shade200,
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isFamilyPlanActive
                                                ? 0.08
                                                : 0.05),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                        spreadRadius: 2,
                                      ),
                                      if (isFamilyPlanActive)
                                        BoxShadow(
                                          color: gradientColors[0]
                                              .withValues(alpha: 0.1),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                    ],
                                    border: Border.all(
                                      color: isFamilyPlanActive
                                          ? gradientColors[0]
                                              .withValues(alpha: 0.2)
                                          : Colors.grey.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: isFamilyPlanActive
                                      ? PrettyQr(
                                          data: _buildQrPayload(ownerId),
                                          size: 280,
                                          roundEdges: false,
                                          elementColor: dotColor,
                                          errorCorrectLevel:
                                              QrErrorCorrectLevel.M,
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lock,
                                              size: 64,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'ファミリープランが必要',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'ファミリープランに加入すると\nQRコードが表示されます',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // メンバー情報
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surface,
                              theme.colorScheme.surface.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: gradientColors[0],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
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
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '参加中のメンバー',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...allMembers
                                        .map((m) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    m == currentUserId
                                                        ? Icons.person_pin
                                                        : Icons.person,
                                                    size: 16,
                                                    color: m == currentUserId
                                                        ? Colors.orange
                                                        : gradientColors[0],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      m == currentUserId
                                                          ? '$m (あなた)'
                                                          : m,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: m ==
                                                                currentUserId
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: theme.colorScheme
                                                            .onSurface
                                                            .withValues(
                                                                alpha: m ==
                                                                        currentUserId
                                                                    ? 1.0
                                                                    : 0.7),
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
}
