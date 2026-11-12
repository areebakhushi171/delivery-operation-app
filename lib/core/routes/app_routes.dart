/// Centralised route paths (no widgets here, so core stays feature-independent).
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const riderSignUp = '/rider/signup';

  // Rider
  static const riderHome = '/rider/home';
  static const riderDeliveries = '/rider/deliveries';
  static const riderMap = '/rider/map';
  static const riderHistory = '/rider/history';
  static const riderProfile = '/rider/profile';
  static const riderNotifications = '/rider/notifications';
  static const riderDeliveryPattern = '/rider/delivery/:id';
  static const riderStatusPattern = '/rider/delivery/:id/status';
  static const riderProofPattern = '/rider/delivery/:id/proof';
  static const riderExceptionPattern = '/rider/delivery/:id/exception';
  static String riderDelivery(String id) => '/rider/delivery/$id';
  static String riderStatus(String id) => '/rider/delivery/$id/status';
  static String riderProof(String id) => '/rider/delivery/$id/proof';
  static String riderException(String id) => '/rider/delivery/$id/exception';

  // Admin
  static const adminDashboard = '/admin/dashboard';
  static const adminOrders = '/admin/orders';
  static const adminRiders = '/admin/riders';
  static const adminFleet = '/admin/fleet';
  static const adminExceptions = '/admin/exceptions';
  static const adminAnalytics = '/admin/analytics';
  static const adminProfile = '/admin/profile';
  static const adminNotifications = '/admin/notifications';
  static const adminCreateOrder = '/admin/create-order';
  static const adminOrderPattern = '/admin/order/:id';
  static const adminAssignPattern = '/admin/order/:id/assign';
  static String adminOrder(String id) => '/admin/order/$id';
  static String adminAssign(String id, {String? exceptionId}) =>
      '/admin/order/$id/assign${exceptionId == null ? '' : '?exception=$exceptionId'}';
}
