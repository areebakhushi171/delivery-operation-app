import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_ops_companion/core/data/mock/mock_auth_repository.dart';
import 'package:delivery_ops_companion/core/data/mock/mock_exception_repository.dart';
import 'package:delivery_ops_companion/core/data/mock/mock_notification_repository.dart';
import 'package:delivery_ops_companion/core/data/mock/mock_order_repository.dart';
import 'package:delivery_ops_companion/core/data/mock/mock_rider_repository.dart';
import 'package:delivery_ops_companion/core/data/mock/mock_store.dart';
import 'package:delivery_ops_companion/core/data/repositories/repositories.dart';
import 'package:delivery_ops_companion/core/storage/local_storage.dart';
import 'package:delivery_ops_companion/features/app/delivery_ops_app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.create();
    final store = MockStore.instance;
    final repositories = AppRepositories(
      auth: MockAuthRepository(store, storage),
      orders: MockOrderRepository(store),
      riders: MockRiderRepository(store),
      exceptions: MockExceptionRepository(store),
      notifications: MockNotificationRepository(store),
    );
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(DeliveryOpsApp(repositories: repositories, storage: storage));
    await tester.pumpAndSettle();
    expect(find.byType(DeliveryOpsApp), findsOneWidget);
  });
}
