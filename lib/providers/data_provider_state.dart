// Repository/Manager間で共有する状態を集約し、コールバック注入を簡素化
import 'package:flutter/foundation.dart';

/// DataProvider配下のRepository/Managerが共有する状態クラス。
/// コールバック関数の個別注入を排除し、依存関係を明確化する。
class DataProviderState {
  DataProviderState({required VoidCallback notifyListeners})
      : _notifyListeners = notifyListeners;

  final VoidCallback _notifyListeners;

  bool isSynced = false;
  bool isBatchUpdating = false;
  bool shouldUseAnonymousSession = false;

  void notifyListeners() => _notifyListeners();
}
