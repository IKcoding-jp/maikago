import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data_service.dart';
import '../models/shop.dart';
import '../models/list.dart';
import '../drawer/settings/settings_persistence.dart';

/// ショップ（タブ）のCRUD操作を担当するサービス
///
/// DataProviderから楽観的更新以外のビジネスロジックを分離し、
/// テスト容易性と再利用性を向上させる。
class ShopService {
  final DataService _dataService;

  ShopService({DataService? dataService})
      : _dataService = dataService ?? DataService();

  /// 新しいショップを作成（IDとタイムスタンプを付与）
  Shop createNewShop(Shop shop, int existingShopCount) {
    if (shop.id == '0') {
      // デフォルトショップの場合はIDをそのまま使用
      return shop.copyWith(createdAt: DateTime.now());
    }

    return shop.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_$existingShopCount',
      createdAt: DateTime.now(),
    );
  }

  /// ショップをFirestoreに保存
  Future<void> saveShop(Shop shop, {required bool isAnonymous}) async {
    try {
      await _dataService.saveShop(shop, isAnonymous: isAnonymous);
      debugPrint('✅ ショップ保存完了: ${shop.name}');
    } catch (e) {
      debugPrint('❌ Firebase保存エラー: $e');
      rethrow;
    }
  }

  /// ショップを更新
  Future<void> updateShop(Shop shop, {required bool isAnonymous}) async {
    try {
      await _dataService.updateShop(shop, isAnonymous: isAnonymous);
    } catch (e) {
      debugPrint('Firebase更新エラー: $e');
      _throwUserFriendlyError(e, 'ショップの更新');
    }
  }

  /// ショップを削除
  Future<void> deleteShop(String shopId, {required bool isAnonymous}) async {
    try {
      await _dataService.deleteShop(shopId, isAnonymous: isAnonymous);

      // デフォルトショップが削除された場合は状態を記録
      if (shopId == '0') {
        await SettingsPersistence.saveDefaultShopDeleted(true);
        debugPrint('デフォルトショップの削除を記録しました');
      }
    } catch (e) {
      debugPrint('Firebase削除エラー: $e');
      _throwUserFriendlyError(e, 'ショップの削除');
    }
  }

  /// ショップリストから削除対象のタブ参照を削除
  ///
  /// 他のタブのsharedTabsから削除対象のIDを除去し、
  /// 共有相手がいなくなった場合は共有マークも削除
  List<Shop> removeSharedTabReferences(List<Shop> shops, String deletedShopId) {
    final result = <Shop>[];

    for (final shop in shops) {
      if (shop.id == deletedShopId) continue;

      if (shop.sharedTabs.contains(deletedShopId)) {
        final updatedSharedTabs =
            shop.sharedTabs.where((id) => id != deletedShopId).toList();

        result.add(shop.copyWith(
          sharedTabs: updatedSharedTabs,
          clearSharedGroupId: updatedSharedTabs.isEmpty,
          clearSharedGroupIcon: updatedSharedTabs.isEmpty,
        ));

        debugPrint('タブ ${shop.id} から削除対象 $deletedShopId への参照を削除');
      } else {
        result.add(shop);
      }
    }

    return result;
  }

  /// デフォルトショップを作成
  Shop createDefaultShop() {
    return Shop(
      id: '0',
      name: 'デフォルト',
      items: [],
      createdAt: DateTime.now(),
    );
  }

  /// デフォルトショップが必要かどうかを確認
  Future<bool> shouldCreateDefaultShop(List<Shop> existingShops) async {
    final hasDefaultShop = existingShops.any((shop) => shop.id == '0');
    if (hasDefaultShop) return false;

    final isDeleted = await SettingsPersistence.loadDefaultShopDeleted();
    return !isDeleted;
  }

  /// ショップの全アイテムをクリア
  Future<void> clearAllItems(
    Shop shop,
    List<ListItem> itemsToDelete, {
    required bool isAnonymous,
    int batchSize = 5,
  }) async {
    // アイテムを並列で削除
    for (int i = 0; i < itemsToDelete.length; i += batchSize) {
      final batch = itemsToDelete.skip(i).take(batchSize);
      await Future.wait(
        batch.map((item) => _dataService.deleteItem(
              item.id,
              isAnonymous: isAnonymous,
            )),
      );
    }

    // ショップを更新
    await updateShop(
      shop.copyWith(items: []),
      isAnonymous: isAnonymous,
    );

    debugPrint('✅ ショップ ${shop.name} の全アイテムをクリア');
  }

  /// ユーザーフレンドリーなエラーメッセージを投げる
  void _throwUserFriendlyError(dynamic e, String operation) {
    if (e.toString().contains('not-found')) {
      throw Exception('ショップが見つかりませんでした。再度お試しください。');
    } else if (e.toString().contains('permission-denied')) {
      throw Exception('権限がありません。ログイン状態を確認してください。');
    } else {
      throw Exception('$operationに失敗しました。ネットワーク接続を確認してください。');
    }
  }
}
