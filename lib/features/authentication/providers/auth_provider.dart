import '../../../core/data/data.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/constants/app_constants.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends BaseProvider {
  AuthProvider(this._repo, this._storage);

  final AuthRepository _repo;
  final LocalStorage _storage;
  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;

  AuthStatus get status => _status;
  AppUser? get user => _user;

  String? get rememberedIdentifier => _storage.getString(StorageKeys.rememberedId);
  UserRole get rememberedRole =>
      UserRole.parse(_storage.getString(StorageKeys.rememberedRole));

  Future<void> initialize() async {
    final started = DateTime.now();
    AppUser? restored;
    try {
      restored = await _repo.restoreSession();
    } catch (_) {
      restored = null;
    }
    final remaining = AppConstants.splashDuration - DateTime.now().difference(started);
    if (!remaining.isNegative) await Future<void>.delayed(remaining);
    _user = restored;
    _status = restored == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<bool> signIn({
    required String identifier,
    required String password,
    required UserRole role,
    required bool remember,
  }) async {
    final u = await guard(
      () => _repo.signIn(identifier: identifier, password: password, role: role),
    );
    if (u == null) return false;
    if (remember) {
      await _storage.setString(StorageKeys.rememberedId, identifier.trim());
      await _storage.setString(StorageKeys.rememberedRole, role.name);
    } else {
      await _storage.remove(StorageKeys.rememberedId);
      await _storage.remove(StorageKeys.rememberedRole);
    }
    _user = u;
    _status = AuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  Future<bool> signUpRider({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String vehicleReg,
  }) async {
    final u = await guard(
      () => _repo.signUpRider(
        name: name,
        email: email,
        phone: phone,
        password: password,
        vehicleType: vehicleType,
        vehicleReg: vehicleReg,
      ),
    );
    if (u == null) return false;
    await _storage.setString(StorageKeys.rememberedId, email.trim());
    await _storage.setString(StorageKeys.rememberedRole, UserRole.rider.name);
    _user = u;
    _status = AuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  Future<bool> sendPasswordReset(String email) async {
    final ok = await guard(() async {
      await _repo.sendPasswordReset(email);
      return true;
    });
    return ok ?? false;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _status = AuthStatus.signedOut;
    setError(null);
    notifyListeners();
  }

  void clearError() {
    setError(null);
    notifyListeners();
  }
}
