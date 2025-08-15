import 'package:flutter_test/flutter_test.dart';

// テストファイルをインポート
import 'services/subscription_manager_test.dart' as subscription_manager_test;
import 'services/feature_access_control_test.dart'
    as feature_access_control_test;
import 'widgets/migration_status_widget_test.dart'
    as migration_status_widget_test;
import 'integration/subscription_integration_test.dart'
    as subscription_integration_test;

void main() {
  group('Subscription System Tests', () {
    group('SubscriptionManager Tests', () {
      subscription_manager_test.main();
    });

    group('FeatureAccessControl Tests', () {
      feature_access_control_test.main();
    });

    group('MigrationStatusWidget Tests', () {
      migration_status_widget_test.main();
    });

    group('Subscription Integration Tests', () {
      subscription_integration_test.main();
    });
  });
}
