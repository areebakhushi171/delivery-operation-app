import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/app_icons.dart';
import '../data/models/models.dart';
import '../providers/notifications_provider.dart';
import '../routes/app_routes.dart';
import '../theme/theme.dart';
import '../utils/date_time_utils.dart';
import '../../features/authentication/providers/auth_provider.dart';
import 'common_app_bar.dart';
import 'common_card.dart';
import 'common_empty_state.dart';
import 'common_error_state.dart';
import 'common_loading_widget.dart';

/// Shared notifications screen body (used by Rider and Admin wrappers).
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationsProvider>();
    final list = _unreadOnly ? p.items.where((n) => !n.read).toList() : p.items;
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: p.unreadCount == 0 ? null : p.markAllRead,
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<bool>(
              segments: [
                const ButtonSegment(value: false, label: Text('All')),
                ButtonSegment(value: true, label: Text('Unread (${p.unreadCount})')),
              ],
              selected: {_unreadOnly},
              onSelectionChanged: (s) => setState(() => _unreadOnly = s.first),
            ),
          ),
          Expanded(
            child: p.isLoading
                ? const CommonLoadingWidget(skeleton: true)
                : p.error != null
                    ? CommonErrorState(message: p.error!)
                    : list.isEmpty
                        ? const CommonEmptyState(
                            icon: Icons.notifications_none,
                            title: 'No notifications',
                            message: 'New assignments and updates will appear here.',
                          )
                        : ListView.separated(
                            key: const PageStorageKey('notifications_list'),
                            padding: EdgeInsets.fromLTRB(
                                AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) => _Tile(
                              item: list[i],
                              onTap: () {
                                final item = list[i];
                                p.markRead(item.id);
                                if (item.orderId != null && item.orderId!.isNotEmpty) {
                                  final auth = context.read<AuthProvider>();
                                  final isAdmin = auth.user?.role == UserRole.admin;
                                  if (isAdmin) {
                                    context.push(AppRoutes.adminOrder(item.orderId!));
                                  } else {
                                    context.push(AppRoutes.riderDelivery(item.orderId!));
                                  }
                                }
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});
  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return CommonCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: context.scheme.primary.withAlpha(30), shape: BoxShape.circle),
            child: Icon(AppIcons.forNotification(item.type), size: 20.w, color: context.scheme.primary),
          ),
          SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: context.text.titleSmall
                              ?.copyWith(fontWeight: item.read ? FontWeight.w500 : FontWeight.w800)),
                    ),
                    if (!item.read) Icon(Icons.circle, size: 10.w, color: c.info),
                  ],
                ),
                Text(item.body, style: context.text.bodyMedium),
                SizedBox(height: AppSpacing.xs),
                Text(DateTimeUtils.relative(item.createdAt), style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
