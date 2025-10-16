import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'logger.dart';

class RemoteConfigValues {
  const RemoteConfigValues({
    required this.maxFreeViews,
    required this.maxFreeDepth,
    required this.feedShareInterest,
    required this.feedShareExplore,
    required this.feedShareTrending,
    required this.generateTimeoutMs,
  });

  final int maxFreeViews;
  final int maxFreeDepth;
  final double feedShareInterest;
  final double feedShareExplore;
  final double feedShareTrending;
  final int generateTimeoutMs;
}

class RemoteConfigService {
  RemoteConfigService([FirebaseRemoteConfig? remoteConfig])
      : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig? _remoteConfig;

  Future<void> initialize() async {
    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) {
      AppLogger.warn('Remote Config disabled; using local defaults');
      return;
    }
    await remoteConfig.setDefaults(defaultValues);
    try {
      await remoteConfig.fetchAndActivate();
    } catch (err, stack) {
      AppLogger.warn('RemoteConfig fetch failed', err);
      AppLogger.error('RemoteConfig stack', err, stack);
    }
  }

  RemoteConfigValues get current {
    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) {
      return _defaultRemoteConfigValues();
    }
    return RemoteConfigValues(
      maxFreeViews: remoteConfig.getInt('maxFreeViews'),
      maxFreeDepth: remoteConfig.getInt('maxFreeDepth'),
      feedShareInterest: remoteConfig.getDouble('feedShareInterest'),
      feedShareExplore: remoteConfig.getDouble('feedShareExplore'),
      feedShareTrending: remoteConfig.getDouble('feedShareTrending'),
      generateTimeoutMs: remoteConfig.getInt('generateTimeoutMs'),
    );
  }
}

final remoteConfigProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});

final remoteConfigValuesProvider = Provider<RemoteConfigValues>((ref) {
  final service = ref.watch(remoteConfigProvider);
  return service.current;
});

const Map<String, Object> defaultValues = {
  'maxFreeViews': 8,
  'maxFreeDepth': 2,
  'feedShareInterest': 0.6,
  'feedShareExplore': 0.25,
  'feedShareTrending': 0.15,
  'generateTimeoutMs': 800,
};

RemoteConfigValues _defaultRemoteConfigValues() {
  return RemoteConfigValues(
    maxFreeViews: Env.maxFreeViews,
    maxFreeDepth: Env.maxFreeDepth,
    feedShareInterest: Env.feedShareInterest,
    feedShareExplore: Env.feedShareExplore,
    feedShareTrending: Env.feedShareTrending,
    generateTimeoutMs: Env.generateTimeoutMs,
  );
}
