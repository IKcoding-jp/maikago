import 'package:flutter/material.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/donation_service.dart';

/// 寄付画面のヘッダーウィジェット
class DonationHeader extends StatelessWidget {
  const DonationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'まいカゴを応援してください',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'あなたの寄付が、アプリの未来を創ります',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 寄付履歴ウィジェット
class DonationHistory extends StatelessWidget {
  const DonationHistory({super.key, required this.donationService});

  final DonationService donationService;

  @override
  Widget build(BuildContext context) {
    if (!donationService.hasDonated) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '寄付履歴',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '合計寄付金額',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${donationService.totalDonationAmount.toString()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '寄付回数',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donationService.donationCount}回',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '最終寄付日: ${donationService.lastDonationDate != null ? _formatDate(donationService.lastDonationDate!) : '不明'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// 日付をフォーマットするヘルパーメソッド
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

/// 金額選択ウィジェット
class DonationAmountSelection extends StatelessWidget {
  const DonationAmountSelection({
    super.key,
    required this.selectedAmount,
    required this.presetAmounts,
    required this.onAmountSelected,
  });

  final int selectedAmount;
  final List<int> presetAmounts;
  final ValueChanged<int> onAmountSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '寄付金額を選択',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPresetAmounts(context),
        ],
      ),
    );
  }

  /// プリセット金額ボタン群
  Widget _buildPresetAmounts(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presetAmounts.map((amount) {
        final isSelected = selectedAmount == amount;

        return GestureDetector(
          onTap: () => onAmountSelected(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '¥${amount.toString()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 開発者メッセージウィジェット
class DonationDeveloperMessage extends StatelessWidget {
  const DonationDeveloperMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '開発者からのメッセージ',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),
          const SizedBox(height: 16),
          Text(
            'このアプリは、エンジニアでもなんでもない人間が、たった一人で作っています。\n'
            '専門的な知識があるわけでもなく、時間を見つけては少しずつ開発してきました。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            '正直、アプリを作って維持していくにはお金も時間もかかります。\n'
            'iOS版もリリースしたいと考えているのですが、MacBookが必要でお金がないため、まだ実現できていません。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            'もしこのアプリが少しでも役に立ったと感じてもらえたら、応援の気持ちとして寄付してもらえると本当に励みになります。\n'
            'もちろん、金額に関係なく気持ちだけでも嬉しいです。\n'
            'ご支援、心からありがとうございます。今後もこつこつ改善を重ねていきます。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// 寄付アクションボタンウィジェット
class DonationActionButton extends StatelessWidget {
  const DonationActionButton({
    super.key,
    required this.selectedAmount,
    required this.onDonate,
  });

  final int selectedAmount;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    final isValidAmount = selectedAmount >= 300;

    return Column(
      children: [
        Center(
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isValidAmount
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: isValidAmount
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
            ),
            child: ElevatedButton(
              onPressed: isValidAmount ? onDonate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: isValidAmount
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '¥${selectedAmount.toString()} 寄付する',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isValidAmount
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// ローディングインジケーターウィジェット
class DonationLoadingIndicator extends StatelessWidget {
  const DonationLoadingIndicator({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 課金サービス利用不可メッセージウィジェット
class DonationUnavailableMessage extends StatelessWidget {
  const DonationUnavailableMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '課金サービスが利用できません。\nネットワーク接続を確認してください。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 商品未検出メッセージウィジェット
class DonationProductNotFoundMessage extends StatelessWidget {
  const DonationProductNotFoundMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Google Play Consoleで寄付用の課金アイテムが設定されていない可能性があります。\nプロダクトID: ${donationProductIds.join(", ")}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
