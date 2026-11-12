import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registers the device FCM token on the user document. Actually *sending*
/// pushes needs a Cloud Function (not included) - in-app notifications work
/// through Firestore streams without it.
class PushService {
  PushService._();

  static Future<void> registerToken(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM registration skipped: $e');
    }
  }
}
