class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email address';
  }

  /// Email OR numeric staff id (optionally prefixed with #).
  static String? identifier(String? v) {
    if (v == null || v.trim().isEmpty) return 'Staff ID or email is required';
    final t = v.trim();
    if (t.contains('@')) return email(t);
    return RegExp(r'^#?\w{2,}$').hasMatch(t) ? null : 'Enter a valid Staff ID';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return v.length < 6 ? 'Password must be at least 6 characters' : null;
  }

  static String? confirmPassword(String? v, String? originalPassword) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    return v == originalPassword ? null : 'Passwords do not match';
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'[\s\-+()]'), '');
    return RegExp(r'^\d{10,13}$').hasMatch(digits) ? null : 'Enter a valid phone number';
  }

  static String? positiveInt(String? v, [String field = 'Value']) {
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n <= 0) ? '$field must be a positive number' : null;
  }

  static String? amount(String? v, [String field = 'Amount']) {
    final n = int.tryParse((v ?? '').trim().replaceAll(',', ''));
    return (n == null || n <= 0) ? '$field must be greater than 0' : null;
  }

  static String? optionalCoordinate(String? v, {required bool isLat}) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    if (n == null) return 'Invalid number';
    final max = isLat ? 90 : 180;
    return n.abs() > max ? 'Out of range' : null;
  }
}
