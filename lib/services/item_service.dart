import 'dart:async';


import 'package:maikago/services/data_service.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/utils/exceptions.dart';

/// アイテム（商品）のCRUD操作を担当するサービス
///
/// DataProviderから楽観的更新以外のビジネスロジックを分離し、
/// テスト容易性と再利用性を向上させる。
class ItemService {
  ItemService({DataService? dataService})
      : _dataService = dataService ?? DataService();

  final DataService _dataService;

  /// 新しいアイテムを作成
  ///
  /// [item] に新しいIDとタイムスタンプを付与して返す
  ListItem createNewItem(ListItem item, int existingItemCount) {
    return item.copyWith(
      id: item.id.isEmpty
          ? '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_$existingItemCount'
          : item.id,
      createdAt: DateTime.now(),
    );
  }

  /// アイテムをFirestoreに保存
  Future<void> saveItem(ListItem item, {required bool isAnonymous}) async {
    try {
      await _dataService.saveItem(item, isAnonymous: isAnonymous);
      DebugService().log('✅ アイテム保存完了: ${item.name}');
    } catch (e) {
      DebugService().log('❌ Firebase保存エラー: $e');
      rethrow;
    }
  }

  /// アイテムを更新
  Future<void> updateItem(ListItem item, {required bool isAnonymous}) async {
    try {
      await _dataService.updateItem(item, isAnonymous: isAnonymous);
    } catch (e) {
      DebugService().log('Firebase更新エラー: $e');
      _throwUserFriendlyError(e, 'アイテムの更新');
    }
  }

  /// 複数アイテムをバッチで更新（並べ替え処理用）
  Future<void> updateItemsBatch(
    List<ListItem> items, {
    required bool isAnonymous,
    int batchSize = 5,
  }) async {
    try {
      for (int i = 0; i < items.length; i += batchSize) {
        final batch = items.skip(i).take(batchSize);
        await Future.wait(
          batch.map((item) => _dataService.updateItem(
                item,
                isAnonymous: isAnonymous,
              )),
        );
      }
      DebugService().log('✅ バッチ更新完了: ${items.length}個のアイテム');
    } catch (e) {
      DebugService().log('Firebaseバッチ更新エラー: $e');
      rethrow;
    }
  }

  /// アイテムを削除
  Future<void> deleteItem(String itemId, {required bool isAnonymous}) async {
    try {
      await _dataService.deleteItem(itemId, isAnonymous: isAnonymous);
    } catch (e) {
      DebugService().log('Firebase削除エラー: $e');
      _throwUserFriendlyError(e, 'アイテムの削除');
    }
  }

  /// 複数アイテムを一括削除
  Future<void> deleteItems(
    List<String> itemIds, {
    required bool isAnonymous,
    int batchSize = 5,
  }) async {
    try {
      for (int i = 0; i < itemIds.length; i += batchSize) {
        final batch = itemIds.skip(i).take(batchSize).toList();
        await Future.wait(
          batch.map(
            (itemId) => _dataService.deleteItem(
              itemId,
              isAnonymous: isAnonymous,
            ),
          ),
        );
      }
      DebugService().log('✅ 一括削除完了: ${itemIds.length}件');
    } catch (e) {
      DebugService().log('Firebase一括削除エラー: $e');
      _throwUserFriendlyError(e, 'アイテムの削除');
    }
  }

  /// アイテムリストからショップへの関連付け
  void associateItemsWithShops(List<ListItem> items, List<Shop> shops) {
    // アイテムをIDでインデックス化
    final itemsById = <String, ListItem>{};
    for (final item in items) {
      itemsById[item.id] = item;
    }

    // 各ショップにアイテムを関連付け
    for (int i = 0; i < shops.length; i++) {
      final shop = shops[i];
      final shopItems = items.where((item) => item.shopId == shop.id).toList();

      // 重複を除去
      final seenIds = <String>{};
      final uniqueItems = <ListItem>[];
      for (final item in shopItems) {
        if (!seenIds.contains(item.id)) {
          seenIds.add(item.id);
          uniqueItems.add(item);
        }
      }

      shops[i] = shop.copyWith(items: uniqueItems);
    }
  }

  /// ユーザーフレンドリーなエラーメッセージを投げる
  void _throwUserFriendlyError(dynamic e, String operation) {
    throw convertToAppException(e, contextMessage: operation);
  }
}
