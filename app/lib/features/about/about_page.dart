import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchWebsite(BuildContext context) async {
    final uri = Uri.parse('https://myway.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open website')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About MyWay'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MyWay',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimaryContainer,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Stories. Your Way.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content sections
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission
                  _SectionTitle(
                    icon: Icons.flag_rounded,
                    title: 'Our Mission',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We believe in authentic content discovery. MyWay is an AI-native platform that puts you in control of your content experience—not advertisers, not corporations, but you.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // The Problem
                  _SectionTitle(
                    icon: Icons.warning_rounded,
                    title: 'The Problem We\'re Solving',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Traditional social media platforms use algorithms designed to maximize engagement and ad revenue—not your happiness or genuine interests. They track your every move, exploit your psychology, and feed you content that keeps you scrolling, not living.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Our Solution
                  _SectionTitle(
                    icon: Icons.lightbulb_rounded,
                    title: 'Our Solution',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MyWay uses ethical AI to generate personalized content based on your true interests. No hidden algorithms, no dark patterns, no manipulation. Just pure, authentic content discovery powered by cutting-edge AI that adapts to what you genuinely care about.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Values
                  _SectionTitle(
                    icon: Icons.favorite_rounded,
                    title: 'What We Stand For',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _ValueItem(
                    icon: Icons.verified_user,
                    title: 'User-First',
                    description: 'Every decision prioritizes your experience',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _ValueItem(
                    icon: Icons.psychology,
                    title: 'Ethical AI',
                    description: 'Transparent technology that serves you',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _ValueItem(
                    icon: Icons.lock_open,
                    title: 'No Manipulation',
                    description: 'Zero dark patterns or addictive design',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _ValueItem(
                    icon: Icons.people,
                    title: 'Authentic Community',
                    description: 'Real connections over engagement metrics',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 40),

                  // CTA to website
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.5),
                          colorScheme.secondaryContainer.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.language,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Want to Learn More?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Visit our website to explore our vision, meet the team, and join the revolution.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _launchWebsite(context),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Visit MyWay.com'),
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
                  const SizedBox(height: 24),

                  // Footer info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Version 1.0.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2025 MyWay. All rights reserved.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final ColorScheme colorScheme;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _ValueItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _ValueItem({
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
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
