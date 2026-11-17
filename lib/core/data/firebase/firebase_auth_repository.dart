import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/app_config.dart';
import '../../services/push_service.dart';
import '../../utils/utils.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<AppUser> _profile(User u) async {
    final doc = await _db.collection('users').doc(u.uid).get();
    if (!doc.exists) {
      // If user exists in Auth but not Firestore, create default user doc if rider
      final fallbackUser = {
        'uid': u.uid,
        'name': u.displayName ?? u.email?.split('@').first ?? 'User',
        'email': u.email ?? '',
        'role': 'rider',
        'staffId': 'R${u.uid.substring(0, 4).toUpperCase()}',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _db.collection('users').doc(u.uid).set(fallbackUser);
      return AppUser.fromMap(fallbackUser);
    }
    return AppUser.fromMap({...doc.data()!, 'uid': u.uid, 'email': u.email ?? ''});
  }

  @override
  Future<AppUser?> restoreSession() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    try {
      return await _profile(u);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> signIn({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    final id = identifier.trim();
    final email = id.contains('@')
        ? id
        : '${id.replaceAll('#', '')}@${AppConfig.staffEmailDomain}';
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = await _profile(cred.user!);
      if (user.role != role) {
        await _auth.signOut();
        throw AppException(
          role == UserRole.admin
              ? 'This account is not an Admin / Dispatcher account.'
              : 'This account is not a Rider account.',
        );
      }
      unawaited(PushService.registerToken(user.uid));
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'network-request-failed':
          throw const AppException('No internet connection.');
        case 'too-many-requests':
          throw const AppException('Too many attempts. Try again later.');
        case 'user-not-found':
          throw const AppException('No account found for this email.');
        case 'wrong-password':
        case 'invalid-credential':
          throw const AppException('Incorrect password or credentials.');
        case 'operation-not-allowed':
          throw const AppException('Email/Password sign-in is disabled in Firebase Console.');
        default:
          throw AppException(e.message ?? 'Invalid credentials. Please check your ID and password.');
      }
    }
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
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      final staffId = 'R${uid.substring(0, 4).toUpperCase()}';

      final userMap = {
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': 'rider',
        'staffId': staffId,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _db.collection('users').doc(uid).set(userMap);

      final riderMap = {
        'id': uid,
        'staffId': staffId,
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'dutyStatus': 'onDuty',
        'vehicleType': vehicleType,
        'vehicleReg': vehicleReg,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _db.collection('riders').doc(uid).set(riderMap);

      final user = AppUser(uid: uid, name: name.trim(), email: email.trim(), role: UserRole.rider, staffId: staffId);
      unawaited(PushService.registerToken(uid));
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') throw const AppException('Email address is already in use.');
      if (e.code == 'weak-password') throw const AppException('Password should be at least 6 characters.');
      if (e.code == 'operation-not-allowed') throw const AppException('Email/Password sign-in is disabled in Firebase Console.');
      throw AppException(e.message ?? 'Registration failed.');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw const AppException('No internet connection.');
    }
  }
}
