// Repository/Manager間で共有する状態を集約し、コールバック注入を簡素化
import 'package:flutter/foundation.dart';

/// DataProvider配下のRepository/Managerが共有する状態クラス。
/// コールバック関数の個別注入を排除し、依存関係を明確化する。
///
/// ### notifyListeners の呼び出しパターン
/// - 各Repository/Managerが `_state.notifyListeners()` を呼び出してUI更新をトリガーする
/// - `isBatchUpdating` が `true` の間は、RealtimeSyncManager等での大量更新時に
///   notifyListeners() の呼び出しを抑止し、更新完了後に一度だけ通知する
/// - ItemRepository・RealtimeSyncManager がバッチ更新フラグを制御する
class DataProviderState {
  DataProviderState({required VoidCallback notifyListeners})
      : _notifyListeners = notifyListeners;

  final VoidCallback _notifyListeners;

  bool isSynced = false;

  /// バッチ更新中フラグ。trueの間はnotifyListenersの呼び出しを抑止し、
  /// 複数の連続的なデータ変更が完了した後に一度だけUI更新を行う。
  /// ItemRepository.updateItem/RealtimeSyncManager._handleSnapshotでセット/クリアされる。
  bool isBatchUpdating = false;

  bool shouldUseAnonymousSession = false;

  void notifyListeners() => _notifyListeners();
}
