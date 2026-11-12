import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_ops_companion/core/data/repository_factory.dart';
import 'package:delivery_ops_companion/core/storage/local_storage.dart';
import 'package:delivery_ops_companion/features/app/delivery_ops_app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final storage = await LocalStorage.create();
    final repositories = RepositoryFactory.create(storage);
    await tester.pumpWidget(DeliveryOpsApp(repositories: repositories, storage: storage));
    expect(find.byType(DeliveryOpsApp), findsOneWidget);
  });
}
