import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../theme/theme.dart';

typedef MapPoint = ({double lat, double lng});

class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.point,
    required this.label,
    required this.color,
    this.icon,
    this.selected = false,
  });
  final String id;
  final MapPoint point;
  final String label;
  final Color color;
  final IconData? icon;
  final bool selected;
}

/// CLEARLY IDENTIFIED SIMULATED MAP (no map SDK / API key needed). Markers and
/// routes are projected from real coordinates. Swap this widget for
/// google_maps_flutter when you have an API key - see README.
class MockMapView extends StatelessWidget {
  const MockMapView({
    super.key,
    required this.markers,
    this.route = const [],
    this.onMarkerTap,
  });

  final List<MapMarkerData> markers;
  final List<MapPoint> route;
  final ValueChanged<String>? onMarkerTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pts = [...markers.map((m) => m.point), ...route];
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight.isFinite ? box.maxHeight : 300.h;
        const pad = 44.0;
        var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
        for (final p in pts) {
          minLat = math.min(minLat, p.lat);
          maxLat = math.max(maxLat, p.lat);
          minLng = math.min(minLng, p.lng);
          maxLng = math.max(maxLng, p.lng);
        }
        if (pts.isEmpty) {
          minLat = 33.68; maxLat = 33.73; minLng = 73.02; maxLng = 73.08;
        }
        final dLat = math.max(maxLat - minLat, 0.004);
        final dLng = math.max(maxLng - minLng, 0.004);
        Offset project(MapPoint p) => Offset(
              pad + (p.lng - minLng) / dLng * (w - 2 * pad),
              pad + (maxLat - p.lat) / dLat * (h - 2 * pad),
            );
        final path = route.map(project).toList();
        return ClipRect(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPainter(
                      path: path,
                      background: dark ? AppColors.mapDark : AppColors.mapLight,
                      road: dark ? const Color(0xFF2C3A5C) : Colors.white,
                      routeColor: context.scheme.primary,
                    ),
                  ),
                ),
                for (final m in markers)
                  Builder(builder: (_) {
                    final o = project(m.point);
                    final size = (m.selected ? 44.0 : 36.0).w;
                    return Positioned(
                      left: o.dx - size / 2,
                      top: o.dy - size / 2,
                      width: size,
                      height: size,
                      child: Semantics(
                        button: onMarkerTap != null,
                        label: 'Map marker ${m.label}',
                        child: GestureDetector(
                          onTap: onMarkerTap == null ? null : () => onMarkerTap!(m.id),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: m.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: m.icon != null
                                ? Icon(m.icon, color: Colors.white, size: 18.w)
                                : FittedBox(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(m.label,
                                          style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: context.appColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(AppStrings.simulatedMap, style: context.text.labelSmall),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.path,
    required this.background,
    required this.road,
    required this.routeColor,
  });
  final List<Offset> path;
  final Color background;
  final Color road;
  final Color routeColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final roadPaint = Paint()
      ..color = road
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    for (double x = 30; x < size.width; x += 78) {
      canvas.drawLine(Offset(x, 0), Offset(x + 18, size.height), roadPaint);
    }
    for (double y = 40; y < size.height; y += 70) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 14), roadPaint);
    }
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.85),
        roadPaint..strokeWidth = 11);

    if (path.length < 2) return;
    final line = Paint()
      ..color = routeColor
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final p = Path()..moveTo(path.first.dx, path.first.dy);
    for (final o in path.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(p, line);

    // direction arrows at segment midpoints
    final arrow = Paint()..color = routeColor;
    for (var i = 0; i < path.length - 1; i++) {
      final a = path[i], b = path[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final ang = math.atan2(b.dy - a.dy, b.dx - a.dx);
      canvas.save();
      canvas.translate(mid.dx, mid.dy);
      canvas.rotate(ang);
      final tri = Path()
        ..moveTo(7, 0)
        ..lineTo(-5, -6)
        ..lineTo(-5, 6)
        ..close();
      canvas.drawPath(tri, arrow);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.path != path || old.background != background || old.routeColor != routeColor;
}
