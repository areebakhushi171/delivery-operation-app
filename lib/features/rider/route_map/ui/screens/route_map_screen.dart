import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../../profile/providers/rider_profile_provider.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  String? _selectedId;

  List<MapPoint> _generateRouteWaypoints(MapPoint start, MapPoint end) {
    final waypoints = <MapPoint>[start];
    final mid1 = (
      lat: start.lat + (end.lat - start.lat) * 0.35 + 0.0025,
      lng: start.lng + (end.lng - start.lng) * 0.3 - 0.0015,
    );
    final mid2 = (
      lat: start.lat + (end.lat - start.lat) * 0.7 - 0.0015,
      lng: start.lng + (end.lng - start.lng) * 0.7 + 0.0025,
    );
    waypoints.add(mid1);
    waypoints.add(mid2);
    waypoints.add(end);
    return waypoints;
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<RiderOrdersProvider>();
    final rider = context.watch<RiderProfileProvider>().rider;
    final allOrders = orders.active.isNotEmpty ? orders.active : orders.today;
    final selected = (_selectedId == null ? null : orders.byId(_selectedId!)) ?? orders.nextStop ?? allOrders.firstOrNull;

    final c = context.appColors;
    final riderLat = rider?.lat ?? 33.6844;
    final riderLng = rider?.lng ?? 73.0479;

    final markers = <MapMarkerData>[
      for (var i = 0; i < allOrders.length; i++)
        () {
          final o = allOrders[i];
          final lat = o.lat ?? (33.6844 + (i * 0.01) - 0.02);
          final lng = o.lng ?? (73.0479 + (i * 0.01) - 0.02);
          final isSelected = (o.id == selected?.id);
          return MapMarkerData(
            id: o.id,
            point: (lat: lat, lng: lng),
            label: '${o.stopNumber ?? (i + 1)}',
            icon: o.status == OrderStatus.delivered ? Icons.check : null,
            color: o.status == OrderStatus.delivered
                ? c.success
                : (o.status == OrderStatus.failed ? c.danger : context.scheme.primary),
            selected: isSelected,
          );
        }(),
      MapMarkerData(
        id: '_me',
        point: (lat: riderLat, lng: riderLng),
        label: 'Me',
        icon: Icons.navigation,
        color: AppColors.primaryDark,
      ),
    ];

    final startPt = (lat: riderLat, lng: riderLng);
    final destPt = selected != null
        ? (lat: selected.lat ?? 33.6844, lng: selected.lng ?? 73.0479)
        : (allOrders.isNotEmpty ? (lat: allOrders.first.lat ?? 33.6844, lng: allOrders.first.lng ?? 73.0479) : startPt);

    final routePoints = _generateRouteWaypoints(startPt, destPt);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Route Navigation Map', showBack: false),
      body: orders.isLoadingInitial
          ? const CommonLoadingWidget()
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: MockMapView(
                        markers: markers,
                        route: routePoints,
                        onMarkerTap: (id) {
                          if (id != '_me') setState(() => _selectedId = id);
                        },
                      ),
                    ),
                    _Panel(order: selected, isNext: selected?.id == orders.nextStop?.id),
                  ],
                ),
                if (selected != null)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.sm + 4),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_outlined, color: context.scheme.primary),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Route to Stop #${selected.stopNumber ?? 1}: ${selected.customerName}',
                                    style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(selected.address, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(color: c.success.withAlpha(30), borderRadius: BorderRadius.circular(AppRadius.chip)),
                            child: Text('${selected.distanceKm.toStringAsFixed(1)} km',
                                style: context.text.labelSmall?.copyWith(color: c.success, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.order, required this.isNext});
  final DeliveryOrder? order;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: [BoxShadow(color: context.appColors.shadow, blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: o == null
            ? const CommonEmptyState(icon: Icons.task_alt, title: 'No active stops', message: 'You have no pending deliveries.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CommonStatusChip(label: isNext ? 'Next Stop' : 'Stop #${o.stopNumber ?? '-'}', tone: StatusTone.info),
                      SizedBox(width: AppSpacing.sm),
                      CommonStatusChip.order(o.status),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text('#${o.id}', style: context.text.titleSmall),
                  Text(o.customerName, style: context.text.titleLarge),
                  Text(o.fullAddress, style: context.text.bodySmall),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      SizedBox(width: 4.w),
                      Text(
                        '${o.etaMinutes != null ? 'ETA ${o.etaMinutes} min - ' : ''}${o.distanceKm.toStringAsFixed(1)} km',
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: CommonButton(
                          label: 'Call',
                          icon: Icons.call,
                          variant: CommonButtonVariant.secondary,
                          onPressed: () async {
                            if (!await LauncherService.call(o.customerPhone) && context.mounted) {
                              context.showMessage('Cannot open the phone app.', isError: true);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: CommonButton(
                          label: 'Start Navigation',
                          icon: Icons.navigation_outlined,
                          onPressed: () async {
                            final lat = o.lat ?? 33.6844;
                            final lng = o.lng ?? 73.0479;
                            if (!await LauncherService.navigate(lat, lng, o.fullAddress) && context.mounted) {
                              context.showMessage('No navigation app available.', isError: true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
