import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';

class FamilyInviteScreen extends StatelessWidget {
  const FamilyInviteScreen({super.key});

  String _buildQrPayload(String ownerUserId) {
    // バージョン付きスキームでエンコード
    return 'maikago://family_invite?v=1&owner=$ownerUserId';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final ownerId = auth.userId;

    final Color dotColor = const Color(0xFF0A285F); // 濃紺

    return Scaffold(
      appBar: AppBar(title: const Text('ファミリー招待QR')),
      body: SafeArea(
        child: Consumer<SubscriptionService>(
          builder: (context, sub, _) {
            final members = sub.familyMembers;
            final max = sub.getMaxFamilyMembers();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'このQRを家族が読み取ると、ファミリープランの特典を共有できます（最大$max人）',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24), // 余白を広めに
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: PrettyQr(
                          data: _buildQrPayload(ownerId),
                          size: 260,
                          roundEdges: true,
                          elementColor: dotColor,
                          errorCorrectLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('メンバー数: ${members.length} / $max'),
                  const SizedBox(height: 12),
                  if (members.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('参加中のメンバー（UID）',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...members.map((m) => Text(m)).toList(),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
