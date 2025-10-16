import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/auth_service.dart';
import '../../core/env.dart';
import '../../core/feed_display_preferences.dart';
import '../../core/video_cache_manager.dart';
import '../../data/dto/feed_item_dto.dart';
import '../auth/view_gate.dart';
import 'feed_controller.dart';
import 'feed_item_styles.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final TabController _tabController;
  int _currentTabIndex = 0;

  final List<FeedType> _feedTypes = [
    FeedType.private, // Your Feed - all user's content (public + private)
    FeedType.hot,
    FeedType.interests,
    FeedType.random,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: _feedTypes.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    final feedType = _feedTypes[_currentTabIndex];
    return ref.read(feedControllerProvider(feedType).notifier).refresh();
  }

  void _loadMoreIfNeeded(FeedType feedType) {
    ref.read(feedControllerProvider(feedType).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        foregroundColor: theme.colorScheme.primary,
        title: const _RainbowLogo(),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(Icons.settings_outlined,
                size: 26, color: theme.colorScheme.primary),
          ),
          IconButton(
            onPressed: () => context.push('/compose'),
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 30, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          dividerColor: Colors.transparent, // Remove the gray divider line
          tabs: _feedTypes
              .map((type) => Tab(
                    icon: Icon(type.icon, size: 20),
                    text: type.displayName,
                  ))
              .toList(),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: TabBarView(
          controller: _tabController,
          children: _feedTypes.map((type) {
            return Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(feedControllerProvider(type));
                return state.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _FeedError(onRetry: _refresh),
                  data: (items) {
                    if (items.isEmpty) {
                      return _EmptyFeed(feedType: type);
                    }
                    final offlineMode =
                        items.every((item) => item.slot == FeedSlot.fallback);
                    final displayPrefs =
                        ref.watch(feedDisplayPreferencesProvider);
                    final style = displayPrefs.getStyle(type);

                    // Use PageView for fullscreen, ListView for card styles
                    final isFullscreen = style == FeedDisplayStyle.fullscreen;

                    return RefreshIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.black,
                      onRefresh: _refresh,
                      child: Stack(
                        children: [
                          if (isFullscreen)
                            NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollUpdateNotification) {
                                  final metrics = notification.metrics;
                                  final scrollPercentage =
                                      metrics.pixels / metrics.maxScrollExtent;
                                  if (scrollPercentage > 0.8) {
                                    _loadMoreIfNeeded(type);
                                  }
                                }
                                return false;
                              },
                              child: PageView.builder(
                                scrollDirection: Axis.vertical,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return FeedTile(
                                    item: item,
                                    onOpen: () => _handleOpen(context, item),
                                  );
                                },
                              ),
                            )
                          else
                            NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollUpdateNotification) {
                                  final metrics = notification.metrics;
                                  final scrollPercentage =
                                      metrics.pixels / metrics.maxScrollExtent;
                                  if (scrollPercentage > 0.8) {
                                    _loadMoreIfNeeded(type);
                                  }
                                }
                                return false;
                              },
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: items.length +
                                    1, // +1 for loading indicator
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 100),
                                itemBuilder: (context, index) {
                                  if (index == items.length) {
                                    // Loading indicator at bottom
                                    final pagination =
                                        ref.watch(feedPaginationProvider(type));
                                    if (pagination.isLoadingMore) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }

                                  final item = items[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: StyledFeedItem(
                                      item: item,
                                      style: style,
                                      controller: null,
                                      onTap: () => _handleOpen(context, item),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (offlineMode)
                            const Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: SafeArea(
                                bottom: false,
                                child: Center(
                                  child: _OfflineNotice(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleOpen(BuildContext context, FeedItemDto item) {
    final auth = ref.read(authServiceProvider);
    final isLocal = auth is LocalAuthService;
    if (!isLocal) {
      final gate = ref.read(viewGateProvider.notifier);
      final allowed = gate.recordView(deep: true);
      if (!allowed) {
        context.push('/signup');
        return;
      }
    }
    final post = item.post;
    if (post != null) {
      context.push('/post/${post.id}');
    }
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          const Text(
            'We lost the feed for a sec',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class FeedTile extends StatefulWidget {
  const FeedTile({super.key, required this.item, this.onOpen});

  final FeedItemDto item;
  final VoidCallback? onOpen;

  @override
  State<FeedTile> createState() => _FeedTileState();
}

class _FeedTileState extends State<FeedTile> {
  VideoPlayerController? _controller;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Don't initialize video in initState - wait for visibility
  }

  @override
  void didUpdateWidget(covariant FeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.post?.id != widget.item.post?.id) {
      _disposeVideo();
      // Re-initialize if still visible
      if (_isVisible) {
        _initVideo();
      }
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _onVisibilityChanged(double visibleFraction) {
    final wasVisible = _isVisible;
    _isVisible = visibleFraction > 0.5; // Consider visible if >50% on screen

    if (_isVisible && !wasVisible) {
      // Became visible - initialize video
      _initVideo();
    } else if (!_isVisible && wasVisible) {
      // Became invisible - dispose video to save memory
      _disposeVideo();
    }
  }

  Future<void> _initVideo() async {
    final post = widget.item.post;
    if (_controller != null) return; // Already initialized

    if (widget.item.slot == FeedSlot.ready &&
        post?.type == PostType.video &&
        (post?.publicUrl ?? post?.storagePath ?? '').isNotEmpty) {
      final videoUrl = post!.publicUrl ?? post.storagePath;

      try {
        // Try to get cached video file first
        final fileInfo =
            await VideoCacheManager.instance.getFileFromCache(videoUrl);

        VideoPlayerController controller;
        if (fileInfo != null) {
          // Use cached file
          controller = VideoPlayerController.file(fileInfo.file);
        } else {
          // Download and cache the video
          final file = await VideoCacheManager.instance.getSingleFile(videoUrl);
          controller = VideoPlayerController.file(file);
        }

        _controller = controller;
        await controller.setLooping(true);
        await controller.initialize();

        if (!mounted) return;
        await controller.play();
        setState(() {});
      } catch (e) {
        // Fallback to network streaming if caching fails
        if (!mounted) return;
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        _controller = controller;
        controller
          ..setLooping(true)
          ..initialize().then((_) {
            if (!mounted) return;
            controller.play();
            setState(() {});
          });
      }
    }
  }

  void _disposeVideo() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final post = item.post;
    return VisibilityDetector(
      key: Key('feed-tile-${item.post?.id ?? 'unknown'}'),
      onVisibilityChanged: (info) {
        _onVisibilityChanged(info.visibleFraction);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: GestureDetector(
            onTap: () {
              // Pause video before navigating
              _controller?.pause();
              widget.onOpen?.call();
            },
            child: Container(
              color: Colors.black,
              child: switch (item.slot) {
                FeedSlot.ready => post == null
                    ? const _PendingCard(label: 'Loading your vibe…')
                    : _ReadyContent(post: post, controller: _controller),
                FeedSlot.pending =>
                  const _PendingCard(label: 'Cooking up magic…'),
                FeedSlot.fallback => _FallbackContent(post: post),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyContent extends ConsumerWidget {
  const _ReadyContent({required this.post, this.controller});

  final PostDto post;
  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = _EngagementStats.fromPost(post);
    final duration = post.duration;
    final auth = ref.watch(authServiceProvider);
    final isSignedIn =
        auth.currentUser != null && !auth.currentUser!.isAnonymous;
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        _MediaBackground(post: post, controller: controller),
        const _MediaOverlayGradient(),
        Positioned(
          top: 20,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TagBadge(
                label: post.type == PostType.video ? 'VIDEO' : 'IMAGE',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              if (duration != null && post.type == PostType.video)
                _TagBadge(
                  label: '${duration.toStringAsFixed(1)}s',
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 28,
          left: 20,
          right: 84,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title ??
                    (post.prompt.isEmpty ? 'Fresh inspiration' : post.prompt),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                'model · ${post.model.toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SocialAction(
                icon: Icons.favorite,
                value: stats.likes,
                onTap: () {
                  if (!isSignedIn) {
                    context.push('/signup');
                  } else {
                    // TODO: Implement like
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Like feature coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              _SocialAction(
                icon: Icons.mode_comment_rounded,
                value: stats.comments,
                onTap: () {
                  if (!isSignedIn) {
                    context.push('/signup');
                  } else {
                    // TODO: Implement comments
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comments coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              _SocialAction(
                icon: Icons.share_rounded,
                value: stats.shares,
                onTap: () async {
                  if (!isSignedIn) {
                    context.push('/signup');
                  } else {
                    // Share the post
                    final shareText = post.title ?? post.prompt;
                    await Share.share(
                      'Check out this amazing ${post.type == PostType.video ? 'video' : 'image'} on MyWay! "$shareText"',
                      subject: 'Shared from MyWay',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FallbackContent extends ConsumerWidget {
  const _FallbackContent({this.post});

  final PostDto? post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (post == null) {
      return const _PendingCard(label: 'Stay tuned for more');
    }

    final fallbackPost = post!;
    final isVideo = fallbackPost.type == PostType.video;
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isVideo)
          _FallbackVideoPreview(url: fallbackPost.storagePath)
        else if ((fallbackPost.publicUrl ?? fallbackPost.storagePath)
            .isNotEmpty)
          CachedNetworkImage(
            imageUrl: fallbackPost.publicUrl ?? fallbackPost.storagePath,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.white54),
              ),
            ),
          )
        else
          Container(color: Colors.grey.shade900),
        const _MediaOverlayGradient(),
        Positioned(
          top: 20,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TagBadge(
                label: isVideo ? 'VIDEO PREVIEW' : 'CURATED',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _TagBadge(
                label: 'DISCOVER',
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 84,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fallbackPost.title ??
                    (fallbackPost.prompt.isEmpty
                        ? 'Ready-made inspiration while your feed warms up'
                        : fallbackPost.prompt),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'From ${fallbackPost.model.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.4,
                    ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SocialAction(
                icon: Icons.favorite_border_rounded,
                value: '—',
                onTap: () => context.push('/signup'),
              ),
              const SizedBox(height: 14),
              _SocialAction(
                icon: Icons.bookmark_add_outlined,
                value: '—',
                onTap: () => context.push('/signup'),
              ),
              const SizedBox(height: 14),
              _SocialAction(
                icon: Icons.flight_takeoff_rounded,
                value: 'Share',
                onTap: () => context.push('/signup'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaBackground extends StatelessWidget {
  const _MediaBackground({required this.post, this.controller});

  final PostDto post;
  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    if (post.type == PostType.video) {
      final videoController = controller;
      if (videoController != null && videoController.value.isInitialized) {
        final size = videoController.value.size;
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(videoController),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final imageUrl = post.publicUrl ?? post.storagePath;
    if (imageUrl.isEmpty) {
      return Container(color: Colors.black);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white70),
        ),
      ),
    );
  }
}

class _MediaOverlayGradient extends StatelessWidget {
  const _MediaOverlayGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Color(0xFF000000),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SocialAction extends ConsumerWidget {
  const _SocialAction({
    required this.icon,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Icon(icon, color: theme.colorScheme.primary, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementStats {
  const _EngagementStats(
      {required this.likes, required this.comments, required this.shares});

  final String likes;
  final String comments;
  final String shares;

  factory _EngagementStats.fromPost(PostDto post) {
    final seed = post.seed ?? post.id.hashCode;
    final random = math.Random(seed);
    final likes = 800 + random.nextInt(6400);
    final comments = 20 + random.nextInt(260);
    final shares = 5 + random.nextInt(180);
    return _EngagementStats(
      likes: _format(likes),
      comments: _format(comments),
      shares: _format(shares),
    );
  }

  static String _format(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade900,
          highlightColor: Colors.grey.shade700,
          child: Container(color: Colors.grey.shade900),
        ),
        Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FallbackVideoPreview extends StatelessWidget {
  const _FallbackVideoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(url)?.host ?? 'preview';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF111827),
            Color(0xFF020617),
          ],
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.play_circle_fill_rounded,
              size: 96, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Tap to preview video',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            host,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyFeed extends ConsumerWidget {
  const _EmptyFeed({required this.feedType});

  final FeedType feedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, title, subtitle) = switch (feedType) {
      FeedType.hot => (
          Icons.local_fire_department,
          'Hot feed is empty',
          'Create content to see what\'s trending!'
        ),
      FeedType.interests => (
          Icons.explore,
          'No interests content yet',
          'Set your interests in settings to see personalized content.'
        ),
      FeedType.private => (
          Icons.person,
          'Your feed is empty',
          'All content you create will appear here - both public and private!'
        ),
      FeedType.random => (
          Icons.shuffle,
          'No content to discover',
          'Create some content to explore random posts!'
        ),
    };

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () =>
          ref.read(feedControllerProvider(feedType).notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white54, size: 56),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/compose'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final hosts = Env.apiBaseCandidates;
    final hostSummary =
        hosts.map((url) => Uri.tryParse(url)?.host ?? url).join(', ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering_off_rounded, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offline demo — feed is showing fallback content.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No response from: $hostSummary',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'On a USB device run: adb reverse tcp:8000 tcp:8000. '
                    'Otherwise set API_BASE_URL to your machine IP (e.g. http://192.168.x.x:8000) and pull to refresh.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInPromptSheet extends StatelessWidget {
  const _SignInPromptSheet({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Join MyWay',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Sign in or create an account to $action and unlock the full experience',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/signup');
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/signup');
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RainbowLogo extends StatefulWidget {
  const _RainbowLogo();

  @override
  State<_RainbowLogo> createState() => _RainbowLogoState();
}

class _RainbowLogoState extends State<_RainbowLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final double offset = _animation.value;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF6BCF7F), // Green
                Color(0xFF4D96FF), // Blue
                Color(0xFF8B7FE8), // Purple
                Color(0xFFE84D8A), // Pink
                Color(0xFF4D96FF), // Blue
                Color(0xFF6BCF7F), // Green
              ],
              stops: [
                (0.0 + offset).clamp(0.0, 1.0),
                (0.2 + offset).clamp(0.0, 1.0),
                (0.4 + offset).clamp(0.0, 1.0),
                (0.6 + offset).clamp(0.0, 1.0),
                (0.8 + offset).clamp(0.0, 1.0),
                (1.0 + offset).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            'MyWay',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
          ),
        );
      },
    );
  }
}
