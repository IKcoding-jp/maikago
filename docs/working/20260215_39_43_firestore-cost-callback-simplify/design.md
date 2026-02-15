# 設計書: Issue #39 + #43

## DataProviderState クラス設計

```
DataProvider (ChangeNotifier)
  └── DataProviderState
        ├── isSynced: bool
        ├── isBatchUpdating: bool
        ├── shouldUseAnonymousSession: bool
        └── notifyListeners() → DataProvider.notifyListeners()

Repository/Manager は DataProviderState を参照:
  ├── ItemRepository(state: DataProviderState)
  ├── ShopRepository(state: DataProviderState)
  ├── RealtimeSyncManager(state: DataProviderState)
  ├── SharedGroupManager(state: DataProviderState)
  └── DataCacheManager(state: DataProviderState)
```

## Firestore 最適化設計

### updateItem/updateShop

```
Before: docRef.get() → doc.exists ? update() : set() + catch not-found → set()
After:  docRef.set(data, SetOptions(merge: true))
```

### deleteItem

```
Before: docRef.get() → doc.exists ? delete() : skip
After:  docRef.delete()
```
