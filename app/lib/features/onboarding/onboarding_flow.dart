import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _currentPage = 0;
  final Set<String> _selectedInterests = {};

  final List<String> _interests = [
    '🎨 Art & Design',
    '🎵 Music',
    '🎮 Gaming',
    '🍳 Food & Cooking',
    '✈️ Travel',
    '💪 Fitness',
    '📚 Books',
    '🎬 Movies & TV',
    '🐾 Pets & Animals',
    '💻 Technology',
    '🌱 Nature',
    '🧘 Wellness',
    '⚽ Sports',
    '🎭 Comedy',
    '📸 Photography',
    '🏠 Home & DIY',
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    final interestsList = _selectedInterests.toList();
    await prefs.setStringList('selected_interests', interestsList);
    debugPrint(
        'Onboarding complete: ${interestsList.length} interests saved - $interestsList');
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _currentPage == 0
              ? _buildWelcomePage(theme)
              : _buildInterestsPage(theme),
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Icon(
          Icons.auto_awesome,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to MyWay',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'An AI-powered social experience\ntailored just for you',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => setState(() => _currentPage = 1),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          child: const Text('Get Started'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _completeOnboarding,
          child: const Text('Skip for now'),
        ),
      ],
    );
  }

  Widget _buildInterestsPage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => setState(() => _currentPage = 0),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(height: 16),
        Text(
          'What interests you?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose topics to personalize your feed',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _interests.length,
            itemBuilder: (context, index) {
              final interest = _interests[index];
              final isSelected = _selectedInterests.contains(interest);

              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                showCheckmark: true,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _selectedInterests.isEmpty ? null : _completeOnboarding,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          child: Text(_selectedInterests.isEmpty
              ? 'Select at least one interest'
              : 'Continue (${_selectedInterests.length} selected)'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _completeOnboarding,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}
