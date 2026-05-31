import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' show DriveApi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/firestore_service.dart';

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
    // serverClientId is required on Android to get a valid idToken for Firebase,
    // but is unsupported on web (clientId already covers it there).
    serverClientId: kIsWeb ? null : '535814593524-qnfs2h0978fkikcvueunqf8g6f7k3bot.apps.googleusercontent.com',
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

  bool get isAppleUser =>
      !kIsWeb &&
      !kIsWeb && (Platform.isIOS || Platform.isMacOS) &&
      (_auth.currentUser?.providerData.any((p) => p.providerId == 'apple.com') ??
          false);

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

  Future<UserCredential?> signInWithApple() async {
    if (kIsWeb) {
      throw UnsupportedError('Apple Sign In is not supported on web.');
    }
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple Sign In is only available on Apple platforms.');
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    return _auth.signInWithCredential(oauthCredential);
  }

  Future<void> _reauthWithGoogle(User user) async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _reauthWithApple(User user) async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
    await user.reauthenticateWithCredential(credential);
  }

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!isAppleUser) await googleSignIn.signOut();
  }

  Future<void> reauthenticateAndDelete() async {
    final user = _auth.currentUser!;
    if (isAppleUser) {
      await _reauthWithApple(user);
    } else {
      await _reauthWithGoogle(user);
    }
    await user.delete();
    if (!isAppleUser) await googleSignIn.signOut();
  }

  // Marks the account for deletion (data kept 28 days) then signs out.
  // Does NOT delete the Firebase Auth account so the user can sign back in to recover.
  Future<void> softDeleteAccount({required bool deleteDriveBackup}) async {
    final user = _auth.currentUser!;
    if (isAppleUser) {
      await _reauthWithApple(user);
    } else {
      await _reauthWithGoogle(user);
    }
    await FirestoreService.markAccountForDeletion(
      uid: user.uid,
      deleteDriveBackup: deleteDriveBackup,
    );
    await _auth.signOut();
    if (!isAppleUser) await googleSignIn.signOut();
  }

  Future<void> recoverAccount(String uid) =>
      FirestoreService.recoverAccount(uid);

  // Called after the 28-day window expires — permanently removes the Firebase Auth account.
  Future<void> permanentlyDelete() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {}
    try {
      await googleSignIn.signOut();
    } catch (_) {}
  }
}
