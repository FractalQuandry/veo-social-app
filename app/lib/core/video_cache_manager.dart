import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for videos with larger cache size and longer duration
class VideoCacheManager {
  static const key = 'myway_video_cache';

  static CacheManager get instance => CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 7), // Keep videos for 7 days
          maxNrOfCacheObjects: 100, // Max 100 videos
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
}
