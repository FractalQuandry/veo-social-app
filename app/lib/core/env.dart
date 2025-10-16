import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  static List<String> get apiBaseCandidates {
    final seen = <String>{};
    final candidates = <String>[];

    void add(String? value) {
      if (value == null) return;
      final normalized = value.trim();
      if (normalized.isEmpty) return;
      if (seen.add(normalized)) {
        candidates.add(normalized);
      }
    }

    final raw = dotenv.env['API_BASE_URL'];
    if (raw != null && raw.isNotEmpty) {
      for (final part in raw.split(',')) {
        add(part);
      }
    }

    if (candidates.isEmpty) {
      add('http://localhost:8000');
    }

    if (candidates
        .any((url) => url.contains('localhost') || url.contains('127.0.0.1'))) {
      add('http://10.0.2.2:8000');
    }

    add(dotenv.env['API_BASE_URL_FALLBACK']);

    return candidates;
  }

  static Duration get apiConnectTimeout => const Duration(seconds: 5);

  static Duration get apiReceiveTimeout => const Duration(seconds: 120);
  static int get maxFreeViews => int.parse(dotenv.env['MAX_FREE_VIEWS'] ?? '8');
  static int get maxFreeDepth => int.parse(dotenv.env['MAX_FREE_DEPTH'] ?? '2');
  static double get feedShareInterest =>
      double.parse(dotenv.env['FEED_SHARE_INTEREST'] ?? '0.60');
  static double get feedShareExplore =>
      double.parse(dotenv.env['FEED_SHARE_EXPLORE'] ?? '0.25');
  static double get feedShareTrending =>
      double.parse(dotenv.env['FEED_SHARE_TRENDING'] ?? '0.15');
  static int get generateTimeoutMs =>
      int.parse(dotenv.env['GENERATE_TIMEOUT_MS'] ?? '800');

  static String? get firebaseApiKey => dotenv.env['FIREBASE_WEB_API_KEY'];
  static String? get firebaseAppId => dotenv.env['FIREBASE_APP_ID'];
  static String? get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
  static String? get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'];
  static String? get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'];

  static FirebaseOptions? get firebaseOptions {
    final apiKey = firebaseApiKey;
    final appId = firebaseAppId;
    final sender = firebaseMessagingSenderId;
    final projectId = firebaseProjectId;
    final hasMissing = [apiKey, appId, sender, projectId]
        .any((element) => element?.isEmpty ?? true);
    if (hasMissing) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey!,
      appId: appId!,
      messagingSenderId: sender!,
      projectId: projectId!,
      storageBucket: firebaseStorageBucket,
    );
  }
}
