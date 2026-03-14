import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/services/purchase/trial_manager.dart';

void main() {
  late TrialManager trialManager;
  late int stateChangedCount;

  setUp(() {
    stateChangedCount = 0;
    trialManager = TrialManager(
      onStateChanged: () => stateChangedCount++,
    );
  });

  tearDown(() {
    trialManager.dispose();
  });

  group('初期状態', () {
    test('体験期間が非アクティブ', () {
      expect(trialManager.isTrialActive, false);
    });

    test('体験期間が未開始', () {
      expect(trialManager.isTrialEverStarted, false);
    });

    test('開始日がnull', () {
      expect(trialManager.trialStartDate, isNull);
    });

    test('終了日がnull', () {
      expect(trialManager.trialEndDate, isNull);
    });

    test('残り時間がnull', () {
      expect(trialManager.trialRemainingDuration, isNull);
    });
  });

  group('startTrial', () {
    test('正常に体験期間を開始できる', () {
      final result = trialManager.startTrial(7);

      expect(result, true);
      expect(trialManager.isTrialActive, true);
      expect(trialManager.isTrialEverStarted, true);
      expect(trialManager.trialStartDate, isNotNull);
      expect(trialManager.trialEndDate, isNotNull);
    });

    test('開始日と終了日の差が指定日数', () {
      trialManager.startTrial(7);

      final diff =
          trialManager.trialEndDate!.difference(trialManager.trialStartDate!);
      expect(diff.inDays, 7);
    });

    test('onStateChangedコールバックが呼ばれる', () {
      trialManager.startTrial(7);

      expect(stateChangedCount, 1);
    });

    test('二重開始が防止される（isTrialEverStarted）', () {
      trialManager.startTrial(7);
      stateChangedCount = 0;

      final result = trialManager.startTrial(7);

      expect(result, false);
      expect(stateChangedCount, 0);
    });

    test('markAsEverStarted後は開始が拒否される', () {
      trialManager.markAsEverStarted();

      final result = trialManager.startTrial(7);

      expect(result, false);
      expect(trialManager.isTrialActive, false);
    });

    test('異なる日数で開始できる', () {
      trialManager.startTrial(3);

      final diff =
          trialManager.trialEndDate!.difference(trialManager.trialStartDate!);
      expect(diff.inDays, 3);
    });
  });

  group('endTrial', () {
    test('体験期間を終了できる', () {
      trialManager.startTrial(7);
      stateChangedCount = 0;

      trialManager.endTrial();

      expect(trialManager.isTrialActive, false);
      expect(trialManager.trialStartDate, isNull);
      expect(trialManager.trialEndDate, isNull);
      expect(stateChangedCount, 1);
    });

    test('終了後もisTrialEverStartedはtrueのまま', () {
      trialManager.startTrial(7);
      trialManager.endTrial();

      expect(trialManager.isTrialEverStarted, true);
    });
  });

  group('checkAndExpireIfNeeded', () {
    test('期限内なら終了しない', () {
      trialManager.startTrial(7);
      stateChangedCount = 0;

      trialManager.checkAndExpireIfNeeded();

      expect(trialManager.isTrialActive, true);
      expect(stateChangedCount, 0);
    });

    test('期限切れなら自動終了する', () {
      // 過去の日付で状態を復元して期限切れをシミュレート
      trialManager.restoreState(
        isActive: true,
        isEverStarted: true,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      trialManager.checkAndExpireIfNeeded();

      expect(trialManager.isTrialActive, false);
      expect(stateChangedCount, 1);
    });

    test('非アクティブ時は何もしない', () {
      trialManager.checkAndExpireIfNeeded();

      expect(trialManager.isTrialActive, false);
      expect(stateChangedCount, 0);
    });
  });

  group('restoreState', () {
    test('状態を復元できる', () {
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 8);

      trialManager.restoreState(
        isActive: true,
        isEverStarted: true,
        startDate: startDate,
        endDate: endDate,
      );

      expect(trialManager.isTrialActive, true);
      expect(trialManager.isTrialEverStarted, true);
      expect(trialManager.trialStartDate, startDate);
      expect(trialManager.trialEndDate, endDate);
    });

    test('onStateChangedは呼ばれない', () {
      trialManager.restoreState(
        isActive: true,
        isEverStarted: true,
      );

      expect(stateChangedCount, 0);
    });
  });

  group('markAsEverStarted', () {
    test('体験開始済みフラグを設定できる', () {
      trialManager.markAsEverStarted();

      expect(trialManager.isTrialEverStarted, true);
      expect(trialManager.isTrialActive, false);
    });
  });

  group('trialRemainingDuration', () {
    test('アクティブな体験期間の残り時間が計算される', () {
      trialManager.startTrial(7);

      final remaining = trialManager.trialRemainingDuration;

      expect(remaining, isNotNull);
      // 開始直後なのでほぼ7日
      expect(remaining!.inDays, greaterThanOrEqualTo(6));
      expect(remaining.inDays, lessThanOrEqualTo(7));
    });

    test('非アクティブ時はnull', () {
      expect(trialManager.trialRemainingDuration, isNull);
    });

    test('期限切れ時はDuration.zero', () {
      trialManager.restoreState(
        isActive: true,
        isEverStarted: true,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      final remaining = trialManager.trialRemainingDuration;

      expect(remaining, Duration.zero);
    });
  });

  group('calculateTrialRemainingDuration（トップレベル関数）', () {
    test('アクティブな状態で残り時間を計算', () {
      final state = TrialState(
        isActive: true,
        isEverStarted: true,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final remaining = calculateTrialRemainingDuration(state);

      expect(remaining, isNotNull);
      expect(remaining!.inDays, greaterThanOrEqualTo(6));
    });

    test('非アクティブな状態でnull', () {
      const state = TrialState(isActive: false);

      expect(calculateTrialRemainingDuration(state), isNull);
    });

    test('endDateがnullでnull', () {
      const state = TrialState(isActive: true);

      expect(calculateTrialRemainingDuration(state), isNull);
    });

    test('期限切れでDuration.zero', () {
      final state = TrialState(
        isActive: true,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(calculateTrialRemainingDuration(state), Duration.zero);
    });
  });

  group('TrialState', () {
    test('デフォルト値', () {
      const state = TrialState();

      expect(state.isActive, false);
      expect(state.isEverStarted, false);
      expect(state.startDate, isNull);
      expect(state.endDate, isNull);
    });

    test('copyWithで値を更新', () {
      const state = TrialState();
      final updated = state.copyWith(isActive: true, isEverStarted: true);

      expect(updated.isActive, true);
      expect(updated.isEverStarted, true);
    });

    test('copyWithでstartDateをクリア', () {
      final state = TrialState(startDate: DateTime.now());
      final updated = state.copyWith(clearStartDate: true);

      expect(updated.startDate, isNull);
    });

    test('copyWithでendDateをクリア', () {
      final state = TrialState(endDate: DateTime.now());
      final updated = state.copyWith(clearEndDate: true);

      expect(updated.endDate, isNull);
    });
  });

  group('タイマー管理', () {
    test('startTrialTimerが期限切れ時にendTrialを呼ぶ', () async {
      // 非常に短い期限の体験期間を設定
      trialManager.restoreState(
        isActive: true,
        isEverStarted: true,
        startDate: DateTime.now().subtract(const Duration(seconds: 2)),
        endDate: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      trialManager.startTrialTimer();

      // タイマーが発火するのを待つ（1秒間隔のタイマー）
      await Future.delayed(const Duration(seconds: 2));

      expect(trialManager.isTrialActive, false);
    });

    test('cancelTrialTimerでタイマーが停止する', () {
      trialManager.startTrial(7);

      trialManager.cancelTrialTimer();

      // キャンセル後もアクティブ状態は維持される
      expect(trialManager.isTrialActive, true);
    });

    test('disposeでタイマーが解放される', () {
      trialManager.startTrial(7);

      // dispose後にエラーが出ないことを確認
      trialManager.dispose();

      expect(trialManager.isTrialActive, true);
    });
  });
}
