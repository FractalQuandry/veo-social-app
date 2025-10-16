import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/auth_service.dart';
import '../../data/dto/feed_item_dto.dart';
import '../../data/repository/feed_repository.dart';
import '../feed/feed_controller.dart';

class PostPage extends ConsumerStatefulWidget {
  const PostPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String url) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  String _formatPrompt(String prompt) {
    // Take first sentence or first 60 characters, whichever is shorter
    final firstSentence = prompt.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length <= 60) {
      return firstSentence;
    }
    return '${prompt.substring(0, 57)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedState = ref.watch(feedControllerProvider(FeedType.hot));
    final feedItem = feedState.maybeWhen(
      data: (items) =>
          items.firstWhere((item) => item.post?.id == widget.id, orElse: () {
        return items.first; // Fallback
      }),
      orElse: () => null,
    );
    final post = feedItem?.post;

    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Post not found. Please refresh the feed.'),
        ),
      );
    }

    // Initialize video if needed
    if (_videoController == null &&
        (post.publicUrl ?? post.storagePath).isNotEmpty &&
        post.type == PostType.video) {
      final videoUrl = post.publicUrl ?? post.storagePath;
      _initializeVideo(videoUrl);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Content
            AspectRatio(
              aspectRatio: 9 / 16,
              child: _buildMediaContent(post),
            ),

            // Post Details
            Container(
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrompt(post.prompt),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Anonymous User',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Recently',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Interaction Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          context,
                          ref,
                          icon: Icons.favorite_border,
                          label: 'Like',
                          onTap: () => _handleLike(context, ref),
                        ),
                        _buildActionButton(
                          context,
                          ref,
                          icon: Icons.comment_outlined,
                          label: 'Comment',
                          onTap: () => _handleComment(context, ref),
                        ),
                        _buildActionButton(
                          context,
                          ref,
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () => _handleShare(context, ref),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Full Prompt
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prompt',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.prompt,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Model Info & Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Generated with ${post.model}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _requestVariations(context, ref),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Create Similar Content'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(PostDto post) {
    if (post.type == PostType.video &&
        (post.publicUrl ?? post.storagePath).isNotEmpty) {
      if (_videoController != null && _isVideoInitialized) {
        return GestureDetector(
          onTap: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                if (!_videoController!.value.isPlaying)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                // Fullscreen button for landscape videos
                if (_videoController!.value.aspectRatio > 1.0)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        _showFullscreenVideo();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else if (post.type == PostType.image &&
        (post.publicUrl ?? post.storagePath).isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: post.publicUrl ?? post.storagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error),
        ),
      );
    } else {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.white54,
        ),
      );
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLike(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);
    final isSignedIn =
        auth.currentUser != null && !auth.currentUser!.isAnonymous;

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
  }

  void _handleComment(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);
    final isSignedIn =
        auth.currentUser != null && !auth.currentUser!.isAnonymous;

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
  }

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authServiceProvider);
    final isSignedIn =
        auth.currentUser != null && !auth.currentUser!.isAnonymous;

    if (!isSignedIn) {
      context.push('/signup');
    } else {
      final feedState = ref.read(feedControllerProvider(FeedType.hot));
      final post = feedState.maybeWhen(
        data: (items) =>
            items.firstWhere((item) => item.post?.id == widget.id, orElse: () {
          return items.first;
        }).post,
        orElse: () => null,
      );

      if (post != null) {
        await Share.share(
          'Check out this amazing ${post.type == PostType.video ? 'video' : 'image'} on MyWay! "${post.prompt}"',
          subject: 'Shared from MyWay',
        );
      }
    }
  }

  Future<void> _requestVariations(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to request variations.'),
          ),
        );
      }
      return;
    }
    try {
      final jobs = await ref
          .read(feedRepositoryProvider)
          .moreLikeThis(user.uid, widget.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Queued ${jobs.length} similar creations!'),
            action: SnackBarAction(
              label: 'View Feed',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showFullscreenVideo() {
    if (_videoController == null) return;

    final wasPlaying = _videoController!.value.isPlaying;
    _videoController!.pause();

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            // Play/pause overlay
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Resume playing if it was playing before
      if (wasPlaying) {
        _videoController!.play();
      }
    });

    // Start playing in fullscreen
    _videoController!.play();
  }
}

class _SignInPromptSheet extends StatelessWidget {
  const _SignInPromptSheet({required this.action});

  final String action;

  IconData _getIconForAction() {
    switch (action.toLowerCase()) {
      case 'like':
      case 'like this':
        return Icons.favorite;
      case 'comment':
      case 'comment on this':
        return Icons.comment;
      case 'share':
      case 'share this':
        return Icons.share;
      case 'create':
      case 'generate':
        return Icons.auto_awesome;
      default:
        return Icons.lock_open;
    }
  }

  String _getActionTitle() {
    switch (action.toLowerCase()) {
      case 'like':
      case 'like this':
        return 'Love what you see?';
      case 'comment':
      case 'comment on this':
        return 'Join the conversation';
      case 'share':
      case 'share this':
        return 'Share the inspiration';
      case 'create':
      case 'generate':
        return 'Ready to create?';
      default:
        return 'Join MyWay';
    }
  }

  String _getActionDescription() {
    switch (action.toLowerCase()) {
      case 'like':
      case 'like this':
        return 'Sign up to save your favorite posts and let creators know you appreciate their work';
      case 'comment':
      case 'comment on this':
        return 'Create an account to share your thoughts and connect with the MyWay community';
      case 'share':
      case 'share this':
        return 'Join MyWay to share amazing content with your friends and followers';
      case 'create':
      case 'generate':
        return 'Create your account to start generating stunning AI content with the power of your imagination';
      default:
        return 'Sign up to unlock the full MyWay experience and join our creative community';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Animated icon with gradient background
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForAction(),
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 24),

                // Dynamic title based on action
                Text(
                  _getActionTitle(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Dynamic description based on action
                Text(
                  _getActionDescription(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Quick benefits
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BenefitChip(
                      icon: Icons.auto_awesome,
                      label: 'Create',
                      colorScheme: colorScheme,
                    ),
                    _BenefitChip(
                      icon: Icons.favorite,
                      label: 'Like',
                      colorScheme: colorScheme,
                    ),
                    _BenefitChip(
                      icon: Icons.comment,
                      label: 'Comment',
                      colorScheme: colorScheme,
                    ),
                    _BenefitChip(
                      icon: Icons.share,
                      label: 'Share',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Primary CTA - Create Account
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/signup');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded),
                        SizedBox(width: 8),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary CTA - Sign In
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/signup');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _BenefitChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
