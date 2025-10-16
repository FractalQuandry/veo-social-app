import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_service.dart';
import '../../core/logger.dart';
import '../../data/dto/feed_item_dto.dart';
import '../../data/repository/feed_repository.dart';

const List<FeedItemDto> _offlineFeedItems = [
  FeedItemDto(
    slot: FeedSlot.fallback,
    reason: ['offline'],
    post: PostDto(
      id: 'offline-aether-neon',
      type: PostType.video,
      status: 'ready',
      storagePath: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
      duration: 6.0,
      aspect: '9:16',
      model: 'mock-video-labs',
      prompt: 'Neon street vendor shot at night, cinematic drone glide',
      seed: 9201,
      safety: SafetyInfoDto(blocked: false),
      synthId: true,
      authorUid: 'demo',
    ),
  ),
  FeedItemDto(
    slot: FeedSlot.fallback,
    reason: ['offline'],
    post: PostDto(
      id: 'offline-cozy-reading',
      type: PostType.image,
      status: 'ready',
      storagePath:
          'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=720&q=80',
      aspect: '9:16',
      model: 'mock-diffusion-v5',
      prompt: 'Cozy reading nook with rainy window and warm lamplight glow',
      seed: 7312,
      safety: SafetyInfoDto(blocked: false),
      synthId: true,
      authorUid: 'demo',
    ),
  ),
  FeedItemDto(
    slot: FeedSlot.fallback,
    reason: ['offline'],
    post: PostDto(
      id: 'offline-ocean-dawn',
      type: PostType.image,
      status: 'ready',
      storagePath:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=720&q=80',
      aspect: '9:16',
      model: 'mock-diffusion-v5',
      prompt: 'Sunrise tide washing over black sand beach, long exposure',
      seed: 5820,
      safety: SafetyInfoDto(blocked: false),
      synthId: true,
      authorUid: 'demo',
    ),
  ),
];

// Provider family to support different feed types
final feedControllerProvider =
    AsyncNotifierProvider.family<FeedController, List<FeedItemDto>, FeedType>(
        () {
  return FeedController();
});

// Pagination state provider
final feedPaginationProvider =
    StateProvider.family<FeedPaginationState, FeedType>((ref, feedType) {
  return FeedPaginationState(hasMore: true, nextPage: 0, isLoadingMore: false);
});

class FeedPaginationState {
  const FeedPaginationState({
    required this.hasMore,
    required this.nextPage,
    required this.isLoadingMore,
  });

  final bool hasMore;
  final int nextPage;
  final bool isLoadingMore;

  FeedPaginationState copyWith({
    bool? hasMore,
    int? nextPage,
    bool? isLoadingMore,
  }) {
    return FeedPaginationState(
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class FeedController extends FamilyAsyncNotifier<List<FeedItemDto>, FeedType> {
  Timer? _poller;
  FeedType get feedType => arg;

  @override
  Future<List<FeedItemDto>> build(FeedType arg) async {
    ref.onDispose(() => _poller?.cancel());
    final uid = _currentUid;
    if (uid == null) {
      return _offlineFeedItems;
    }
    final repo = ref.read(feedRepositoryProvider);
    try {
      final response = await repo.fetchFeed(uid, feedType: arg, page: 0);
      if (response.items.isEmpty) {
        AppLogger.info('Feed is empty - user has no content yet');
        return []; // Return empty list to trigger empty state UI
      }
      // Update pagination state
      ref.read(feedPaginationProvider(arg).notifier).state =
          FeedPaginationState(
        hasMore: response.hasMore,
        nextPage: response.nextPage,
        isLoadingMore: false,
      );
      _schedulePolling(response.items);
      return response.items;
    } catch (err, stack) {
      AppLogger.warn('Unable to load feed, falling back to offline demo', err);
      AppLogger.error('Feed load stack', err, stack);
      return _offlineFeedItems;
    }
  }

  Future<void> refresh() async {
    final uid = _currentUid;
    if (uid == null) {
      AppLogger.warn('Cannot refresh feed: uid is null');
      return;
    }
    AppLogger.info('Refreshing feed (${feedType.name}) for user: $uid');
    state = const AsyncLoading();
    final repo = ref.read(feedRepositoryProvider);
    try {
      final response = await repo.fetchFeed(uid, feedType: feedType, page: 0);
      AppLogger.info(
          'Feed refresh successful (${feedType.name}): received ${response.items.length} items, hasMore=${response.hasMore}');
      for (var item in response.items) {
        final isPrivate = item.post?.isPrivate ?? false;
        AppLogger.info(
            '  - ${item.slot} | ${item.post?.id ?? "no-post"} | private=$isPrivate | ${item.post?.prompt ?? ""}');
      }
      // Reset pagination state
      ref.read(feedPaginationProvider(feedType).notifier).state =
          FeedPaginationState(
        hasMore: response.hasMore,
        nextPage: response.nextPage,
        isLoadingMore: false,
      );
      state = AsyncData(response.items);
      _schedulePolling(response.items);
    } catch (err, stack) {
      AppLogger.warn('Feed refresh failed, falling back to offline demo', err);
      AppLogger.error('Feed refresh error details', err, stack);
      state = const AsyncData<List<FeedItemDto>>(_offlineFeedItems);
    }
  }

  Future<void> loadMore() async {
    final uid = _currentUid;
    if (uid == null) return;

    final paginationState = ref.read(feedPaginationProvider(feedType));
    if (!paginationState.hasMore || paginationState.isLoadingMore) {
      AppLogger.info(
          'Cannot load more: hasMore=${paginationState.hasMore}, isLoadingMore=${paginationState.isLoadingMore}');
      return;
    }

    final currentItems = state.valueOrNull ?? [];
    if (currentItems.isEmpty) return;

    AppLogger.info(
        'Loading more items for feed ${feedType.name}, page=${paginationState.nextPage}');

    // Set loading state
    ref.read(feedPaginationProvider(feedType).notifier).state =
        paginationState.copyWith(isLoadingMore: true);

    final repo = ref.read(feedRepositoryProvider);
    try {
      final response = await repo.fetchFeed(
        uid,
        feedType: feedType,
        page: paginationState.nextPage,
      );

      AppLogger.info(
          'Load more successful: received ${response.items.length} new items, hasMore=${response.hasMore}');

      // Append new items to existing list
      final updatedItems = [...currentItems, ...response.items];
      state = AsyncData(updatedItems);

      // Update pagination state
      ref.read(feedPaginationProvider(feedType).notifier).state =
          FeedPaginationState(
        hasMore: response.hasMore,
        nextPage: response.nextPage,
        isLoadingMore: false,
      );

      _schedulePolling(updatedItems);
    } catch (err, stack) {
      AppLogger.error('Failed to load more items', err, stack);
      // Reset loading state on error
      ref.read(feedPaginationProvider(feedType).notifier).state =
          paginationState.copyWith(isLoadingMore: false);
    }
  }

  void addOptimisticPending(String prompt, String mediaType,
      {String aspectRatio = '9:16'}) {
    // Add a temporary pending item to show immediately
    final current = state.valueOrNull ?? [];
    final pendingItem = FeedItemDto(
      slot: FeedSlot.pending,
      jobId: 'optimistic-${DateTime.now().millisecondsSinceEpoch}',
      reason: ['composer'],
    );
    state = AsyncData([pendingItem, ...current]);
    AppLogger.info(
        'Added optimistic pending item for $mediaType ($aspectRatio): "$prompt"');
  }

  Future<void> enqueuePrompt(String prompt,
      {String mediaType = 'image',
      String aspectRatio = '9:16',
      int duration = 6,
      bool audio = true,
      bool isPrivate = false,
      bool includeMe = false,
      List<String>? referenceImagePaths}) async {
    final uid = _currentUid;
    if (uid == null) {
      AppLogger.warn('Cannot enqueue: uid is null');
      return;
    }
    AppLogger.info(
        'Enqueueing $mediaType ($aspectRatio, ${duration}s, audio=$audio, private=$isPrivate, includeMe=$includeMe, referenceImages=${referenceImagePaths?.length ?? 0}) for user $uid on feed ${feedType.name}: "$prompt"');
    final repo = ref.read(feedRepositoryProvider);
    try {
      if (mediaType == 'video') {
        final jobId = await repo.enqueueVideo(
            uid, prompt, aspectRatio, duration, audio,
            isPrivate: isPrivate,
            includeMe: includeMe,
            referenceImagePaths: referenceImagePaths);
        AppLogger.info(
            'Video ($duration sec, audio=$audio, private=$isPrivate, includeMe=$includeMe, referenceImages=${referenceImagePaths?.length ?? 0}) enqueued with jobId: $jobId');
      } else {
        final jobId = await repo.enqueueImage(uid, prompt, aspectRatio,
            isPrivate: isPrivate,
            includeMe: includeMe,
            referenceImagePaths: referenceImagePaths);
        AppLogger.info(
            'Image (private=$isPrivate, includeMe=$includeMe, referenceImages=${referenceImagePaths?.length ?? 0}) enqueued with jobId: $jobId');
      }
      AppLogger.info(
          'Generation complete, waiting briefly for Firestore write...');
      // Small delay to ensure Firestore write completes
      await Future.delayed(const Duration(milliseconds: 500));
      AppLogger.info('Refreshing feed ${feedType.name}...');
      await refresh();
    } catch (err, stack) {
      AppLogger.error('Failed to enqueue $mediaType', err, stack);
      rethrow;
    }
  }

  void _schedulePolling(List<FeedItemDto> items) {
    _poller?.cancel();
    final hasPending = items
        .any((item) => item.slot == FeedSlot.pending && item.jobId != null);
    if (!hasPending) {
      return;
    }
    _poller = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _pollPending();
    });
  }

  Future<void> _pollPending() async {
    final uid = _currentUid;
    if (uid == null) return;
    final current = state.valueOrNull;
    if (current == null || current.isEmpty) {
      return;
    }
    if (identical(current, _offlineFeedItems)) {
      return;
    }
    final pendingJobs = current
        .where((item) => item.slot == FeedSlot.pending && item.jobId != null)
        .toList();
    if (pendingJobs.isEmpty) {
      _poller?.cancel();
      return;
    }
    final repo = ref.read(feedRepositoryProvider);
    bool anyReady = false;
    for (final job in pendingJobs) {
      final status = await repo.jobStatus(job.jobId!);
      if (status['status'] == 'ready') {
        anyReady = true;
      }
    }
    if (anyReady) {
      AppLogger.info('Pending jobs resolved, refreshing feed ${feedType.name}');
      final response = await repo.fetchFeed(uid, feedType: feedType, page: 0);
      // Reset pagination state when polling detects new ready items
      ref.read(feedPaginationProvider(feedType).notifier).state =
          FeedPaginationState(
        hasMore: response.hasMore,
        nextPage: response.nextPage,
        isLoadingMore: false,
      );
      state = AsyncData(response.items);
      _schedulePolling(response.items);
    }
  }

  String? get _currentUid {
    return ref.read(authServiceProvider).currentUser?.uid;
  }
}
