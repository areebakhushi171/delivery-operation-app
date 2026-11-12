
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/admin_providers.dart';

// ───────────────────────── Helpers ─────────────────────────

String _fmt(DateTime d) =>
    DateFormat('EEE, d MMM • h:mm a').format(d.toLocal());

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

({String label, Color color}) _statusInfo(
    BuildContext context,
    ExceptionStatus s,
    ) {
  final c = context.appColors;

  if (s == ExceptionStatus.resolved) {
    return (label: 'Resolved', color: c.success);
  }
  if (s == ExceptionStatus.rescheduled) {
    return (label: 'Rescheduled', color: c.info);
  }
  if (s == ExceptionStatus.reassigned) {
    return (label: 'Reassigned', color: c.info);
  }
  if (s == ExceptionStatus.rto) {
    return (label: 'Return to origin', color: c.warning);
  }

  return (label: 'Open', color: c.danger);
}

// ───────────────────────── Screen ─────────────────────────

class ExceptionsDeskScreen extends StatefulWidget {
  const ExceptionsDeskScreen({super.key});

  @override
  State<ExceptionsDeskScreen> createState() =>
      _ExceptionsDeskScreenState();
}

class _ExceptionsDeskScreenState
    extends State<ExceptionsDeskScreen> {
  bool _showOpen = true;
  bool _openingSheet = false;

  Future<void> _openSheet(DeliveryException ex) async {
    if (_openingSheet) return;

    final admin = context.read<AuthProvider>().user;

    if (admin == null || admin.uid.isEmpty) {
      context.showMessage(
        'Admin session not found. Please log in again.',
        isError: true,
      );
      return;
    }

    setState(() => _openingSheet = true);

    try {
      final prov = context.read<AdminExceptionsProvider>();
      final dashboard = context.read<AdminDashboardProvider>();

      debugPrint('EXCEPTIONS: Opening action sheet for ${ex.id}');

      final message = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        useRootNavigator: false,
        isDismissible: true,
        enableDrag: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        builder: (sheetContext) {
          debugPrint('EXCEPTIONS: Action sheet built');

          return _ActionSheet(
            ex: ex,
            riders: dashboard.riders,
            prov: prov,
            adminUid: admin.uid,
          );
        },
      );

      debugPrint('EXCEPTIONS: Sheet closed. Result: $message');

      if (!mounted) return;

      if (message != null && message.isNotEmpty) {
        context.showMessage(message, isSuccess: true);
      }
    } catch (e, stack) {
      debugPrint('EXCEPTIONS SHEET ERROR: $e');
      debugPrintStack(stackTrace: stack);

      if (mounted) {
        context.showMessage(
          'Unable to open action panel: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingSheet = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminExceptionsProvider>();

    if (prov.isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: 'Exceptions Desk'),
        body: CommonLoadingWidget(),
      );
    }

    final all = [...prov.exceptions]
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    final open = all.where((e) => e.status.isOpen).toList();
    final closed = all.where((e) => !e.status.isOpen).toList();
    final list = _showOpen ? open : closed;

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Exceptions Triage Desk',
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text('Open (${open.length})'),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Closed (${closed.length})'),
                  ),
                ],
                selected: {_showOpen},
                onSelectionChanged: (s) {
                  setState(() => _showOpen = s.first);
                },
              ),
            ),
          ),
          Expanded(
            child: prov.error != null && all.isEmpty
                ? CommonErrorState(message: prov.error!)
                : list.isEmpty
                ? CommonEmptyState(
              title: _showOpen
                  ? 'All clear'
                  : 'Nothing closed yet',
              message: _showOpen
                  ? 'No open delivery exceptions right now.'
                  : 'Closed exceptions will appear here.',
            )
                : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final exception = list[i];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: _ExceptionCard(
                    ex: exception,
                    isOpening: _openingSheet,
                    onAction: () => _openSheet(exception),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Exception Card ─────────────────────────

class _ExceptionCard extends StatelessWidget {
  const _ExceptionCard({
    required this.ex,
    required this.onAction,
    required this.isOpening,
  });

  final DeliveryException ex;
  final VoidCallback onAction;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final muted = context.scheme.onSurfaceVariant;
    final st = _statusInfo(context, ex.status);

    final isOpen = ex.status.isOpen;
    final requested = ex.rescheduleRequestedAt;

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${ex.orderId}',
                  style: context.text.titleSmall,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  color: st.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  st.label,
                  style: context.text.labelSmall?.copyWith(
                    color: st.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(
                Icons.report_problem_outlined,
                size: 16.w,
                color: c.danger,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  ex.reason.label,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _ago(ex.reportedAt),
                style: context.text.labelSmall?.copyWith(
                  color: muted,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Rider: ${ex.riderName} (#${ex.riderStaffId}) • Customer: ${ex.customerName}',
            style: context.text.bodySmall?.copyWith(color: muted),
          ),
          if (ex.description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              ex.description,
              style: context.text.bodyMedium,
            ),
          ],
          if (isOpen && requested != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: c.info.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_repeat,
                    size: 18.w,
                    color: c.info,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Rider requested reschedule: ${_fmt(requested)}',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isOpen) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: st.color.withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.resolvedAt != null
                        ? '${st.label} • ${_fmt(ex.resolvedAt!)}'
                        : st.label,
                    style: context.text.labelMedium?.copyWith(
                      color: st.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (ex.resolutionNote != null &&
                      ex.resolutionNote!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Message to rider: ${ex.resolutionNote}',
                      style: context.text.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  context.push(AppRoutes.adminOrder(ex.orderId));
                },
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                ),
                label: const Text('View order'),
              ),
              if (isOpen) ...[
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isOpening ? null : onAction,
                    icon: isOpening
                        ? SizedBox(
                      height: 16.w,
                      width: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.bolt_rounded,
                      size: 18,
                    ),
                    label: const Text('Take action'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Action Types ─────────────────────────

enum _Action {
  resolve,
  reschedule,
  reassign,
  rto,
}

// ───────────────────────── Action Sheet ─────────────────────────

class _ActionSheet extends StatefulWidget {
  const _ActionSheet({
    required this.ex,
    required this.riders,
    required this.prov,
    required this.adminUid,
  });

  final DeliveryException ex;
  final List<Rider> riders;
  final AdminExceptionsProvider prov;
  final String adminUid;

  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  final _noteCtrl = TextEditingController();

  late _Action _action;
  late DateTime _start;

  int _hours = 3;
  String? _riderId;
  bool _busy = false;
  String? _error;

  late final List<Rider> _candidates = ([...widget.riders]
    ..removeWhere((r) => r.id == widget.ex.riderId)
    ..sort((a, b) {
      final ad = a.dutyStatus == DutyStatus.onDuty ? 0 : 1;
      final bd = b.dutyStatus == DutyStatus.onDuty ? 0 : 1;
      return ad.compareTo(bd);
    }));

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final requested = widget.ex.rescheduleRequestedAt;

    if (requested != null && requested.isAfter(now)) {
      _start = requested;
      _action = _Action.reschedule;
    } else {
      _start = DateTime(
        now.year,
        now.month,
        now.day + 1,
        10,
      );
      _action = _Action.resolve;
    }

    debugPrint(
      'EXCEPTIONS: Action panel initialized for ${widget.ex.id}',
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime get _end => _start.add(Duration(hours: _hours));

  ExceptionStatus get _outcome {
    switch (_action) {
      case _Action.resolve:
        return ExceptionStatus.resolved;
      case _Action.reschedule:
        return ExceptionStatus.rescheduled;
      case _Action.reassign:
        return ExceptionStatus.reassigned;
      case _Action.rto:
        return ExceptionStatus.rto;
    }
  }

  String get _note => _noteCtrl.text.trim();

  String get _riderNameForReassign {
    for (final rider in _candidates) {
      if (rider.id == _riderId) return rider.name;
    }
    return 'another courier';
  }

  List<String> get _templates {
    switch (_action) {
      case _Action.resolve:
        return [
          'Issue sorted with the customer.',
          'Customer contacted, no further action needed.',
        ];
      case _Action.reschedule:
        return [
          'Customer confirmed the new time.',
          'Please deliver in the new window.',
        ];
      case _Action.reassign:
        return [
          'This order has been moved to another courier.',
          'Please continue with your next stop.',
        ];
      case _Action.rto:
        return [
          'Please return the parcel to the hub.',
          'Customer refused delivery. Return to hub.',
        ];
    }
  }

  String get _preview {
    final id = widget.ex.orderId;

    String base;

    switch (_action) {
      case _Action.resolve:
        base = 'Dispatcher closed the report for #$id.';
        break;
      case _Action.reschedule:
        base =
        'Order #$id rescheduled: ${_fmt(_start)} – ${DateFormat('h:mm a').format(_end)}.';
        break;
      case _Action.reassign:
        base = 'Order #$id was moved to $_riderNameForReassign.';
        break;
      case _Action.rto:
        base = 'Return #$id to the hub.';
        break;
    }

    return _note.isEmpty ? base : '$base\n"$_note"';
  }

  String get _successMessage {
    final id = widget.ex.orderId;

    switch (_action) {
      case _Action.resolve:
        return 'Exception for #$id resolved. Rider notified.';
      case _Action.reschedule:
        return 'Order #$id rescheduled to ${_fmt(_start)}. Rider notified.';
      case _Action.reassign:
        return 'Order #$id reassigned to $_riderNameForReassign.';
      case _Action.rto:
        return 'Order #$id marked Return to Origin.';
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);

    final initial = _start.isBefore(first) ? first : _start;

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: first.add(const Duration(days: 30)),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _start = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _start.hour,
        _start.minute,
      );
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        selected.hour,
        selected.minute,
      );
      _error = null;
    });
  }

  void _selectAction(_Action action) {
    if (_busy) return;

    setState(() {
      _action = action;
      _error = null;
    });

    debugPrint('EXCEPTIONS: Selected action $action');
  }

  Future<void> _submit() async {
    if (_busy) return;

    if (_action == _Action.reschedule &&
        !_start.isAfter(DateTime.now())) {
      setState(() {
        _error = 'Please select a future date and time.';
      });
      return;
    }

    if (_action == _Action.reassign) {
      if (_riderId == null) {
        setState(() {
          _error = 'Please select another courier.';
        });
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      debugPrint(
        'EXCEPTIONS: Submitting ${_action.name} for ${widget.ex.id}',
      );

      await widget.prov.resolve(
        exceptionId: widget.ex.id,
        outcome: _outcome,
        byUid: widget.adminUid,
        note: _note.isEmpty ? null : _note,
        newRiderId:
        _action == _Action.reassign ? _riderId : null,
        newStart:
        _action == _Action.reschedule ? _start : null,
        newEnd:
        _action == _Action.reschedule ? _end : null,
      );

      if (!mounted) return;

      debugPrint('EXCEPTIONS: Action successfully saved');

      Navigator.of(context).pop(_successMessage);
    } catch (e, stack) {
      debugPrint('EXCEPTIONS SUBMIT ERROR: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final muted = context.scheme.onSurfaceVariant;
    final requested = widget.ex.rescheduleRequestedAt;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom +
                AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: muted.withAlpha(100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Exception action center',
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed:
                    _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              Text(
                'Order #${widget.ex.orderId}',
                style: context.text.titleMedium?.copyWith(
                  color: context.scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${widget.ex.reason.label} • ${widget.ex.riderName}',
                style: context.text.bodySmall?.copyWith(
                  color: muted,
                ),
              ),

              if (requested != null) ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.info.withAlpha(25),
                    borderRadius:
                    BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_repeat,
                        size: 20.w,
                        color: c.info,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Rider requested: ${_fmt(requested)}',
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.md),

              Text(
                'Choose an action',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.sm),

              _ActionTile(
                icon: Icons.check_circle_outline,
                title: 'Resolve',
                subtitle: 'Close this report and notify the rider.',
                selected: _action == _Action.resolve,
                onTap: () => _selectAction(_Action.resolve),
              ),

              _ActionTile(
                icon: Icons.event_repeat,
                title: 'Reschedule delivery',
                subtitle: 'Choose a new delivery date and time.',
                selected: _action == _Action.reschedule,
                onTap: () => _selectAction(_Action.reschedule),
              ),

              _ActionTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Reassign to another rider',
                subtitle: 'Transfer this order to another courier.',
                selected: _action == _Action.reassign,
                onTap: () => _selectAction(_Action.reassign),
              ),

              _ActionTile(
                icon: Icons.undo_rounded,
                title: 'Return to origin',
                subtitle: 'Send the parcel back to the hub.',
                selected: _action == _Action.rto,
                onTap: () => _selectAction(_Action.rto),
              ),

              SizedBox(height: AppSpacing.md),

              // RESCHEDULE WORKFLOW
              if (_action == _Action.reschedule) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.scheme.outline.withAlpha(90),
                    ),
                    borderRadius:
                    BorderRadius.circular(AppRadius.input),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New delivery schedule',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _pickDate,
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                DateFormat('EEE, d MMM')
                                    .format(_start),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _pickTime,
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                DateFormat('h:mm a')
                                    .format(_start),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Delivery window duration',
                        style: context.text.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 8.w,
                        children: [
                          for (final h in [2, 3, 4])
                            ChoiceChip(
                              label: Text('$h hours'),
                              selected: _hours == h,
                              onSelected: _busy
                                  ? null
                                  : (_) {
                                setState(() {
                                  _hours = h;
                                });
                              },
                            ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'New window: ${DateFormat('h:mm a').format(_start)} – ${DateFormat('h:mm a').format(_end)}',
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // REASSIGN WORKFLOW
              if (_action == _Action.reassign) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.scheme.outline.withAlpha(90),
                    ),
                    borderRadius:
                    BorderRadius.circular(AppRadius.input),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose replacement courier',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      if (_candidates.isEmpty)
                        Text(
                          'No other registered riders are available.',
                          style: context.text.bodySmall?.copyWith(
                            color: c.danger,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _riderId,
                          decoration: const InputDecoration(
                            labelText: 'Select courier',
                            hintText: 'Choose a registered rider',
                          ),
                          items: [
                            for (final r in _candidates)
                              DropdownMenuItem<String>(
                                value: r.id,
                                child: Text(
                                  '${r.name} • ${r.dutyStatus.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) {
                            setState(() {
                              _riderId = v;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],

              // RESOLVE AND RTO INFORMATION
              if (_action == _Action.resolve ||
                  _action == _Action.rto) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _action == _Action.resolve
                        ? c.success.withAlpha(18)
                        : c.warning.withAlpha(18),
                    borderRadius:
                    BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _action == _Action.resolve
                            ? Icons.check_circle_outline
                            : Icons.local_shipping_outlined,
                        color: _action == _Action.resolve
                            ? c.success
                            : c.warning,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _action == _Action.resolve
                              ? 'The exception report will be closed and the rider will be notified.'
                              : 'The order will be marked as Return to Origin. The rider will be instructed to return the parcel to the hub.',
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.md),

              Text(
                'Message to rider (optional)',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),

              TextField(
                controller: _noteCtrl,
                enabled: !_busy,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText:
                  'Write instructions or a message for the rider...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              SizedBox(height: AppSpacing.sm),

              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  for (final template in _templates)
                    ActionChip(
                      label: Text(
                        template,
                        style: context.text.labelSmall,
                      ),
                      onPressed: _busy
                          ? null
                          : () {
                        setState(() {
                          _noteCtrl.text = template;
                        });
                      },
                    ),
                ],
              ),

              SizedBox(height: AppSpacing.md),

              // NOTIFICATION PREVIEW
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.scheme.primary.withAlpha(18),
                  borderRadius:
                  BorderRadius.circular(AppRadius.input),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 18.w,
                          color: context.scheme.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Rider notification preview',
                          style: context.text.labelMedium?.copyWith(
                            color: context.scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _preview,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.danger.withAlpha(20),
                    borderRadius:
                    BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: c.danger,
                        size: 18.w,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _error!,
                          style: context.text.bodySmall?.copyWith(
                            color: c.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? SizedBox(
                    height: 18.w,
                    width: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _busy ? 'Saving...' : _submitLabel,
                  ),
                ),
              ),

              SizedBox(height: 6.h),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                  _busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _submitLabel {
    switch (_action) {
      case _Action.resolve:
        return 'Resolve exception & notify rider';
      case _Action.reschedule:
        return 'Confirm new delivery schedule';
      case _Action.reassign:
        return 'Confirm rider reassignment';
      case _Action.rto:
        return 'Confirm return to origin';
    }
  }
}

// ───────────────────────── Action Tile ─────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: selected
            ? primary.withAlpha(22)
            : context.scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.input),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(AppRadius.input),
              border: Border.all(
                color: selected
                    ? primary
                    : context.scheme.outline.withAlpha(80),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? primary
                      : context.scheme.onSurfaceVariant,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: context.text.bodySmall?.copyWith(
                          color:
                          context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? primary
                      : context.scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
