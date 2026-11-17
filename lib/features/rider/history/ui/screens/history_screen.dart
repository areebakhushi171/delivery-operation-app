import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/core.dart';
import '../../../../../core/utils/scroll_reset.dart';
import '../../../deliveries/providers/rider_orders_provider.dart';
import '../../../deliveries/ui/widgets/delivery_card.dart';
import '../../../deliveries/ui/widgets/rider_stats.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _failedTab = false;
  DateRangeOption _range = DateRangeOption.last30;
  String _query = '';

  @override
  void initState() {
    super.initState();
    ScrollResetRegistry.register(3, _scrollController);
  }

  @override
  void dispose() {
    ScrollResetRegistry.unregister(3);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RiderOrdersProvider>();
    final list = p.history(failedTab: _failedTab, range: _range, query: _query);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Delivery History', showBack: false),
      body: KeyboardDismissOnTap(
        child: RefreshIndicator(
          onRefresh: p.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
                  child: Column(
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Completed')),
                          ButtonSegment(value: true, label: Text('Failed')),
                        ],
                        selected: {_failedTab},
                        onSelectionChanged: (s) {
                          setState(() => _failedTab = s.first);
                          ScrollResetRegistry.resetController(_scrollController);
                        },
                      ),
                      SizedBox(height: AppSpacing.sm),
                      CommonDateFilter(value: _range, onChanged: (v) => setState(() => _range = v)),
                      SizedBox(height: AppSpacing.sm),
                      CommonSearchField(hint: 'Search history...', onChanged: (v) => setState(() => _query = v)),
                    ],
                  ),
                ),
              ),
              if (p.isLoadingInitial)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: CommonLoadingWidget(skeleton: true),
                )
              else if (p.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: CommonErrorState(message: p.error!, onRetry: p.refresh),
                )
              else if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 60),
                    child: CommonEmptyState(
                      icon: Icons.history,
                      title: _failedTab ? 'No failed deliveries' : 'No completed deliveries',
                      message: 'Nothing matches this period or search.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.gap),
                            child: _Summary(list: list, failedTab: _failedTab, p: p, range: _range),
                          );
                        }
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.gap),
                          child: DeliveryCard(order: list[i - 1]),
                        );
                      },
                      childCount: list.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top card: count, COD collected and a trend chart of the shown deliveries.
class _Summary extends StatelessWidget {
  const _Summary({required this.list, required this.failedTab, required this.p, required this.range});
  final List<DeliveryOrder> list;
  final bool failedTab;
  final RiderOrdersProvider p;
  final DateRangeOption range;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final days = (range == DateRangeOption.all || range.days < 7) ? (range == DateRangeOption.today ? 7 : 30) : range.days;
    final color = failedTab ? c.danger : c.success;
    return SummaryCard(
      label: failedTab ? 'Failed deliveries' : 'Completed deliveries',
      value: '${list.length}',
      badge: failedTab ? range.label : 'COD collected: ${CurrencyUtils.rs(p.codCollectedIn(list))}',
      badgeColor: failedTab ? c.danger : c.success,
      child: AreaLineChart(
        values: RiderStats.dailyCounts(list, days),
        xLabels: RiderStats.dayLabels(days),
        color: color,
        height: 150,
        format: (v) => '${v.round()} deliveries',
      ),
    );
  }
}
