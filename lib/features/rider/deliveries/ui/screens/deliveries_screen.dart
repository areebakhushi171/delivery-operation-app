import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../providers/rider_orders_provider.dart';
import '../widgets/delivery_card.dart';

class DeliveriesScreen extends StatelessWidget {
  const DeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RiderOrdersProvider>();
    final list = p.filtered;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB8D9F5),
            Color(0xFFDCEBFA),
            Color(0xFFF4F7FB),
          ],
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const CommonAppBar(title: "Today's Deliveries", showBack: false),
          body: KeyboardDismissOnTap(
            child: Column(
              children: [
                // Top Summary Card with colored donut ring & legend
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
                  child: _DeliveriesSummaryCard(p: p),
                ),
                // Search bar
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.sm),
                  child: CommonSearchField(hint: 'Search orders...', onChanged: p.setQuery),
                ),
                // Filter pills row (All, Pending, In Transit, Delivered, Failed)
                SizedBox(
                  height: 44.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    children: [
                      _filterPill(context, p, RiderStatusFilter.all, 'All'),
                      SizedBox(width: 8.w),
                      _filterPill(context, p, RiderStatusFilter.pending, 'Pending'),
                      SizedBox(width: 8.w),
                      _filterPill(context, p, RiderStatusFilter.inTransit, 'In Transit'),
                      SizedBox(width: 8.w),
                      _filterPill(context, p, RiderStatusFilter.delivered, 'Delivered'),
                      SizedBox(width: 8.w),
                      _filterPill(context, p, RiderStatusFilter.failed, 'Failed'),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                // Deliveries List
                Expanded(
                  child: p.isLoadingInitial
                      ? const CommonLoadingWidget(skeleton: true)
                      : RefreshIndicator(
                    onRefresh: p.refresh,
                    child: p.error != null
                        ? _Scrollable(CommonErrorState(message: p.error!, onRetry: p.refresh))
                        : list.isEmpty
                        ? const _Scrollable(CommonEmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No deliveries found',
                      message: 'Try a different filter or pull down to refresh.',
                    ))
                        : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 96.h),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.gap),
                      itemBuilder: (_, i) => DeliveryCard(order: list[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterPill(BuildContext context, RiderOrdersProvider p, RiderStatusFilter filter, String label) {
    final isSelected = p.filter == filter;
    return GestureDetector(
      onTap: () => p.setFilter(filter),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF111827),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveriesSummaryCard extends StatelessWidget {
  const _DeliveriesSummaryCard({required this.p});
  final RiderOrdersProvider p;

  @override
  Widget build(BuildContext context) {
    final total = p.today.length;
    final pending = p.today.where((o) => o.status == OrderStatus.unassigned || o.status == OrderStatus.assigned).length;
    final inTransit = p.today.where((o) => o.status == OrderStatus.outForDelivery).length;
    final delivered = p.today.where((o) => o.status == OrderStatus.delivered).length;
    final failed = p.today.where((o) => o.status == OrderStatus.failed).length;

    const cPending = Color(0xFFF97316);
    const cTransit = Color(0xFF3B82F6);
    const cDelivered = Color(0xFF16A34A);
    const cFailed = Color(0xFFEC4899);

    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(112, 112),
                  painter: _DonutPainter(
                    strokeWidth: 12,
                    trackColor: const Color(0xFFE2E8F0),
                    segments: [
                      _Segment(pending.toDouble(), cPending),
                      _Segment(inTransit.toDouble(), cTransit),
                      _Segment(delivered.toDouble(), cDelivered),
                      _Segment(failed.toDouble(), cFailed),
                    ],
                  ),
                ),
                // Center text: large and clear
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Text(
                          'today',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(cPending, 'Pending', pending),
                const SizedBox(height: 6),
                _legendRow(cTransit, 'In transit', inTransit),
                const SizedBox(height: 6),
                _legendRow(cDelivered, 'Delivered', delivered),
                const SizedBox(height: 6),
                _legendRow(cFailed, 'Failed', failed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
          ],
        ),
        Text('$count', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      ],
    );
  }
}

class _Segment {
  const _Segment(this.value, this.color);
  final double value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.trackColor,
    required this.strokeWidth,
  });

  final List<_Segment> segments;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Grey track (ring is visible even when there are no orders)
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    final total = segments.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    final active = segments.where((s) => s.value > 0).toList();
    final gap = active.length > 1 ? 0.07 : 0.0; // small gap between segments
    var start = -math.pi / 2;

    for (final s in active) {
      final sweep = (s.value / total) * math.pi * 2;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0.02),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt
          ..color = s.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    if (old.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (old.segments[i].value != segments[i].value) return true;
    }
    return false;
  }
}

class _Scrollable extends StatelessWidget {
  const _Scrollable(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [SizedBox(height: box.maxHeight, child: child)],
    ),
  );
}