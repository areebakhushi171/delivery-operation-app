import 'enums.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.staffId = '',
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String staffId;
  final String? photoUrl;

  String get firstName => name.split(' ').first;

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'name': name, 'email': email, 'role': role.name, 'staffId': staffId, 'photoUrl': photoUrl};

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        uid: m['uid'] as String? ?? '',
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        role: UserRole.parse(m['role'] as String?),
        staffId: m['staffId'] as String? ?? '',
        photoUrl: m['photoUrl'] as String?,
      );
}
