import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              title: '1. Acceptance of Terms',
              content:
                  'By accessing or using MyWay, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '2. User Accounts',
              content:
                  'You are responsible for maintaining the security of your account and for all activities that occur under your account. You must notify us immediately of any unauthorized use.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '3. Content',
              content:
                  'You retain ownership of content you create on MyWay. By posting content, you grant us a license to use, modify, and distribute your content in connection with operating the service.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '4. AI-Generated Content',
              content:
                  'MyWay generates content using artificial intelligence. While we strive for accuracy and quality, AI-generated content may occasionally contain errors or inappropriate material. We are not responsible for AI-generated content accuracy.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '5. Prohibited Conduct',
              content:
                  'You agree not to use MyWay for any unlawful purpose, to harass others, to distribute spam, or to interfere with the proper functioning of the service.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '6. Intellectual Property',
              content:
                  'The MyWay service, including its design, features, and functionality, is owned by MyWay and is protected by copyright, trademark, and other intellectual property laws.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '7. Termination',
              content:
                  'We reserve the right to suspend or terminate your account at any time, with or without notice, for violating these Terms of Service.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '8. Disclaimer',
              content:
                  'MyWay is provided "as is" without warranties of any kind. We do not guarantee that the service will be uninterrupted, secure, or error-free.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '9. Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, MyWay shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the service.',
            ),
            const SizedBox(height: 24),
            _Section(
              title: '10. Contact',
              content:
                  'For questions about these Terms of Service, please contact us at legal@myway.com.',
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
