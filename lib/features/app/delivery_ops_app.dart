
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/data/repositories/repositories.dart';
import '../../core/navigation/app_router.dart';
import '../../core/providers/providers.dart';
import '../../core/services/location_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/dark_theme.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/light_theme.dart';
import '../../features/admin/providers/admin_providers.dart';
import '../authentication/providers/auth_provider.dart';
import '../rider/deliveries/providers/rider_orders_provider.dart';
import '../rider/profile/providers/rider_profile_provider.dart';
import '../rider/update_status/providers/rider_actions_provider.dart';

class DeliveryOpsApp extends StatelessWidget {
  const DeliveryOpsApp({
    super.key,
    required this.repositories,
    required this.storage,
  });

  final AppRepositories repositories;
  final LocalStorage storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppRepositories>.value(value: repositories),
        Provider<LocalStorage>.value(value: storage),

        // Authentication
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repositories.auth, storage)..initialize(),
        ),

        // Notifications: automatically bind to the logged-in user.
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (_) => NotificationsProvider(repositories.notifications),
          update: (context, auth, previous) {
            final prov =
                previous ?? NotificationsProvider(repositories.notifications);

            prov.bind(auth.user);
            return prov;
          },
        ),

        // Sync
        ChangeNotifierProvider(
          create: (_) => SyncProvider(storage)..init(),
        ),

        // Preferences
        ChangeNotifierProvider(
          create: (_) => PreferencesProvider(storage),
        ),

        // Theme
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storage),
        ),

        // Rider Orders
        ChangeNotifierProxyProvider<AuthProvider, RiderOrdersProvider>(
          create: (_) => RiderOrdersProvider(repositories.orders),
          update: (context, auth, previous) {
            final prov =
                previous ?? RiderOrdersProvider(repositories.orders);

            prov.bind(auth.user);
            return prov;
          },
        ),

        // Rider Profile
        ChangeNotifierProxyProvider<AuthProvider, RiderProfileProvider>(
          create: (_) => RiderProfileProvider(
            repositories.riders,
            LocationService(),
          ),
          update: (context, auth, previous) {
            final prov = previous ??
                RiderProfileProvider(
                  repositories.riders,
                  LocationService(),
                );

            prov.bind(auth.user);
            return prov;
          },
        ),

        // Rider Actions
        ChangeNotifierProxyProvider2<
            AuthProvider,
            SyncProvider,
            RiderActionsProvider>(
          create: (context) => RiderActionsProvider(
            orders: repositories.orders,
            exceptions: repositories.exceptions,
            sync: context.read<SyncProvider>(),
          ),
          update: (context, auth, sync, previous) {
            final prov = previous ??
                RiderActionsProvider(
                  orders: repositories.orders,
                  exceptions: repositories.exceptions,
                  sync: sync,
                );

            prov.bind(auth.user);
            return prov;
          },
        ),

        // Admin Dashboard
        ChangeNotifierProxyProvider<AuthProvider, AdminDashboardProvider>(
          create: (_) => AdminDashboardProvider(
            repositories.orders,
            repositories.riders,
            repositories.exceptions,
          ),
          update: (context, auth, previous) {
            final prov = previous ??
                AdminDashboardProvider(
                  repositories.orders,
                  repositories.riders,
                  repositories.exceptions,
                );

            prov.bind(auth.user);
            return prov;
          },
        ),

        // Admin Orders
        ChangeNotifierProxyProvider<AuthProvider, AdminOrdersProvider>(
          create: (_) => AdminOrdersProvider(
            repositories.orders,
            repositories.riders,
          ),
          update: (context, auth, previous) {
            final prov = previous ??
                AdminOrdersProvider(
                  repositories.orders,
                  repositories.riders,
                );

            prov.bind(auth.user);
            return prov;
          },
        ),

        // Admin Exceptions
        ChangeNotifierProxyProvider<AuthProvider, AdminExceptionsProvider>(
          create: (_) => AdminExceptionsProvider(repositories.exceptions),
          update: (context, auth, previous) {
            final prov = previous ??
                AdminExceptionsProvider(repositories.exceptions);

            prov.bind(auth.user);
            return prov;
          },
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => const _AppView(),
      ),
    );
  }
}

/// Router is created once and reused.
/// Authentication changes are handled through the router refresh listener.
class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Delivery Operations Companion',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(themeProvider.accentColor),
      darkTheme: darkTheme(themeProvider.accentColor),
      themeMode: themeProvider.mode,
      routerConfig: _router,
      // Sky-blue gradient behind every screen (scaffolds are transparent).
      builder: (context, child) => AppBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
