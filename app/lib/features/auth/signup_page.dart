import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_service.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _phoneDelayAnimation;
  late Animation<double> _contentDelayAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Page slides in first
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Phone illustration comes in with delay
    _phoneDelayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Content fades in last
    _contentDelayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hero illustration with staggered animation
                    _AnimatedPhoneIllustration(
                      phoneAnimation: _phoneDelayAnimation,
                      contentAnimation: _contentDelayAnimation,
                    ),
                    const SizedBox(height: 40),

                    // Welcome message
                    Text(
                      'Your Stories.',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Your Way.',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Discover authentic, AI-generated content that adapts to your true interests—not what brands want you to see.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Features list
                    _FeatureItem(
                      icon: Icons.auto_awesome,
                      title: 'Your Content, Not Their Ads',
                      description:
                          'AI-generated content based on your genuine interests',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _FeatureItem(
                      icon: Icons.favorite,
                      title: 'Your Feed, Your Rules',
                      description:
                          'No algorithmic manipulation—just pure discovery',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _FeatureItem(
                      icon: Icons.comment,
                      title: 'Authentic Connections',
                      description:
                          'Join a community that values real engagement',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _FeatureItem(
                      icon: Icons.share,
                      title: 'Break Free',
                      description:
                          'Take back control from corporate algorithms',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 48),

                    // Primary CTA - Sign up
                    FilledButton(
                      onPressed: () {
                        context.push('/signup/email');
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch),
                          SizedBox(width: 8),
                          Text(
                            'Join the Revolution',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary CTA - Sign in
                    OutlinedButton(
                      onPressed: () {
                        context.push('/signin/email');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: colorScheme.primary),
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
                    const SizedBox(height: 24),

                    // Skip option
                    TextButton(
                      onPressed: () async {
                        final auth = ref.read(authServiceProvider);
                        await auth.signOut();
                        await auth.signInAnonymously();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'Maybe later',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Terms hint
                    Text(
                      'By creating an account, you agree to our Terms of Service and Privacy Policy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedPhoneIllustration extends StatefulWidget {
  final Animation<double> phoneAnimation;
  final Animation<double> contentAnimation;

  const _AnimatedPhoneIllustration({
    required this.phoneAnimation,
    required this.contentAnimation,
  });

  @override
  State<_AnimatedPhoneIllustration> createState() =>
      _AnimatedPhoneIllustrationState();
}

class _AnimatedPhoneIllustrationState extends State<_AnimatedPhoneIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, widget.phoneAnimation]),
      builder: (context, child) {
        // Clamp opacity to valid range (0.0-1.0) since ElasticOutCurve can overshoot
        final phoneOpacity = widget.phoneAnimation.value.clamp(0.0, 1.0);
        final phoneScale =
            0.5 + (widget.phoneAnimation.value.clamp(0.0, 1.0) * 0.5);

        return Opacity(
          opacity: phoneOpacity,
          child: Transform.scale(
            scale: phoneScale,
            child: Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Container(
                height: 240,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.2),
                      colorScheme.secondaryContainer.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: _PhoneFrame(
                  contentAnimation: widget.contentAnimation,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  final Animation<double> contentAnimation;

  const _PhoneFrame({required this.contentAnimation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: contentAnimation,
      builder: (context, child) {
        // Clamp opacity to valid range (0.0-1.0)
        final contentOpacity = contentAnimation.value.clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Column(
              children: [
                // Status bar
                Container(
                  height: 8,
                  color: colorScheme.surfaceContainerHighest,
                ),
                // Content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Opacity(
                      opacity: contentOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Text lines
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 6,
                            width: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Image placeholder
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primaryContainer,
                                    colorScheme.secondaryContainer,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _MiniActionButton(
                                icon: Icons.favorite_border,
                                colorScheme: colorScheme,
                              ),
                              _MiniActionButton(
                                icon: Icons.comment_outlined,
                                colorScheme: colorScheme,
                              ),
                              _MiniActionButton(
                                icon: Icons.share_outlined,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final ColorScheme colorScheme;

  const _MiniActionButton({
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 16,
        color: colorScheme.primary,
      ),
    );
  }
}
