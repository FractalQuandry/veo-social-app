import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth_service.dart';
import 'core/logger.dart';
import 'features/about/about_page.dart';
import 'features/auth/email_signin_page.dart';
import 'features/auth/email_signup_page.dart';
import 'features/auth/signup_page.dart';
import 'features/composer/composer_page.dart';
import 'features/feed/feed_page.dart';
import 'features/legal/privacy_policy_page.dart';
import 'features/legal/terms_of_service_page.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/post/post_page.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/profile_image_capture_page.dart';
import 'features/settings/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final user = auth.currentUser;
  final onboardingComplete = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, st) {
      // Check onboarding status for all routes except onboarding itself
      if (st.matchedLocation != '/onboarding') {
        final complete = onboardingComplete.value ?? false;
        if (!complete) {
          return '/onboarding';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (ctx, st) => const OnboardingFlow(),
      ),
      GoRoute(
        path: '/',
        builder: (ctx, st) => const FeedPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (ctx, st) => const SignupPage(),
      ),
      GoRoute(
        path: '/signup/email',
        builder: (ctx, st) => const EmailSignupPage(),
      ),
      GoRoute(
        path: '/signin/email',
        builder: (ctx, st) => const EmailSignInPage(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (ctx, st) => PostPage(id: st.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (ctx, st) => const SettingsPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (ctx, st) => const AboutPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (ctx, st) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/capture',
        builder: (ctx, st) => const ProfileImageCapturePage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (ctx, st) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (ctx, st) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: '/compose',
        builder: (ctx, st) => const ComposerPage(),
        redirect: (ctx, st) {
          if (user == null) {
            AppLogger.warn('No user, preventing composer access');
            return '/signup';
          }
          if (user.isAnonymous) {
            return '/signup';
          }
          return null;
        },
      ),
    ],
  );
});
