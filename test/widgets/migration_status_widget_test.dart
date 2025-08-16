import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maikago/widgets/migration_status_widget.dart';
import 'package:maikago/services/subscription_integration_service.dart';

// モッククラスの生成
@GenerateMocks([SubscriptionIntegrationService])
import 'migration_status_widget_test.mocks.dart';

void main() {
  group('MigrationStatusWidget Tests', () {
    late MockSubscriptionIntegrationService mockSubscriptionService;

    setUp(() {
      mockSubscriptionService = MockSubscriptionIntegrationService();
    });

    Widget createTestWidget({
      VoidCallback? onUpgradePressed,
      VoidCallback? onMigrationComplete,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider<SubscriptionIntegrationService>.value(
          value: mockSubscriptionService,
          child: Scaffold(
            body: MigrationStatusWidget(
              onUpgradePressed: onUpgradePressed,
              onMigrationComplete: onMigrationComplete,
            ),
          ),
        ),
      );
    }

    group('表示テスト', () {
      testWidgets('サブスクリプション有効時は表示されない', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': true,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': true,
          'hasDonationBenefits': false,
        });

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(MigrationStatusWidget), findsOneWidget);
        expect(find.byType(Card), findsNothing);
      });

      testWidgets('新規ユーザー時の表示が正しい', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': true,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションでより多くの機能をお楽しみください');

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('新規ユーザー'), findsOneWidget);
        expect(find.text('サブスクリプションでより多くの機能をお楽しみください'), findsOneWidget);
        expect(find.text('サブスクリプションにアップグレード'), findsOneWidget);
      });

      testWidgets('既存寄付者時の表示が正しい', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': true,
          'migrationCompleted': false,
          'isNewUser': false,
          'shouldRecommendSubscription': false,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': true,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('既存の寄付特典が引き続き有効です');

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('既存寄付者'), findsOneWidget);
        expect(find.text('既存の寄付特典が引き続き有効です'), findsOneWidget);
        expect(find.text('移行完了'), findsOneWidget);
      });

      testWidgets('移行案内時の表示が正しい', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': false,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションに移行して特典を継続しましょう');

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('移行案内'), findsOneWidget);
        expect(find.text('サブスクリプションに移行して特典を継続しましょう'), findsOneWidget);
        expect(find.text('サブスクリプションにアップグレード'), findsOneWidget);
      });
    });

    group('インタラクションテスト', () {
      testWidgets('アップグレードボタンのタップが正しく動作する', (WidgetTester tester) async {
        bool upgradePressed = false;

        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': true,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションでより多くの機能をお楽しみください');

        await tester.pumpWidget(
          createTestWidget(onUpgradePressed: () => upgradePressed = true),
        );

        await tester.tap(find.text('サブスクリプションにアップグレード'));
        await tester.pump();

        expect(upgradePressed, true);
      });

      testWidgets('移行完了ボタンのタップが正しく動作する', (WidgetTester tester) async {
        bool migrationCompleted = false;

        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': true,
          'migrationCompleted': false,
          'isNewUser': false,
          'shouldRecommendSubscription': false,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': true,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('既存の寄付特典が引き続き有効です');
        when(
          mockSubscriptionService.completeMigration(),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          createTestWidget(
            onMigrationComplete: () => migrationCompleted = true,
          ),
        );

        await tester.tap(find.text('移行完了'));
        await tester.pump();

        verify(mockSubscriptionService.completeMigration()).called(1);
        expect(migrationCompleted, true);
      });
    });

    group('状態表示テスト', () {
      testWidgets('現在の状態が正しく表示される', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': true,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションでより多くの機能をお楽しみください');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('現在の状態'), findsOneWidget);
        expect(find.text('プラン'), findsOneWidget);
        expect(find.text('Free'), findsOneWidget);
        expect(find.text('寄付特典'), findsOneWidget);
        expect(find.text('なし'), findsOneWidget);
        expect(find.text('サブスクリプション'), findsOneWidget);
        expect(find.text('なし'), findsAtLeastNWidgets(1));
        expect(find.text('移行完了'), findsOneWidget);
        expect(find.text('未完了'), findsOneWidget);
      });
    });

    group('アイコンと色のテスト', () {
      testWidgets('新規ユーザーのアイコンと色が正しい', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': true,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションでより多くの機能をお楽しみください');

        await tester.pumpWidget(createTestWidget());

        final iconFinder = find.byIcon(Icons.person_add);
        expect(iconFinder, findsOneWidget);

        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.color, Colors.blue);
      });

      testWidgets('既存寄付者のアイコンと色が正しい', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': true,
          'migrationCompleted': false,
          'isNewUser': false,
          'shouldRecommendSubscription': false,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': true,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('既存の寄付特典が引き続き有効です');

        await tester.pumpWidget(createTestWidget());

        final iconFinder = find.byIcon(Icons.favorite);
        expect(iconFinder, findsOneWidget);

        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.color, Colors.green);
      });

      testWidgets('移行案内のアイコンと色が正しい', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': false,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションに移行して特典を継続しましょう');

        await tester.pumpWidget(createTestWidget());

        final iconFinder = find.byIcon(Icons.info);
        expect(iconFinder, findsOneWidget);

        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.color, Colors.orange);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('サービスがnullの場合のエラーハンドリング', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MigrationStatusWidget())),
        );

        // エラーが発生してもクラッシュしないことを確認
        expect(find.byType(MigrationStatusWidget), findsOneWidget);
      });

      testWidgets('移行完了処理でエラーが発生した場合のハンドリング', (WidgetTester tester) async {
        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': true,
          'migrationCompleted': false,
          'isNewUser': false,
          'shouldRecommendSubscription': false,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': true,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('既存の寄付特典が引き続き有効です');
        when(
          mockSubscriptionService.completeMigration(),
        ).thenThrow(Exception('移行処理でエラーが発生しました'));

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('移行完了'));
        await tester.pump();

        // エラーが発生してもアプリがクラッシュしないことを確認
        expect(find.byType(MigrationStatusWidget), findsOneWidget);
      });
    });

    group('レスポンシブデザインテスト', () {
      testWidgets('小さい画面サイズでの表示が正しい', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(320, 480);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': true,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションでより多くの機能をお楽しみください');

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('新規ユーザー'), findsOneWidget);

        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      });

      testWidgets('大きい画面サイズでの表示が正しい', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        when(mockSubscriptionService.getMigrationStatus()).thenReturn({
          'isLegacyDonor': false,
          'migrationCompleted': false,
          'isNewUser': true,
          'shouldRecommendSubscription': true,
          'currentPlan': 'Free',
          'hasSubscription': false,
          'hasDonationBenefits': false,
        });
        when(
          mockSubscriptionService.getMigrationRecommendationMessage(),
        ).thenReturn('サブスクリプションでより多くの機能をお楽しみください');

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('新規ユーザー'), findsOneWidget);

        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      });
    });
  });
}
