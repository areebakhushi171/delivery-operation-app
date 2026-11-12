
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/ui/screens/admin_dashboard_screen.dart';
import '../../features/admin/ui/screens/admin_notifications_screen.dart';
import '../../features/admin/ui/screens/admin_order_details_screen.dart';
import '../../features/admin/ui/screens/admin_orders_screen.dart';
import '../../features/admin/ui/screens/admin_profile_screen.dart';
import '../../features/admin/ui/screens/admin_riders_screen.dart';
import '../../features/admin/ui/screens/create_order_screen.dart';
import '../../features/admin/ui/screens/exceptions_desk_screen.dart';
import '../../features/admin/ui/screens/fleet_analytics_screen.dart';
import '../../features/admin/ui/screens/fleet_telemetry_screen.dart';
import '../../features/authentication/providers/auth_provider.dart';
import '../../features/authentication/ui/screens/login_screen.dart';
import '../../features/authentication/ui/screens/rider_signup_screen.dart';
import '../../features/authentication/ui/screens/splash_screen.dart';
import '../../features/rider/deliveries/ui/screens/deliveries_screen.dart';
import '../../features/rider/delivery_details/ui/screens/delivery_details_screen.dart';
import '../../features/rider/exceptions/ui/screens/report_exception_screen.dart';
import '../../features/rider/history/ui/screens/history_screen.dart';
import '../../features/rider/home/ui/screens/rider_home_screen.dart';
import '../../features/rider/notifications/ui/screens/rider_notifications_screen.dart';
import '../../features/rider/profile/ui/screens/rider_profile_screen.dart';
import '../../features/rider/proof_of_delivery/ui/screens/proof_of_delivery_screen.dart';
import '../../features/rider/route_map/ui/screens/route_map_screen.dart';
import '../../features/rider/update_status/ui/screens/update_status_screen.dart';
import '../data/models/enums.dart';
import '../routes/app_routes.dart';
import '../widgets/common_bottom_navigation.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isSignUp = state.matchedLocation == AppRoutes.riderSignUp;

      if (status == AuthStatus.unknown) {
        return null;
      }

      if (status == AuthStatus.signedOut) {
        return (isLogin || isSignUp) ? null : AppRoutes.login;
      }

      if (status == AuthStatus.signedIn) {
        if (isSplash || isLogin || isSignUp) {
          final role = authProvider.user?.role;

          return role == UserRole.admin
              ? AppRoutes.adminDashboard
              : AppRoutes.riderHome;
        }
      }

      return null;
    },
    routes: [
      // Authentication routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.riderSignUp,
        builder: (context, state) => const RiderSignUpScreen(),
      ),

      // Rider Shell with bottom navigation tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            shell: navigationShell,
            items: const [
              AppNavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
              ),
              AppNavItem(
                label: 'Deliveries',
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
              ),
              AppNavItem(
                label: 'Map',
                icon: Icons.map_outlined,
                selectedIcon: Icons.map_rounded,
              ),
              AppNavItem(
                label: 'History',
                icon: Icons.history_rounded,
                selectedIcon: Icons.history_toggle_off_rounded,
              ),
              AppNavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
              ),
            ],
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.riderHome,
                builder: (context, state) => const RiderHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.riderDeliveries,
                builder: (context, state) => const DeliveriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.riderMap,
                builder: (context, state) => const RouteMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.riderHistory,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.riderProfile,
                builder: (context, state) => const RiderProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin Shell with bottom navigation tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            shell: navigationShell,
            items: const [
              AppNavItem(
                label: 'Dashboard',
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
              ),
              AppNavItem(
                label: 'Orders',
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long_rounded,
              ),
              AppNavItem(
                label: 'Riders',
                icon: Icons.two_wheeler_outlined,
                selectedIcon: Icons.two_wheeler_rounded,
              ),
              AppNavItem(
                label: 'Exceptions',
                icon: Icons.warning_amber_rounded,
                selectedIcon: Icons.warning_rounded,
              ),
              AppNavItem(
                label: 'Analytics',
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics_rounded,
              ),
            ],
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminDashboard,
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminOrders,
                builder: (context, state) => const AdminOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminRiders,
                builder: (context, state) => const AdminRidersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminExceptions,
                builder: (context, state) => const ExceptionsDeskScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminAnalytics,
                builder: (context, state) => const FleetAnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Standalone Rider routes
      GoRoute(
        path: AppRoutes.riderNotifications,
        builder: (context, state) => const RiderNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.riderDeliveryPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DeliveryDetailsScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.riderStatusPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return UpdateStatusScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.riderProofPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProofOfDeliveryScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.riderExceptionPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ReportExceptionScreen(orderId: id);
        },
      ),

      // Standalone Admin routes
      GoRoute(
        path: AppRoutes.adminNotifications,
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProfile,
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCreateOrder,
        builder: (context, state) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminOrderPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdminOrderDetailsScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.adminFleet,
        builder: (context, state) => const FleetTelemetryScreen(),
      ),
    ],
  );
}
