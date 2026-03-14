import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maikago/services/purchase/purchase_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loadFromLocalStorage', () {
    test('空のストレージからデフォルト値を返す', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = PurchasePersistence();

      final data = await persistence.loadFromLocalStorage();

      expect(data.userPremiumStatus, isEmpty);
      expect(data.isTrialActive, false);
      expect(data.isTrialEverStarted, false);
      expect(data.trialStartDate, isNull);
      expect(data.trialEndDate, isNull);
    });

    test('premium_status_mapから購入状態を復元', () async {
      final statusMap = {'user123': true, 'user456': false};
      SharedPreferences.setMockInitialValues({
        'premium_status_map': jsonEncode(statusMap),
      });
      final persistence = PurchasePersistence();

      final data = await persistence.loadFromLocalStorage();

      expect(data.userPremiumStatus['user123'], true);
      expect(data.userPremiumStatus['user456'], false);
    });

    test('レガシーキー（premium_unlocked）からの移行', () async {
      SharedPreferences.setMockInitialValues({
        'premium_unlocked': true,
      });
      final persistence = PurchasePersistence();

      final data = await persistence.loadFromLocalStorage();

      expect(data.userPremiumStatus['_legacy_default'], true);
    });

    test('premium_status_mapが存在する場合はレガシーキーを無視', () async {
      SharedPreferences.setMockInitialValues({
        'premium_status_map': jsonEncode({'user1': true}),
        'premium_unlocked': false,
      });
      final persistence = PurchasePersistence();

      final data = await persistence.loadFromLocalStorage();

      expect(data.userPremiumStatus.containsKey('_legacy_default'), false);
      expect(data.userPremiumStatus['user1'], true);
    });

    test('体験期間情報を復元', () async {
      final now = DateTime.now();
      final startTimestamp = now.millisecondsSinceEpoch;
      final endTimestamp =
          now.add(const Duration(days: 7)).millisecondsSinceEpoch;

      SharedPreferences.setMockInitialValues({
        'trial_active': true,
        'trial_ever_started': true,
        'trial_start_timestamp': startTimestamp,
        'trial_end_timestamp': endTimestamp,
      });
      final persistence = PurchasePersistence();

      final data = await persistence.loadFromLocalStorage();

      expect(data.isTrialActive, true);
      expect(data.isTrialEverStarted, true);
      expect(data.trialStartDate, isNotNull);
      expect(data.trialEndDate, isNotNull);
      expect(
        data.trialStartDate!.millisecondsSinceEpoch,
        startTimestamp,
      );
      expect(
        data.trialEndDate!.millisecondsSinceEpoch,
        endTimestamp,
      );
    });

    test('体験期間のタイムスタンプがnullの場合', () async {
      SharedPreferences.setMockInitialValues({
        'trial_active': true,
        'trial_ever_started': true,
      });
      final persistence = PurchasePersistence();

      final data = await persistence.loadFromLocalStorage();

      expect(data.isTrialActive, true);
      expect(data.trialStartDate, isNull);
      expect(data.trialEndDate, isNull);
    });
  });

  group('saveToLocalStorage', () {
    test('購入状態を保存できる', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = PurchasePersistence();

      await persistence.saveToLocalStorage(
        userPremiumStatus: {'user1': true},
        isTrialActive: false,
        isTrialEverStarted: false,
      );

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('premium_status_map');
      expect(saved, isNotNull);

      final decoded = jsonDecode(saved!) as Map<String, dynamic>;
      expect(decoded['user1'], true);
    });

    test('体験期間情報を保存できる', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = PurchasePersistence();
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 3, 8);

      await persistence.saveToLocalStorage(
        userPremiumStatus: {},
        isTrialActive: true,
        isTrialEverStarted: true,
        trialStartDate: start,
        trialEndDate: end,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('trial_active'), true);
      expect(prefs.getBool('trial_ever_started'), true);
      expect(
        prefs.getInt('trial_start_timestamp'),
        start.millisecondsSinceEpoch,
      );
      expect(
        prefs.getInt('trial_end_timestamp'),
        end.millisecondsSinceEpoch,
      );
    });

    test('trialStartDate/trialEndDateがnullの場合は保存しない', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = PurchasePersistence();

      await persistence.saveToLocalStorage(
        userPremiumStatus: {},
        isTrialActive: false,
        isTrialEverStarted: false,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('trial_start_timestamp'), isNull);
      expect(prefs.getInt('trial_end_timestamp'), isNull);
    });
  });

  group('保存→復元の往復テスト', () {
    test('購入状態の往復', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = PurchasePersistence();
      final originalStatus = {'user1': true, 'user2': false};

      await persistence.saveToLocalStorage(
        userPremiumStatus: originalStatus,
        isTrialActive: false,
        isTrialEverStarted: false,
      );

      final loaded = await persistence.loadFromLocalStorage();

      expect(loaded.userPremiumStatus, originalStatus);
    });

    test('体験期間情報の往復', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = PurchasePersistence();
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 3, 8);

      await persistence.saveToLocalStorage(
        userPremiumStatus: {},
        isTrialActive: true,
        isTrialEverStarted: true,
        trialStartDate: start,
        trialEndDate: end,
      );

      final loaded = await persistence.loadFromLocalStorage();

      expect(loaded.isTrialActive, true);
      expect(loaded.isTrialEverStarted, true);
      expect(
        loaded.trialStartDate!.millisecondsSinceEpoch,
        start.millisecondsSinceEpoch,
      );
      expect(
        loaded.trialEndDate!.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      );
    });
  });

  group('LocalPurchaseData', () {
    test('コンストラクタのデフォルト値', () {
      const data = LocalPurchaseData(
        userPremiumStatus: {},
        isTrialActive: false,
        isTrialEverStarted: false,
      );

      expect(data.trialStartDate, isNull);
      expect(data.trialEndDate, isNull);
    });
  });

  group('FirestorePurchaseData', () {
    test('コンストラクタ', () {
      const data = FirestorePurchaseData(
        isPremium: true,
        isTrialEverStarted: false,
      );

      expect(data.isPremium, true);
      expect(data.isTrialEverStarted, false);
    });
  });
}
