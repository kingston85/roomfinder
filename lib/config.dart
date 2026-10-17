import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// All settings come from --dart-define values (set as GitHub secrets and
/// passed in by the build workflow). Nothing secret lives in the code:
/// Firebase web keys are public by design; the Firestore rules protect data.
class AppConfig {
  static const appName = 'RoomFinder LR';

  // Firebase (from the Firebase console > Project settings > Your apps)
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appIdAndroid = String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
  static const _appIdWeb = String.fromEnvironment('FIREBASE_APP_ID_WEB');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  // Cloudinary free plan: cloud name + an UNSIGNED upload preset
  static const cloudinaryCloud = String.fromEnvironment('CLOUDINARY_CLOUD');
  static const cloudinaryPreset = String.fromEnvironment('CLOUDINARY_PRESET');

  /// Public address of the web app, used for share links,
  /// e.g. https://kingston85.github.io/roomfinder
  static const webBaseUrl = String.fromEnvironment('WEB_BASE_URL');

  /// Rough exchange rate used only to compare LRD and USD prices in filters.
  /// Update when the rate moves.
  static const _lrdPerUsdText = String.fromEnvironment('LRD_PER_USD');
  static double get lrdPerUsd => double.tryParse(_lrdPerUsdText) ?? 190;

  /// Listings not confirmed within this many days are hidden from search.
  static const freshDays = 14;

  static bool get isConfigured =>
      _apiKey.isNotEmpty && _projectId.isNotEmpty && _senderId.isNotEmpty &&
      (kIsWeb ? _appIdWeb.isNotEmpty : _appIdAndroid.isNotEmpty);

  static FirebaseOptions get firebaseOptions => FirebaseOptions(
        apiKey: _apiKey,
        appId: kIsWeb ? _appIdWeb : _appIdAndroid,
        messagingSenderId: _senderId,
        projectId: _projectId,
        authDomain: _authDomain.isEmpty ? '$_projectId.firebaseapp.com' : _authDomain,
      );
}
