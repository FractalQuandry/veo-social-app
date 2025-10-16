import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth_service.dart';
import '../../core/feed_display_preferences.dart';
import '../../core/theme_controller.dart';
import '../../core/usage_limits_service.dart';
import '../../data/dto/feed_item_dto.dart';
import '../feed/feed_controller.dart';
import 'interests_editor.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themePrefs = ref.watch(themeControllerProvider);
    final auth = ref.watch(authServiceProvider);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSection(
            context,
            title: 'Account',
            children: [
              if (user != null && !user.isAnonymous)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text('User ${user.uid.substring(0, 8)}...'),
                  subtitle: const Text('View profile'),
                  onTap: () => context.push('/profile'),
                ),
              if (user == null || user.isAnonymous)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Sign In'),
                  subtitle: const Text(
                      'Create an account to personalize your experience'),
                  onTap: () => context.push('/signup'),
                ),
              if (user != null && !user.isAnonymous)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () async {
                    // Clear usage limits on sign out
                    final usageLimits = ref.read(usageLimitsServiceProvider);
                    await usageLimits.resetUsage();

                    // Clear feed cache for all feed types by invalidating providers
                    for (final feedType in FeedType.values) {
                      ref.invalidate(feedControllerProvider(feedType));
                      ref.invalidate(feedPaginationProvider(feedType));
                    }

                    // Sign out
                    await auth.signOut();

                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                ),
            ],
          ),

          // Appearance Section
          _buildSection(
            context,
            title: 'Appearance',
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme Mode'),
                subtitle: Text(_themeModeLabel(themePrefs.themeMode)),
                onTap: () => _showThemeModeDialog(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Color Scheme'),
                subtitle: Text(themePrefs.colorScheme.label),
                onTap: () => _showColorSchemeDialog(context, ref),
              ),
            ],
          ),

          // Feed Preferences
          _buildSection(
            context,
            title: 'Feed Preferences',
            children: [
              ListTile(
                leading: const Icon(Icons.interests),
                title: const Text('Interests'),
                subtitle: const Text('Manage your content preferences'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InterestsEditor(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_module),
                title: const Text('Feed Display Styles'),
                subtitle: const Text('Customize feed layout per tab'),
                onTap: () => _showDisplayStyleDialog(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Content Filters'),
                subtitle: const Text('Customize what you see'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Content filters are coming in the next update!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          // About Section
          _buildSection(
            context,
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('About MyWay'),
                subtitle: const Text('Our mission and story'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/about');
                },
              ),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset Usage Limits'),
                subtitle:
                    const Text('Clear daily generation quotas (for testing)'),
                onTap: () async {
                  final usageLimits = ref.read(usageLimitsServiceProvider);
                  await usageLimits.resetUsage();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usage limits reset successfully! 🎉'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                onTap: () => context.push('/privacy'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                onTap: () => context.push('/terms'),
              ),
            ],
          ),

          // Debug Section (for development)
          _buildSection(
            context,
            title: 'Debug',
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset Onboarding'),
                subtitle: const Text('See the welcome flow again'),
                onTap: () => _resetOnboarding(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    final themeController = ref.read(themeControllerProvider.notifier);
    final currentMode = ref.read(themeControllerProvider).themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_themeModeLabel(mode)),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  themeController.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showColorSchemeDialog(BuildContext context, WidgetRef ref) {
    final themeController = ref.read(themeControllerProvider.notifier);
    final currentScheme = ref.read(themeControllerProvider).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color Scheme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppColorScheme.values.map((scheme) {
            return RadioListTile<AppColorScheme>(
              title: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: scheme.seed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(scheme.label),
                ],
              ),
              value: scheme,
              groupValue: currentScheme,
              onChanged: (value) {
                if (value != null) {
                  themeController.setColorScheme(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDisplayStyleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feed Display Styles'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a display style for each feed type:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...FeedType.values.map((feedType) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(feedType.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            feedType.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final currentStyle = ref
                              .watch(feedDisplayPreferencesProvider)
                              .getStyle(feedType);
                          return DropdownButtonFormField<FeedDisplayStyle>(
                            value: currentStyle,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: FeedDisplayStyle.values.map((style) {
                              return DropdownMenuItem(
                                value: style,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        style.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        style.description,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (style) {
                              if (style != null) {
                                ref
                                    .read(feedDisplayPreferencesProvider)
                                    .setStyle(feedType, style);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding?'),
        content: const Text(
          'This will clear your onboarding completion status and selected interests. '
          'The app will restart and show the welcome flow again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_complete');
      await prefs.remove('selected_interests');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onboarding reset! Restarting app...'),
            duration: Duration(seconds: 2),
          ),
        );
        // Navigate to root and then to onboarding
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            context.go('/onboarding');
          }
        });
      }
    }
  }
}
