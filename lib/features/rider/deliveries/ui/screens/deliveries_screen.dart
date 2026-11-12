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
    return Scaffold(
      appBar: const CommonAppBar(title: "Today's Deliveries", showBack: false),
      body: KeyboardDismissOnTap(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: CommonSearchField(onChanged: p.setQuery),
            ),
            SizedBox(
              height: 44.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: RiderStatusFilter.values.length,
                separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final f = RiderStatusFilter.values[i];
                  return ChoiceChip(
                    label: Text(f.label),
                    selected: p.filter == f,
                    onSelected: (_) => p.setFilter(f),
                  );
                },
              ),
            ),
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
                                  key: const PageStorageKey('rider_deliveries_scroll'),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (_, i) => DeliveryCard(order: list[i]),
                                ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets empty/error states still support pull-to-refresh.
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
