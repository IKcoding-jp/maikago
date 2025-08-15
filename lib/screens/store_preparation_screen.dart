import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_preparation_service.dart';
import '../widgets/store_checklist_widget.dart';
import '../widgets/store_status_widget.dart';
import '../widgets/store_export_widget.dart';

/// ストア申請準備画面
class StorePreparationScreen extends StatefulWidget {
  const StorePreparationScreen({super.key});

  @override
  State<StorePreparationScreen> createState() => _StorePreparationScreenState();
}

class _StorePreparationScreenState extends State<StorePreparationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late StorePreparationService _storeService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _storeService = StorePreparationService();
    _initializeStoreService();
  }

  Future<void> _initializeStoreService() async {
    await _storeService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _storeService,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChecklistTab(),
                  _buildStatusTab(),
                  _buildExportTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// アプリバーを構築
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'ストア申請準備',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 0,
      actions: [
        Consumer<StorePreparationService>(
          builder: (context, storeService, _) {
            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: storeService.isStoreReady
                    ? Colors.green
                    : Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                storeService.isStoreReady ? '準備完了' : '準備中',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// タブバーを構築
  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.onPrimary,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
        tabs: const [
          Tab(
            icon: Icon(Icons.checklist),
            text: 'チェックリスト',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: '状況確認',
          ),
          Tab(
            icon: Icon(Icons.download),
            text: 'エクスポート',
          ),
        ],
      ),
    );
  }

  /// チェックリストタブを構築
  Widget _buildChecklistTab() {
    return const StoreChecklistWidget();
  }

  /// 状況確認タブを構築
  Widget _buildStatusTab() {
    return const StoreStatusWidget();
  }

  /// エクスポートタブを構築
  Widget _buildExportTab() {
    return const StoreExportWidget();
  }

  /// フローティングアクションボタンを構築
  Widget? _buildFloatingActionButton() {
    return Consumer<StorePreparationService>(
      builder: (context, storeService, _) {
        if (storeService.isStoreReady) {
          return FloatingActionButton.extended(
            onPressed: () => _showStoreReadyDialog(),
            icon: const Icon(Icons.rocket_launch),
            label: const Text('ストア申請'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// ストア準備完了ダイアログを表示
  void _showStoreReadyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 8),
            Text('ストア申請準備完了！'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('おめでとうございます！'),
            SizedBox(height: 8),
            Text('ストア申請の準備が完了しました。以下の手順で申請を進めてください：'),
            SizedBox(height: 16),
            Text('1. Google Play Consoleでアプリをアップロード'),
            Text('2. App Store Connectでアプリをアップロード'),
            Text('3. 各ストアの審査を待つ'),
            Text('4. 承認後にリリース'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showStoreLinks();
            },
            child: const Text('ストアリンク'),
          ),
        ],
      ),
    );
  }

  /// ストアリンクを表示
  void _showStoreLinks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ストア申請リンク'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.android, color: Colors.green),
              title: const Text('Google Play Console'),
              subtitle: const Text('Androidアプリの申請'),
              onTap: () => _openGooglePlayConsole(),
            ),
            ListTile(
              leading: const Icon(Icons.apple, color: Colors.black),
              title: const Text('App Store Connect'),
              subtitle: const Text('iOSアプリの申請'),
              onTap: () => _openAppStoreConnect(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// Google Play Consoleを開く
  void _openGooglePlayConsole() {
    // TODO: 実際のGoogle Play Console URLに変更
    const url = 'https://play.google.com/console';
    // url_launcherを使用してURLを開く
  }

  /// App Store Connectを開く
  void _openAppStoreConnect() {
    // TODO: 実際のApp Store Connect URLに変更
    const url = 'https://appstoreconnect.apple.com';
    // url_launcherを使用してURLを開く
  }
}
