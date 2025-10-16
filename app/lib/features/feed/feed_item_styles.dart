import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/feed_display_preferences.dart';
import '../../data/dto/feed_item_dto.dart';

/// Widget that renders feed item based on selected display style
class StyledFeedItem extends StatelessWidget {
  const StyledFeedItem({
    super.key,
    required this.item,
    required this.style,
    required this.controller,
    required this.onTap,
  });

  final FeedItemDto item;
  final FeedDisplayStyle style;
  final VideoPlayerController? controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      FeedDisplayStyle.fullscreen =>
        const SizedBox.shrink(), // Should use FeedTile instead
      FeedDisplayStyle.card => _CardStyleItem(
          item: item,
          controller: controller,
          onTap: onTap,
        ),
      FeedDisplayStyle.compact => _CompactStyleItem(
          item: item,
          controller: controller,
          onTap: onTap,
        ),
      FeedDisplayStyle.masonry => _MasonryStyleItem(
          item: item,
          controller: controller,
          onTap: onTap,
        ),
      FeedDisplayStyle.minimal => _MinimalStyleItem(
          item: item,
          controller: controller,
          onTap: onTap,
        ),
    };
  }
}

/// Card Style - Large cards with media front and center
class _CardStyleItem extends StatelessWidget {
  const _CardStyleItem({
    required this.item,
    required this.controller,
    required this.onTap,
  });

  final FeedItemDto item;
  final VideoPlayerController? controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    if (post == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildMedia(post, controller),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title ?? (post.prompt.isEmpty ? 'Untitled' : post.prompt),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${post.type.name.toUpperCase()} • ${post.model}',
                    style: Theme.of(context).textTheme.bodySmall,
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

/// Compact Style - Smaller thumbnails with text alongside
class _CompactStyleItem extends StatelessWidget {
  const _CompactStyleItem({
    required this.item,
    required this.controller,
    required this.onTap,
  });

  final FeedItemDto item;
  final VideoPlayerController? controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    if (post == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 80,
                    child: _buildMedia(post, controller),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title ?? (post.prompt.isEmpty ? 'Untitled' : post.prompt),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            post.type == PostType.video
                                ? Icons.videocam
                                : Icons.image,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              post.type.name.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Masonry Style - Staggered grid with varying heights
class _MasonryStyleItem extends StatelessWidget {
  const _MasonryStyleItem({
    required this.item,
    required this.controller,
    required this.onTap,
  });

  final FeedItemDto item;
  final VideoPlayerController? controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    if (post == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: _buildMedia(post, controller),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                post.title ?? (post.prompt.isEmpty ? 'Untitled' : post.prompt),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal Style - Clean, minimal design with more whitespace
class _MinimalStyleItem extends StatelessWidget {
  const _MinimalStyleItem({
    required this.item,
    required this.controller,
    required this.onTap,
  });

  final FeedItemDto item;
  final VideoPlayerController? controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    if (post == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildMedia(post, controller),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title ?? (post.prompt.isEmpty ? 'Untitled' : post.prompt),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.type.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

/// Helper to build media (video or image)
Widget _buildMedia(PostDto post, VideoPlayerController? controller) {
  if (post.type == PostType.video) {
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  final imageUrl = post.publicUrl ?? post.storagePath;
  if (imageUrl.isEmpty) {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  return CachedNetworkImage(
    imageUrl: imageUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
      color: Colors.grey[800],
      child: const Center(child: CircularProgressIndicator()),
    ),
    errorWidget: (context, url, error) => Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    ),
  );
}

