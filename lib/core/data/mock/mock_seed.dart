import '../models/models.dart';

class MockSnapshot {
  const MockSnapshot({
    required this.orders,
    required this.riders,
    required this.exceptions,
    required this.notifications,
  });
  final List<DeliveryOrder> orders;
  final List<Rider> riders;
  final List<DeliveryException> exceptions;
  final List<AppNotification> notifications;
}

/// DEVELOPMENT SEED DATA ONLY (used when DATA_SOURCE=mock).
/// Never shipped to production Firestore. Times are relative to "now" so the
/// demo always looks current.
class MockSeed {
  MockSeed._();

  static const adminUid = 'admin_1';
  static const zubair = 'rider_408';
  static const tariq = 'rider_415';
  static const ayesha = 'rider_421';
  static const bilal = 'rider_432';

  static MockSnapshot build(DateTime now) {
    DateTime m(int mins) => now.add(Duration(minutes: mins));
    StatusEntry h(OrderStatus s, int mins, String by, [String? note]) =>
        StatusEntry(status: s, at: m(mins), byUid: by, note: note);

    DeliveryOrder order({
      required String id,
      required String customer,
      required String phone,
      required String address,
      required String area,
      required double lat,
      required double lng,
      required OrderStatus status,
      required int winStart,
      required int winEnd,
      required List<StatusEntry> history,
      required List<OrderItem> items,
      String city = 'Islamabad',
      String? rider,
      int? stop,
      int? eta,
      double km = 2,
      PaymentType pay = PaymentType.prepaid,
      int cod = 0,
      int prepaid = 0,
      String notes = '',
      String category = 'General',
      bool collected = false,
      bool deposited = false,
    }) =>
        DeliveryOrder(
          id: id,
          customerName: customer,
          customerPhone: phone,
          address: address,
          city: city,
          area: area,
          lat: lat,
          lng: lng,
          items: items,
          instructions: notes,
          paymentType: pay,
          codAmount: cod,
          prepaidAmount: prepaid,
          windowStart: m(winStart),
          windowEnd: m(winEnd),
          category: category,
          status: status,
          riderId: rider,
          stopNumber: stop,
          etaMinutes: eta,
          distanceKm: km,
          createdAt: m(-420),
          history: history,
          codCollected: collected,
          codDeposited: deposited,
        );

    final today = <DeliveryOrder>[
      // ---- Zubair Ahmed #408 ----
      order(
        id: 'PK-9817', customer: 'Sana Ahmed', phone: '+92 300 5550117',
        address: 'Shop 4, Markaz', area: 'Sector G-9', lat: 33.6950, lng: 73.0310,
        status: OrderStatus.delivered, rider: zubair, stop: 18, km: 3.1,
        pay: PaymentType.cod, cod: 2100, collected: true,
        winStart: -210, winEnd: -120, category: 'Grocery',
        items: const [OrderItem(name: 'Grocery Box', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -300, adminUid),
          h(OrderStatus.pickedUp, -240, zubair),
          h(OrderStatus.outForDelivery, -200, zubair),
          h(OrderStatus.delivered, -150, zubair),
        ],
      ),
      order(
        id: 'PK-9819', customer: 'Usman Tariq', phone: '+92 300 5550119',
        address: 'House 12, Street 9', area: 'Sector F-8', lat: 33.7120, lng: 73.0400,
        status: OrderStatus.delivered, rider: zubair, stop: 19, km: 2.4,
        prepaid: 3200, winStart: -120, winEnd: -45, category: 'Electronics',
        items: const [OrderItem(name: 'Wireless Earbuds', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -300, adminUid),
          h(OrderStatus.pickedUp, -150, zubair),
          h(OrderStatus.outForDelivery, -110, zubair),
          h(OrderStatus.delivered, -75, zubair),
        ],
      ),
      order(
        id: 'PK-9821', customer: 'Farhan Malik', phone: '+92 300 1234567',
        address: 'House 27, Street 5', area: 'Sector F-7', lat: 33.7210, lng: 73.0540,
        status: OrderStatus.outForDelivery, rider: zubair, stop: 20, eta: 5, km: 1.2,
        pay: PaymentType.cod, cod: 4500, winStart: -30, winEnd: 60,
        category: 'Grocery', notes: 'Please call before arrival.',
        items: const [OrderItem(name: 'Groceries Pack', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -240, adminUid),
          h(OrderStatus.pickedUp, -120, zubair),
          h(OrderStatus.outForDelivery, -40, zubair),
        ],
      ),
      order(
        id: 'PK-9824', customer: 'Hira Noor', phone: '+92 300 5550124',
        address: 'Flat 3, Block B', area: 'Sector E-7', lat: 33.7290, lng: 73.0420,
        status: OrderStatus.assigned, rider: zubair, stop: 21, km: 2.2,
        pay: PaymentType.cod, cod: 1800, winStart: 45, winEnd: 135, category: 'Pharmacy',
        items: const [OrderItem(name: 'Pharmacy Order', quantity: 2)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -50, adminUid),
        ],
      ),
      order(
        id: 'PK-9826', customer: 'Imran Shah', phone: '+92 300 5550126',
        address: 'House 8, Street 22', area: 'Sector G-6', lat: 33.7120, lng: 73.0770,
        status: OrderStatus.assigned, rider: zubair, stop: 22, km: 3.8,
        prepaid: 5600, winStart: 90, winEnd: 180, category: 'Electronics',
        items: const [OrderItem(name: 'Smart Speaker', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -45, adminUid),
        ],
      ),
      // ---- Tariq Mehmood #415 ----
      order(
        id: 'PK-9812', customer: 'Kamran Butt', phone: '+92 301 5550112',
        address: 'Office 5, Plaza 2', area: 'Blue Area', lat: 33.7100, lng: 73.0590,
        status: OrderStatus.delivered, rider: tariq, stop: 3, km: 2.9,
        pay: PaymentType.cod, cod: 3000, collected: true, winStart: -240, winEnd: -150,
        category: 'Documents', items: const [OrderItem(name: 'Document Parcel', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -330, adminUid),
          h(OrderStatus.pickedUp, -260, tariq),
          h(OrderStatus.outForDelivery, -200, tariq),
          h(OrderStatus.delivered, -170, tariq),
        ],
      ),
      order(
        id: 'PK-9815', customer: 'Hamza Qureshi', phone: '+92 301 5550115',
        address: 'House 91, Street 14', area: 'Sector I-8', lat: 33.6670, lng: 73.0700,
        status: OrderStatus.failed, rider: tariq, stop: 4, km: 4.6,
        pay: PaymentType.cod, cod: 8200, winStart: -90, winEnd: -20, category: 'Electronics',
        items: const [OrderItem(name: 'Tablet', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -300, adminUid),
          h(OrderStatus.pickedUp, -200, tariq),
          h(OrderStatus.outForDelivery, -80, tariq),
          h(OrderStatus.failed, -35, tariq, 'Exception: Customer Not Available'),
        ],
      ),
      order(
        id: 'PK-9828', customer: 'Nadia Khan', phone: '+92 301 5550128',
        address: 'House 40, Street 3', area: 'Sector G-10', lat: 33.6840, lng: 73.0150,
        status: OrderStatus.assigned, rider: tariq, stop: 5, km: 5.0,
        prepaid: 2400, winStart: 30, winEnd: 120,
        items: const [OrderItem(name: 'Gift Box', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -25, adminUid),
        ],
      ),
      // ---- Ayesha Siddiqui #421 ----
      order(
        id: 'PK-9810', customer: 'Tahir Mehmood', phone: '+92 302 5550110',
        address: 'Street 6, Phase 4', area: 'Bahria Town', city: 'Rawalpindi',
        lat: 33.5400, lng: 73.1100, status: OrderStatus.delivered, rider: ayesha, stop: 1,
        km: 6.2, prepaid: 1500, winStart: -300, winEnd: -200,
        items: const [OrderItem(name: 'Books', quantity: 3)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -380, adminUid),
          h(OrderStatus.pickedUp, -320, ayesha),
          h(OrderStatus.outForDelivery, -270, ayesha),
          h(OrderStatus.delivered, -230, ayesha),
        ],
      ),
      order(
        id: 'PK-9827', customer: 'Zara Sheikh', phone: '+92 302 5550127',
        address: 'House 17, Street 11', area: 'Bahria Town', city: 'Rawalpindi',
        lat: 33.5450, lng: 73.1150, status: OrderStatus.outForDelivery, rider: ayesha,
        stop: 2, eta: 12, km: 4.4, pay: PaymentType.cod, cod: 6750, winStart: -10, winEnd: 80,
        items: const [OrderItem(name: 'Home Decor Set', quantity: 1)],
        history: [
          h(OrderStatus.unassigned, -420, adminUid, 'Order created'),
          h(OrderStatus.assigned, -200, adminUid),
          h(OrderStatus.pickedUp, -90, ayesha),
          h(OrderStatus.outForDelivery, -25, ayesha),
        ],
      ),
      // ---- Unassigned ----
      order(
        id: 'PK-9830', customer: 'Saad Ali', phone: '+92 300 5550130',
        address: 'House 5, Street 18', area: 'Sector F-10', lat: 33.7000, lng: 73.0200,
        status: OrderStatus.unassigned, km: 0, pay: PaymentType.cod, cod: 3900,
        winStart: 60, winEnd: 150, category: 'Grocery',
        items: const [OrderItem(name: 'Weekly Grocery', quantity: 1)],
        history: [h(OrderStatus.unassigned, -15, adminUid, 'Order created')],
      ),
      order(
        id: 'PK-9831', customer: 'Maryam Javed', phone: '+92 300 5550131',
        address: 'Plot 22, Street 4', area: 'Sector I-10', lat: 33.6500, lng: 73.0400,
        status: OrderStatus.unassigned, km: 0, prepaid: 7800, winStart: 120, winEnd: 210,
        category: 'Electronics', items: const [OrderItem(name: 'Smart Watch', quantity: 1)],
        history: [h(OrderStatus.unassigned, -8, adminUid, 'Order created')],
      ),
    ];

    final dayStart = DateTime(now.year, now.month, now.day);
    final past = <DeliveryOrder>[];
    const pastRiders = [zubair, tariq, ayesha];
    const pastNames = ['Ali Raza', 'Fatima Khan', 'Bilal Rauf', 'Sidra Anwar', 'Omar Farooq', 'Hina Aslam'];
    for (var d = 1; d <= 6; d++) {
      for (var k = 0; k < 2; k++) {
        final idx = d * 2 + k;
        final day = dayStart.subtract(Duration(days: d));
        final start = day.add(Duration(hours: 10 + k * 3));
        final end = start.add(const Duration(hours: 1));
        final failed = idx % 7 == 0;
        final late = idx % 5 == 0;
        final finishedAt = late
            ? end.add(const Duration(minutes: 20))
            : end.subtract(const Duration(minutes: 15));
        final isCod = idx.isEven;
        final rid = pastRiders[idx % pastRiders.length];
        past.add(
          DeliveryOrder(
            id: 'PK-${9700 + idx}',
            customerName: pastNames[idx % pastNames.length],
            customerPhone: '+92 300 55501${idx.toString().padLeft(2, '0')}',
            address: 'House ${idx + 3}, Street ${idx + 1}',
            city: 'Islamabad',
            area: idx.isEven ? 'Sector F-6' : 'Sector G-11',
            lat: 33.70 + idx * 0.002,
            lng: 73.04 + idx * 0.002,
            items: const [OrderItem(name: 'Parcel', quantity: 1)],
            paymentType: isCod ? PaymentType.cod : PaymentType.prepaid,
            codAmount: isCod ? 1500 + idx * 250 : 0,
            prepaidAmount: isCod ? 0 : 1200 + idx * 200,
            windowStart: start,
            windowEnd: end,
            status: failed ? OrderStatus.failed : OrderStatus.delivered,
            riderId: rid,
            stopNumber: 1,
            createdAt: day.add(const Duration(hours: 8)),
            codCollected: isCod && !failed,
            codDeposited: isCod && !failed && d > 1,
            history: [
              StatusEntry(status: OrderStatus.assigned, at: start.subtract(const Duration(hours: 1)), byUid: adminUid),
              StatusEntry(status: OrderStatus.pickedUp, at: start.subtract(const Duration(minutes: 30)), byUid: rid),
              StatusEntry(
                status: OrderStatus.outForDelivery,
                at: finishedAt.subtract(const Duration(minutes: 25)),
                byUid: rid,
              ),
              StatusEntry(
                status: failed ? OrderStatus.failed : OrderStatus.delivered,
                at: finishedAt,
                byUid: rid,
                note: failed ? 'Exception: Wrong Address' : null,
              ),
            ],
          ),
        );
      }
    }

    final riders = <Rider>[
      Rider(
        id: zubair, staffId: '408', name: 'Zubair Ahmed', phone: '+92 300 4081234',
        email: 'zubair@demo.pk', vehicleType: 'Bike - Honda CG125', vehicleReg: 'ICT-408',
        dutyStatus: DutyStatus.onDuty, rating: 4.8, lat: 33.7185, lng: 73.0515,
        speedKmh: 24, battery: 88, heading: 45, currentOrderId: 'PK-9821', currentStop: 20,
        etaMinutes: 5, lastUpdated: m(-1), telemetrySource: 'seed',
      ),
      Rider(
        id: tariq, staffId: '415', name: 'Tariq Mehmood', phone: '+92 301 4155678',
        email: 'tariq@demo.pk', vehicleType: 'Bike - Suzuki GS150', vehicleReg: 'ICT-415',
        dutyStatus: DutyStatus.onDuty, rating: 4.5, lat: 33.7050, lng: 73.0450,
        speedKmh: 0, battery: 61, heading: 120, currentOrderId: 'PK-9828', currentStop: 5,
        etaMinutes: 18, lastUpdated: m(-2), telemetrySource: 'seed',
      ),
      Rider(
        id: ayesha, staffId: '421', name: 'Ayesha Siddiqui', phone: '+92 302 4219012',
        email: 'ayesha@demo.pk', vehicleType: 'Bike - Yamaha YBR125', vehicleReg: 'RWP-421',
        dutyStatus: DutyStatus.onDuty, rating: 4.9, lat: 33.5430, lng: 73.1130,
        speedKmh: 31, battery: 74, heading: 200, currentOrderId: 'PK-9827', currentStop: 2,
        etaMinutes: 12, lastUpdated: m(-1), telemetrySource: 'seed',
      ),
      Rider(
        id: bilal, staffId: '432', name: 'Bilal Hussain', phone: '+92 303 4323456',
        email: 'bilal@demo.pk', vehicleType: 'Van - Suzuki Bolan', vehicleReg: 'ICT-432',
        dutyStatus: DutyStatus.offDuty, rating: 4.3, lat: 33.6844, lng: 73.0479,
        battery: 100, lastUpdated: m(-600), telemetrySource: 'seed',
      ),
    ];

    final exceptions = <DeliveryException>[
      DeliveryException(
        id: 'EX-9815', orderId: 'PK-9815', customerName: 'Hamza Qureshi',
        riderId: tariq, riderName: 'Tariq Mehmood', riderStaffId: '415',
        reason: ExceptionReason.customerNotAvailable,
        description: 'Phone was switched off. Waited 15 minutes at the gate.',
        codAmount: 8200, reportedAt: m(-35),
      ),
    ];

    AppNotification n(String id, String to, NotificationType t, String title, String body, int mins,
            {String? orderId, bool read = false}) =>
        AppNotification(
          id: id, recipientId: to, type: t, title: title, body: body,
          createdAt: m(mins), orderId: orderId, read: read,
        );

    final notifications = <AppNotification>[
      n('seed_n1', zubair, NotificationType.assignment, 'New Assignment', 'Order PK-9826 assigned to you.', -45, orderId: 'PK-9826'),
      n('seed_n2', zubair, NotificationType.reminder, 'Reminder', 'Please complete pending deliveries.', -20),
      n('seed_n3', zubair, NotificationType.routeChange, 'Route Update', 'Your route has been optimized.', -180, read: true),
      n('seed_n4', tariq, NotificationType.exceptionUpdate, 'Exception received', 'Your report for PK-9815 is awaiting dispatcher triage.', -30, orderId: 'PK-9815'),
      n('seed_n5', 'admin', NotificationType.exceptionUpdate, 'Exception reported', 'PK-9815 - Customer Not Available (Tariq Mehmood #415).', -35, orderId: 'PK-9815'),
      n('seed_n6', 'admin', NotificationType.reminder, 'Unassigned orders', 'PK-9830 and PK-9831 still need riders.', -10),
    ];

    return MockSnapshot(
      orders: [...today, ...past],
      riders: riders,
      exceptions: exceptions,
      notifications: notifications,
    );
  }
}
