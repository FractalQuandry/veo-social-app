import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: October 2, 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            _Section(
              title: '1. Introduction',
              content:
                  'MyWay ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share information about you when you use our mobile application.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '2. Information We Collect',
              content:
                  'We collect information you provide directly to us, such as when you create an account, post content, or communicate with us. This may include your email address, profile information, and content you create or share.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '3. How We Use Your Information',
              content:
                  'We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to personalize your experience on MyWay.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '4. AI-Generated Content',
              content:
                  'MyWay uses AI to generate personalized content based on your interests. We process your interaction data to improve content recommendations while respecting your privacy.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '5. Data Security',
              content:
                  'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or destruction.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '6. Your Rights',
              content:
                  'You have the right to access, correct, or delete your personal information. You can do this through your account settings or by contacting us directly.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '7. Contact Us',
              content:
                  'If you have questions about this Privacy Policy, please contact us at privacy@myway.com.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
