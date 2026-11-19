import '../../utils/utils.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_store.dart';

class MockExceptionRepository implements ExceptionRepository {
  MockExceptionRepository(this._s);
  final MockStore _s;

  @override
  Stream<List<DeliveryException>> watchAll() => _s.exceptions.watch();

  @override
  Stream<List<DeliveryException>> watchActiveExceptions() =>
      _s.exceptions.watch().map((l) => l.where((e) => e.status.isOpen).toList());

  @override
  Stream<List<DeliveryException>> watchForRider(String riderId) =>
      _s.exceptions.watch().map((l) => l.where((e) => e.riderId == riderId).toList());

  @override
  Future<List<DeliveryException>> fetchExceptionHistory({
    int limit = 20,
    DeliveryException? startAfter,
  }) async {
    final list = await _s.exceptions.watch().first;
    final closed = list.where((e) => !e.status.isOpen).toList();
    closed.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    if (startAfter != null) {
      final index = closed.indexWhere((e) => e.id == startAfter.id);
      if (index != -1 && index + 1 < closed.length) {
        return closed.skip(index + 1).take(limit).toList();
      }
      return [];
    }
    return closed.take(limit).toList();
  }

  @override
  Future<void> report(DeliveryException exception, String byUid) async {
    if (_s.exceptionById(exception.id) != null) return; // idempotent
    final o = _s.requireOrder(exception.orderId);
    if (o.riderId != byUid) throw const AppException('This delivery is not assigned to you.');
    if (!o.status.isActive) throw const AppException('Only active deliveries can be reported.');
    _s.addException(exception);
    _s.putOrder(
      o.copyWith(
        status: OrderStatus.failed,
        history: [
          ...o.history,
          StatusEntry(
            status: OrderStatus.failed,
            at: DateTime.now(),
            byUid: byUid,
            note: 'Exception: ${exception.reason.label}',
          ),
        ],
      ),
    );
    _s.refreshRider(byUid);
    _s.notify(
      to: 'admin',
      type: NotificationType.exceptionUpdate,
      title: 'Exception reported',
      body: '${o.id} - ${exception.reason.label} (${exception.riderName} #${exception.riderStaffId}).',
      orderId: o.id,
    );
    _s.audit('exception.report', byUid, exception.id, {'orderId': o.id});
  }

  @override
  Future<void> resolve({
    required String exceptionId,
    required ExceptionStatus outcome,
    required String byUid,
    String? note,
    String? newRiderId,
    DateTime? newStart,
    DateTime? newEnd,
  }) async {
    final ex = _s.exceptionById(exceptionId) ?? (throw const AppException('Exception not found.'));
    if (!ex.status.isOpen) throw const AppException('This exception is already closed.');
    final noteText = (note ?? '').trim();
    // Dispatcher ka message rider ki notification mein jata hai
    final suffix = noteText.isEmpty ? '' : ' Note: $noteText';
    switch (outcome) {
      case ExceptionStatus.rescheduled:
        if (newStart == null || newEnd == null) throw const AppException('Pick a new delivery window.');
        _s.rescheduleOrder(orderId: ex.orderId, start: newStart, end: newEnd, byUid: byUid);
        if (noteText.isNotEmpty) {
          _s.notify(
            to: ex.riderId,
            type: NotificationType.exceptionUpdate,
            title: 'Dispatcher message',
            body: 'Order ${ex.orderId} rescheduled.$suffix',
            orderId: ex.orderId,
          );
        }
        break;
      case ExceptionStatus.reassigned:
        if (newRiderId == null) throw const AppException('Select a courier.');
        _s.assignOrder(orderId: ex.orderId, riderId: newRiderId, byUid: byUid, note: 'Reassigned after exception');
        if (newRiderId != ex.riderId) {
          _s.notify(
            to: ex.riderId,
            type: NotificationType.exceptionUpdate,
            title: 'Delivery reassigned',
            body: 'Order ${ex.orderId} was moved to another courier.$suffix',
            orderId: ex.orderId,
          );
        }
        break;
      case ExceptionStatus.rto:
        final o = _s.requireOrder(ex.orderId);
        _s.putOrder(
          o.copyWith(
            history: [
              ...o.history,
              StatusEntry(status: OrderStatus.failed, at: DateTime.now(), byUid: byUid, note: 'Return to origin'),
            ],
          ),
        );
        _s.notify(
          to: ex.riderId,
          type: NotificationType.exceptionUpdate,
          title: 'Return to origin',
          body: 'Return ${ex.orderId} to the hub.$suffix',
          orderId: ex.orderId,
        );
        break;
      case ExceptionStatus.resolved:
        _s.notify(
          to: ex.riderId,
          type: NotificationType.exceptionUpdate,
          title: 'Exception resolved',
          body: 'Dispatcher closed the report for ${ex.orderId}.$suffix',
          orderId: ex.orderId,
        );
        break;
      case ExceptionStatus.reported:
        throw const AppException('Invalid resolution.');
    }
    _s.putException(
      ex.copyWith(status: outcome, resolutionNote: note, resolvedAt: DateTime.now(), resolvedBy: byUid),
    );
    _s.audit('exception.resolve', byUid, exceptionId, {'outcome': outcome.name});
  }
}