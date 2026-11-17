import '../../storage/local_storage.dart';
import '../../utils/utils.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_seed.dart';
import 'mock_store.dart';

/// Development-only credentials (mock mode). Never used with Firebase.
class MockCredentials {
  MockCredentials._();
  static const password = 'Demo@1234';
  static const riderEmail = 'zubair@demo.pk';
  static const adminEmail = 'admin@demo.pk';
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._store, this._storage);

  final MockStore _store;
  final LocalStorage _storage;

  static const _admin = AppUser(
    uid: MockSeed.adminUid,
    name: 'Dispatcher Admin',
    email: MockCredentials.adminEmail,
    role: UserRole.admin,
    staffId: 'A001',
  );

  AppUser? _findByIdentifier(String raw) {
    final id = raw.trim().toLowerCase().replaceAll('#', '');
    if (id == _admin.email || id == _admin.staffId.toLowerCase() || id == 'admin' || id.startsWith('admin') || id == 'a001') return _admin;
    for (final r in _store.riders.value) {
      if (r.email.toLowerCase() == id || r.staffId.toLowerCase() == id || id == r.name.toLowerCase() || id == r.id) {
        return AppUser(uid: r.id, name: r.name, email: r.email, role: UserRole.rider, staffId: r.staffId);
      }
    }
    return null;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final uid = _storage.getString(StorageKeys.mockSession);
    if (uid == null) return null;
    if (uid == _admin.uid) return _admin;
    final r = _store.riderById(uid);
    return r == null
        ? null
        : AppUser(uid: r.id, name: r.name, email: r.email, role: UserRole.rider, staffId: r.staffId);
  }

  @override
  Future<AppUser> signIn({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    var user = _findByIdentifier(identifier);
    if (user == null && role == UserRole.admin) {
      user = _admin;
    }
    if (user == null) {
      throw const AppException('Invalid credentials. Please check your ID and password.');
    }
    if (user.role != role) {
      throw AppException(
        role == UserRole.admin
            ? 'This account is not an Admin / Dispatcher account.'
            : 'This account is not a Rider account.',
      );
    }
    await _storage.setString(StorageKeys.mockSession, user.uid);
    return user;
  }

  @override
  Future<AppUser> signUpRider({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String vehicleReg,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final existing = _store.riders.value.where((r) => r.email.toLowerCase() == email.trim().toLowerCase()).toList();
    if (existing.isNotEmpty) {
      throw const AppException('An account with this email already exists.');
    }

    final id = 'rider-${DateTime.now().millisecondsSinceEpoch}';
    final staffId = 'R00${_store.riders.value.length + 1}';
    final newRider = Rider(
      id: id,
      staffId: staffId,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      vehicleType: vehicleType,
      vehicleReg: vehicleReg,
      dutyStatus: DutyStatus.onDuty,
    );

    final currentRiders = List<Rider>.from(_store.riders.value)..add(newRider);
    _store.riders.value = currentRiders;

    final user = AppUser(uid: id, name: name.trim(), email: email.trim(), role: UserRole.rider, staffId: staffId);
    await _storage.setString(StorageKeys.mockSession, user.uid);
    return user;
  }

  @override
  Future<void> signOut() => _storage.remove(StorageKeys.mockSession);

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_findByIdentifier(email) == null) {
      throw const AppException('No account found for this email.');
    }
  }
}
