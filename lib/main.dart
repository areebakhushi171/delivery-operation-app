import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/data/repository_factory.dart';
import 'core/storage/local_storage.dart';
import 'features/app/delivery_ops_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.useFirebase) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint('Firebase init notice: $e');
    }
  }
  final storage = await LocalStorage.create();
  runApp(
    DeliveryOpsApp(
      repositories: RepositoryFactory.create(storage),
      storage: storage,
    ),
  );
}
