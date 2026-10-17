import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/listing.dart';

/// Keeps track of who is signed in and their profile (users/{uid}).
class Session extends ChangeNotifier {
  Session._() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  static final Session instance = Session._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _profileSub;

  User? user;
  AppUser? profile;

  bool get signedIn => user != null;
  bool get isAdmin => profile?.isAdmin ?? false;
  bool get canList => profile?.canList ?? false;
  bool get isBanned => profile?.banned ?? false;

  void _onAuthChanged(User? u) {
    user = u;
    _profileSub?.cancel();
    if (u == null) {
      profile = null;
      notifyListeners();
      return;
    }
    final ref = _db.collection('users').doc(u.uid);
    _profileSub = ref.snapshots().listen((snap) async {
      if (!snap.exists) {
        await ref.set({
          'name': u.displayName ?? '',
          'email': u.email ?? '',
          'phone': u.phoneNumber ?? '',
          'whatsapp': '',
          'role': 'renter',
          'banned': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return; // the snapshot listener fires again with the new doc
      }
      profile = AppUser.fromDoc(snap);
      notifyListeners();
    }, onError: (_) {
      profile = null;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> createAccount(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user?.updateDisplayName(name.trim());
    // The profile doc may already exist with an empty name, or not exist yet;
    // a merge with the default fields works for both (see firestore.rules).
    await _db.collection('users').doc(cred.user!.uid).set(
      {
        'name': name.trim(),
        'email': email.trim(),
        'role': 'renter',
        'banned': false,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String whatsapp,
    required String role,
  }) {
    final data = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'whatsapp': whatsapp.trim(),
    };
    // Admins keep their role; everyone else can switch between the three.
    if (!isAdmin) data['role'] = role;
    return _db.collection('users').doc(user!.uid).set(data, SetOptions(merge: true));
  }
}
