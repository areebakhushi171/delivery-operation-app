import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../storage/local_storage.dart';
import 'firebase/firebase_auth_repository.dart';
import 'firebase/firebase_exception_repository.dart';
import 'firebase/firebase_notification_repository.dart';
import 'firebase/firebase_order_repository.dart';
import 'firebase/firebase_rider_repository.dart';
import 'mock/mock_auth_repository.dart';
import 'mock/mock_exception_repository.dart';
import 'mock/mock_notification_repository.dart';
import 'mock/mock_order_repository.dart';
import 'mock/mock_rider_repository.dart';
import 'mock/mock_store.dart';
import 'repositories/repositories.dart';

/// The ONLY place that decides Mock vs Firebase. Screens/providers never know.
class RepositoryFactory {
  RepositoryFactory._();

  static AppRepositories create(LocalStorage storage) {
    if (AppConfig.useFirebase) {
      final db = FirebaseFirestore.instance;
      return AppRepositories(
        auth: FirebaseAuthRepository(FirebaseAuth.instance, db),
        orders: FirebaseOrderRepository(db),
        riders: FirebaseRiderRepository(db),
        exceptions: FirebaseExceptionRepository(db),
        notifications: FirebaseNotificationRepository(db),
      );
    }
    final store = MockStore.instance;
    return AppRepositories(
      auth: MockAuthRepository(store, storage),
      orders: MockOrderRepository(store),
      riders: MockRiderRepository(store),
      exceptions: MockExceptionRepository(store),
      notifications: MockNotificationRepository(store),
    );
  }
}
