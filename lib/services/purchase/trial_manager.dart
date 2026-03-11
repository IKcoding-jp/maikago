import 'dart:async';

import 'package:maikago/services/debug_service.dart';

/// 体験期間の状態を保持するデータクラス
class TrialState {
  const TrialState({
    this.isActive = false,
    this.isEverStarted = false,
    this.startDate,
    this.endDate,
  });

  final bool isActive;
  final bool isEverStarted;
  final DateTime? startDate;
  final DateTime? endDate;

  TrialState copyWith({
    bool? isActive,
    bool? isEverStarted,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TrialState(
      isActive: isActive ?? this.isActive,
      isEverStarted: isEverStarted ?? this.isEverStarted,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

/// 体験期間の残り時間を計算
Duration? calculateTrialRemainingDuration(TrialState state) {
  if (!state.isActive || state.endDate == null) return null;
  final now = DateTime.now();
  final remaining = state.endDate!.difference(now);
  return remaining.isNegative ? Duration.zero : remaining;
}

/// 体験期間のビジネスロジックを管理するクラス
///
/// 体験期間の開始・終了・タイマー管理を担当する。
/// 永続化やUI通知は [onStateChanged] コールバック経由で親に委譲する。
class TrialManager {
  TrialManager({required this.onStateChanged});

  /// 状態変更時に呼ばれるコールバック（永続化・notifyListeners用）
  final void Function() onStateChanged;

  // 体験期間の状態
  bool _isTrialActive = false;
  DateTime? _trialStartDate;
  DateTime? _trialEndDate;
  Timer? _trialEndTimer;
  bool _isTrialEverStarted = false;

  // Getters
  bool get isTrialActive => _isTrialActive;
  bool get isTrialEverStarted => _isTrialEverStarted;
  DateTime? get trialStartDate => _trialStartDate;
  DateTime? get trialEndDate => _trialEndDate;

  /// 体験期間の残り時間を取得
  Duration? get trialRemainingDuration {
    if (!_isTrialActive || _trialEndDate == null) return null;
    final now = DateTime.now();
    final remaining = _trialEndDate!.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// ローカルストレージから読み込んだ値で状態を復元
  void restoreState({
    required bool isActive,
    required bool isEverStarted,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _isTrialActive = isActive;
    _isTrialEverStarted = isEverStarted;
    _trialStartDate = startDate;
    _trialEndDate = endDate;
  }

  /// Firestoreから読み込んだ体験開始済みフラグを適用
  void markAsEverStarted() {
    _isTrialEverStarted = true;
  }

  /// 体験期間を開始
  ///
  /// 既に体験期間が開始されたことがあるデバイスでは開始を拒否する。
  /// 戻り値: 開始できたかどうか
  bool startTrial(int trialDays) {
    // デバイスフィンガープリントベースでの二重開始チェック
    if (_isTrialEverStarted) {
      return false; // 体験期間開始を拒否
    }

    _isTrialActive = true;
    _isTrialEverStarted = true;
    _trialStartDate = DateTime.now();
    _trialEndDate = _trialStartDate!.add(Duration(days: trialDays));

    startTrialTimer();
    onStateChanged();

    DebugService().logInfo('体験期間開始: $trialDays日間');
    return true;
  }

  /// 体験期間を終了
  void endTrial() {
    _isTrialActive = false;
    _trialStartDate = null;
    _trialEndDate = null;

    cancelTrialTimer();
    onStateChanged();

    DebugService().logInfo('体験期間終了');
  }

  /// 体験期間が期限切れかチェックし、期限切れなら終了する
  void checkAndExpireIfNeeded() {
    if (_isTrialActive &&
        _trialEndDate != null &&
        DateTime.now().isAfter(_trialEndDate!)) {
      endTrial();
    }
  }

  /// 体験期間終了を監視するタイマーを開始
  void startTrialTimer() {
    cancelTrialTimer();
    if (_isTrialActive && _trialEndDate != null) {
      final remainingDuration = _trialEndDate!.difference(DateTime.now());
      if (remainingDuration.isNegative) {
        endTrial();
        return;
      }
      _trialEndTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isTrialActive || _trialEndDate == null) {
          cancelTrialTimer();
          return;
        }
        if (DateTime.now().isAfter(_trialEndDate!)) {
          endTrial();
        } else {
          onStateChanged();
        }
      });
    }
  }

  /// 体験期間終了タイマーをキャンセル
  void cancelTrialTimer() {
    _trialEndTimer?.cancel();
    _trialEndTimer = null;
  }

  /// リソースを解放
  void dispose() {
    cancelTrialTimer();
  }
}
