import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../../deliveries/ui/widgets/delivery_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _failedTab = false;
  DateRangeOption _range = DateRangeOption.last30;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RiderOrdersProvider>();
    final list = p.history(failedTab: _failedTab, range: _range, query: _query);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Delivery History', showBack: false),
      body: KeyboardDismissOnTap(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Completed')),
                      ButtonSegment(value: true, label: Text('Failed')),
                    ],
                    selected: {_failedTab},
                    onSelectionChanged: (s) => setState(() => _failedTab = s.first),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  CommonDateFilter(value: _range, onChanged: (v) => setState(() => _range = v)),
                  SizedBox(height: AppSpacing.sm),
                  CommonSearchField(hint: 'Search history...', onChanged: (v) => setState(() => _query = v)),
                  if (!_failedTab && list.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: Text('${list.length} deliveries', style: context.text.labelMedium)),
                        Text('COD collected: ${CurrencyUtils.rs(p.codCollectedIn(list))}',
                            style: context.text.labelLarge?.copyWith(color: context.appColors.success)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: p.isLoadingInitial
                  ? const CommonLoadingWidget(skeleton: true)
                  : p.error != null
                      ? CommonErrorState(message: p.error!, onRetry: p.refresh)
                      : list.isEmpty
                          ? CommonEmptyState(
                              icon: Icons.history,
                              title: _failedTab ? 'No failed deliveries' : 'No completed deliveries',
                              message: 'Nothing matches this period or search.',
                            )
                          : ListView.separated(
                              key: PageStorageKey('rider_history_${_failedTab ? 'failed' : 'done'}'),
                              padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                              itemBuilder: (_, i) => DeliveryCard(order: list[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
