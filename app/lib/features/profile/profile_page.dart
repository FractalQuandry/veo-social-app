import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_service.dart';
import '../../data/profile_service.dart';
import 'profile_image_capture_page.dart';

// State provider for profile images
final profileImagesProvider =
    FutureProvider.family<ProfileImages?, String>((ref, uid) async {
  final profileService = ref.watch(profileServiceProvider);
  try {
    final response = await profileService.getProfileImages(uid: uid);
    return response.profileImages;
  } catch (e) {
    return null;
  }
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = ref.watch(authServiceProvider);
    final user = auth.currentUser;

    // Load profile images
    final profileImagesAsync = user != null
        ? ref.watch(profileImagesProvider(user.uid))
        : const AsyncValue<ProfileImages?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Image
              profileImagesAsync.when(
                data: (profileImages) => _ProfileAvatar(
                  profileImages: profileImages,
                  colorScheme: colorScheme,
                ),
                loading: () => CircleAvatar(
                  radius: 60,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: const CircularProgressIndicator(),
                ),
                error: (_, __) => CircleAvatar(
                  radius: 60,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user?.isAnonymous == true ? 'Guest User' : 'MyWay User',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.uid ?? 'No user ID',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.cloud_upload_outlined,
                        label: 'Posts',
                        value: '0',
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.favorite_border,
                        label: 'Likes',
                        value: '0',
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.comment_outlined,
                        label: 'Comments',
                        value: '0',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Image Setup Button
              if (user != null && !user.isAnonymous)
                profileImagesAsync.when(
                  data: (profileImages) {
                    final hasBaseImage =
                        profileImages?.baseImageApproved == true;
                    return OutlinedButton.icon(
                      onPressed: () async {
                        // Navigate to capture page using GoRouter context
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileImageCapturePage(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          // Refresh profile images
                          ref.invalidate(profileImagesProvider(user.uid));
                        }
                      },
                      icon: Icon(hasBaseImage ? Icons.edit : Icons.add_a_photo),
                      label: Text(hasBaseImage
                          ? 'Update Profile Image'
                          : 'Create Profile Image'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

              const SizedBox(height: 12),

              if (user?.isAnonymous == true)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/signup');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Account'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final ProfileImages? profileImages;
  final ColorScheme colorScheme;

  const _ProfileAvatar({
    required this.profileImages,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (profileImages?.baseImageApproved == true &&
        profileImages?.baseImagePublicUrl != null) {
      // Show the approved base image
      return CircleAvatar(
        radius: 60,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: profileImages!.baseImagePublicUrl!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(
              Icons.person,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    } else {
      // Default placeholder avatar
      return CircleAvatar(
        radius: 60,
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          Icons.person,
          size: 60,
          color: colorScheme.primary,
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
