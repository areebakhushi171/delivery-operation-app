import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/sync_provider.dart';
import '../theme/theme.dart';
import '../utils/date_time_utils.dart';

/// Shows offline state, queued action count, sync progress, failures + retry.
class CommonOfflineBanner extends StatelessWidget {
  const CommonOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    if (sync.isOnline && sync.pendingCount == 0) return const SizedBox.shrink();
    final c = context.appColors;

    late final Color color;
    late final IconData icon;
    late final String text;
    Widget? action;
    if (!sync.isOnline) {
      color = c.warning;
      icon = Icons.cloud_off;
      text = sync.pendingCount == 0
          ? 'You are offline'
          : 'Offline Queue (${sync.pendingCount} action${sync.pendingCount == 1 ? '' : 's'} cached)';
    } else if (sync.isSyncing) {
      color = c.info;
      icon = Icons.sync;
      text = 'Syncing ${sync.pendingCount} action(s)...';
    } else {
      color = sync.hasFailed ? c.danger : c.warning;
      icon = sync.hasFailed ? Icons.sync_problem : Icons.cloud_upload_outlined;
      text = sync.hasFailed
          ? 'Sync failed for ${sync.pendingCount} action(s)'
          : '${sync.pendingCount} action(s) waiting to sync';
      action = TextButton(onPressed: sync.syncNow, child: const Text('Retry'));
    }

    return Material(
      color: color.withAlpha(36),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 18.w, color: color),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                sync.lastSync == null
                    ? text
                    : '$text - last synced ${DateTimeUtils.relative(sync.lastSync!)}',
                style: context.text.labelMedium?.copyWith(color: context.scheme.onSurface),
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
