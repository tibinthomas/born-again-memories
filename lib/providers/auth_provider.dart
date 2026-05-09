import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' show DriveApi;

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// macOS OAuth constants (reversed client ID = URL scheme already in Info.plist)
const _macOsClientId =
    '535814593524-6dnrg7ake15fjh9lv6ioelfg03o9af6c.apps.googleusercontent.com';
const _macOsRedirectUrl =
    'com.googleusercontent.apps.535814593524-6dnrg7ake15fjh9lv6ioelfg03o9af6c:/';

class AuthService {
  final _auth = FirebaseAuth.instance;
  late final googleSignIn = GoogleSignIn(
    clientId: _clientId,
    scopes: ['email', DriveApi.driveFileScope],
  );

  static String? get _clientId {
    if (kIsWeb) {
      return '535814593524-qnfs2h0978fkikcvueunqf8g6f7k3bot.apps.googleusercontent.com';
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return _macOsClientId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return '535814593524-2ivnq4cakusq84cd3c65la319getapt1.apps.googleusercontent.com';
    }
    return null;
  }

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    // On macOS, GIDSignIn v7 requires keychain-sharing which needs a signed
    // developer certificate. Use flutter_appauth (ASWebAuthenticationSession)
    // instead — it handles the OAuth flow without any keychain dependency.
    if (!kIsWeb && Platform.isMacOS) {
      return _signInWithGoogleMacOS();
    }
    return _signInWithGoogleNative();
  }

  Future<UserCredential?> _signInWithGoogleMacOS() async {
    const appAuth = FlutterAppAuth();
    final result = await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _macOsClientId,
        _macOsRedirectUrl,
        discoveryUrl:
            'https://accounts.google.com/.well-known/openid-configuration',
        scopes: ['openid', 'email', 'profile', DriveApi.driveFileScope],
      ),
    );
    if (result == null) return null;
    final credential = GoogleAuthProvider.credential(
      accessToken: result.accessToken,
      idToken: result.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> _signInWithGoogleNative() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    try {
      await googleSignIn.requestScopes([DriveApi.driveFileScope]);
    } catch (_) {}

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      googleSignIn.signOut(),
    ]);
  }

  Future<void> reauthenticateAndDelete() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final user = _auth.currentUser!;
    await user.reauthenticateWithCredential(credential);
    await user.delete();
    await googleSignIn.signOut();
  }
}
