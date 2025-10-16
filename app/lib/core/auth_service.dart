import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  const AuthUser({required this.uid, required this.isAnonymous});

  final String uid;
  final bool isAnonymous;
}

abstract class AuthService extends ChangeNotifier {
  AuthUser? get currentUser;

  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  Future<AuthUser> ensureSignedIn();

  Future<void> signOut();

  Future<AuthUser> signInAnonymously();

  Future<AuthUser> signUpWithEmailPassword(String email, String password);

  Future<AuthUser> signInWithEmailPassword(String email, String password);
}

class FirebaseAuthService extends AuthService {
  FirebaseAuthService(this._auth) {
    _subscription = _auth.authStateChanges().listen((user) {
      _currentUser = user == null
          ? null
          : AuthUser(uid: user.uid, isAnonymous: user.isAnonymous);
      notifyListeners();
    });
    final user = _auth.currentUser;
    if (user != null) {
      _currentUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous);
    }
  }

  final FirebaseAuth _auth;
  AuthUser? _currentUser;
  StreamSubscription<User?>? _subscription;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> ensureSignedIn() async {
    if (_auth.currentUser != null) {
      return AuthUser(
          uid: _auth.currentUser!.uid,
          isAnonymous: _auth.currentUser!.isAnonymous);
    }
    return signInAnonymously();
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user!;
    _currentUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous);
    notifyListeners();
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  @override
  Future<AuthUser> signUpWithEmailPassword(
      String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    _currentUser = AuthUser(uid: user.uid, isAnonymous: false);
    notifyListeners();
    return _currentUser!;
  }

  @override
  Future<AuthUser> signInWithEmailPassword(
      String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    _currentUser = AuthUser(uid: user.uid, isAnonymous: false);
    notifyListeners();
    return _currentUser!;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class LocalAuthService extends AuthService {
  LocalAuthService() {
    _initialize();
  }

  static const String _uidKey = 'local_auth_uid';
  static const String _isAnonymousKey = 'local_auth_is_anonymous';
  static const String _emailKey = 'local_auth_email';

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString(_uidKey);
    final isAnonymous = prefs.getBool(_isAnonymousKey) ?? true;

    if (savedUid != null) {
      _currentUser = AuthUser(uid: savedUid, isAnonymous: isAnonymous);
    } else {
      // First time - generate and save a persistent UID
      final newUid = _generateLocalUid();
      await prefs.setString(_uidKey, newUid);
      await prefs.setBool(_isAnonymousKey, true);
      _currentUser = AuthUser(uid: newUid, isAnonymous: true);
    }
    notifyListeners();
  }

  @override
  Future<AuthUser> ensureSignedIn() async {
    if (_currentUser == null) {
      await _initialize();
    }
    return _currentUser!;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_uidKey) ?? _generateLocalUid();
    await prefs.setString(_uidKey, uid);
    await prefs.setBool(_isAnonymousKey, true);
    await prefs.remove(_emailKey);
    _currentUser = AuthUser(uid: uid, isAnonymous: true);
    notifyListeners();
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    // Generate a NEW UID on sign out to simulate a new anonymous user
    final newUid = _generateLocalUid();
    await prefs.setString(_uidKey, newUid);
    await prefs.setBool(_isAnonymousKey, true);
    await prefs.remove(_emailKey);
    _currentUser = AuthUser(uid: newUid, isAnonymous: true);
    notifyListeners();
  }

  @override
  Future<AuthUser> signUpWithEmailPassword(
      String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep existing UID if available, link it to the email account
    final uid = prefs.getString(_uidKey) ?? _generateLocalUid();
    await prefs.setString(_uidKey, uid);
    await prefs.setBool(_isAnonymousKey, false);
    await prefs.setString(_emailKey, email);
    _currentUser = AuthUser(uid: uid, isAnonymous: false);
    notifyListeners();
    return _currentUser!;
  }

  @override
  Future<AuthUser> signInWithEmailPassword(
      String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // For sign-in, retrieve the existing UID associated with this email
    // In a real implementation, this would validate credentials
    // For local mock, we'll use the stored UID or generate one
    final uid = prefs.getString(_uidKey) ?? _generateLocalUid();
    await prefs.setString(_uidKey, uid);
    await prefs.setBool(_isAnonymousKey, false);
    await prefs.setString(_emailKey, email);
    _currentUser = AuthUser(uid: uid, isAnonymous: false);
    notifyListeners();
    return _currentUser!;
  }
}

String _generateLocalUid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  throw UnimplementedError('authServiceProvider must be overridden in main');
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.currentUser;
});
