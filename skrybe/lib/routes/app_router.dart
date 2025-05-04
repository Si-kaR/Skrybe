// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:skrybe/core/utils/transition_animations.dart';
import 'package:skrybe/data/providers/auth_provider.dart';
import 'package:skrybe/features/auth/screens/login_screen.dart';
import 'package:skrybe/features/auth/screens/signup_screen.dart';
import 'package:skrybe/features/dashboard/screens/dashboard_screen.dart';
import 'package:skrybe/features/onboarding/screens/onboarding_screen.dart';
import 'package:skrybe/features/onboarding/screens/splash_screen.dart';
import 'package:skrybe/features/onboarding/screens/welcome_screen.dart';
import 'package:skrybe/features/profile/screens/profile_screen.dart';
import 'package:skrybe/features/recording/screens/recording_screen.dart';
import 'package:skrybe/features/transcription/screens/transcription_detail_screen.dart';
import 'package:skrybe/features/upload/screens/upload_screen.dart';
import 'package:skrybe/routes/route_names.dart';
import 'package:skrybe/widgets/error_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error.toString(),
    ),
    redirect: (BuildContext context, GoRouterState state) {
      // Get whether the user has seen onboarding
      final hasSeenOnboarding = ref.read(onboardingCompletedProvider);

      // Handle authentication redirects
      final isAuthenticated = authState.valueOrNull ?? false;
      final isLoggingIn = state.uri.toString() == RouteNames.login;
      final isSigningUp = state.uri.toString() == RouteNames.signup;
      final isOnboarding = state.uri.toString() == RouteNames.onboarding;
      final isWelcome = state.uri.toString() == RouteNames.welcome;
      final isSplash = state.uri.toString() == RouteNames.splash;

      // Always allow splash screen
      if (isSplash) return null;

      // Handle onboarding flow
      if (!hasSeenOnboarding && !isOnboarding && !isSplash) {
        return RouteNames.onboarding;
      }

      // Handle authentication flow
      if (!isAuthenticated) {
        if (isLoggingIn || isSigningUp || isWelcome || isOnboarding) {
          return null;
        }
        return RouteNames.welcome;
      }

      // If the user is authenticated but on an auth screen, redirect to dashboard
      if (isAuthenticated && (isLoggingIn || isSigningUp || isWelcome)) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      // Splash and Onboarding Routes
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),
      GoRoute(
        path: RouteNames.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: slideTransition,
        ),
      ),

      // Authentication Routes
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: slideTransition,
        ),
      ),
      GoRoute(
        path: RouteNames.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionsBuilder: slideTransition,
        ),
      ),

      // Main App Routes
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          transitionsBuilder: slideTransition,
        ),
      ),
      GoRoute(
        path: RouteNames.record,
        name: 'record',
        builder: (context, state) => const RecordingScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RecordingScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: RouteNames.upload,
        name: 'upload',
        builder: (context, state) => const UploadScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const UploadScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: '${RouteNames.transcription}/:id',
        name: 'transcription_detail',
        builder: (context, state) {
          final transcriptionId = state.pathParameters['id']!;
          return TranscriptionDetailScreen(transcriptionId: transcriptionId);
        },
        pageBuilder: (context, state) {
          final transcriptionId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: TranscriptionDetailScreen(transcriptionId: transcriptionId),
            transitionsBuilder: slideTransition,
          );
        },
      ),
    ],
  );
});

final onboardingCompletedProvider = Provider<bool>((ref) {
  // In a real app, this would be loaded from local storage
  final settings = Hive.box('settings');
  return settings.get('onboardingCompleted', defaultValue: false);
});

// lib/routes/route_names.dart
class RouteNames {
  // Onboarding Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';

  // Auth Routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Main App Routes
  static const String dashboard = '/dashboard';

  static var profile;

  static var record;

  static var upload;

  static var transcription;
}
