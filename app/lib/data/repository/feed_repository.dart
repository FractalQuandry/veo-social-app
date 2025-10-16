import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/myway_api.dart';
import '../dto/feed_item_dto.dart';

final myWayApiProvider = Provider<MyWayApi>((ref) {
  return MyWayApi();
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(myWayApiProvider));
});

class FeedRepository {
  FeedRepository(this._api);

  final MyWayApi _api;

  Future<FeedResponseDto> fetchFeed(String uid,
      {FeedType feedType = FeedType.hot, int page = 0}) {
    return _api.fetchFeed(uid: uid, feedType: feedType, page: page);
  }

  Future<String> enqueueImage(String uid, String prompt, String aspectRatio,
      {bool isPrivate = false,
      bool includeMe = false,
      List<String>? referenceImagePaths}) {
    return _api.enqueueImage(
        uid: uid,
        prompt: prompt,
        aspectRatio: aspectRatio,
        isPrivate: isPrivate,
        includeMe: includeMe,
        referenceImagePaths: referenceImagePaths);
  }

  Future<String> enqueueVideo(
      String uid, String prompt, String aspectRatio, int duration, bool audio,
      {bool isPrivate = false,
      bool includeMe = false,
      List<String>? referenceImagePaths}) {
    return _api.enqueueVideo(
        uid: uid,
        prompt: prompt,
        aspectRatio: aspectRatio,
        duration: duration,
        audio: audio,
        isPrivate: isPrivate,
        includeMe: includeMe,
        referenceImagePaths: referenceImagePaths);
  }

  Future<Map<String, dynamic>> jobStatus(String jobId) {
    return _api.jobStatus(jobId);
  }

  Future<List<String>> moreLikeThis(String uid, String postId) {
    return _api.moreLikeThis(uid: uid, postId: postId);
  }
}
