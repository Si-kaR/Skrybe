// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skrybe/core/utils/transition_animations.dart';
import 'package:skrybe/data/models/transcript_model.dart';
import 'package:skrybe/data/providers/auth_provider.dart';
import 'package:skrybe/features/auth/screens/forgot_password_screen.dart';
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

// Fixed: Moved welcomeCompletedProvider outside of onboardingCompletedProvider
final welcomeCompletedProvider = FutureProvider<bool>((ref) async {
  try {
    if (Hive.isBoxOpen('settings')) {
      final settingsBox = Hive.box('settings');
      return settingsBox.get('welcomeCompleted', defaultValue: false);
    } else {
      final settingsBox = await Hive.openBox('settings');
      return settingsBox.get('welcomeCompleted', defaultValue: false);
    }
  } catch (e) {
    debugPrint('❌ Error getting welcomeCompleted: $e');
    return false;
  }
});

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  // Try to check onboarding status from Hive first
  try {
    if (Hive.isBoxOpen('settings')) {
      final settingsBox = Hive.box('settings');
      final value = settingsBox.get('onboardingCompleted', defaultValue: false);
      debugPrint('📋 Hive onboardingCompleted: $value');
      return value;
    } else {
      // Try to open the box
      try {
        final settingsBox = await Hive.openBox('settings');
        final value =
            settingsBox.get('onboardingCompleted', defaultValue: false);
        debugPrint('📋 Hive onboardingCompleted (after opening): $value');
        return value;
      } catch (e) {
        debugPrint('❌ Could not open Hive box: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Error checking onboarding status from Hive: $e');
  }

  // Fallback to SharedPreferences
  try {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('onboardingCompleted') ?? false;
    debugPrint('📋 SharedPreferences onboardingCompleted: $value');
    return value;
  } catch (e) {
    debugPrint('❌ Error checking onboarding status from SharedPreferences: $e');
    return false;
  }
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingCompletedState = ref.watch(onboardingCompletedProvider);
  final welcomeCompletedState = ref.watch(welcomeCompletedProvider);

  final isAuthenticated = authState.valueOrNull ?? false;
  final hasSeenOnboarding = onboardingCompletedState.valueOrNull ?? false;
  final hasCompletedWelcome = welcomeCompletedState.valueOrNull ?? false;

  debugPrint("🔑 isLoggedIn: $isAuthenticated");
  debugPrint("🚀 hasSeenOnboarding: $hasSeenOnboarding");
  debugPrint("👋 hasCompletedWelcome: $hasCompletedWelcome");

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error.toString(),
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final loc = state.matchedLocation;
      final isSplash = loc == RouteNames.splash;
      final isOnboarding = loc == RouteNames.onboarding;
      final isWelcome = loc == RouteNames.welcome;
      final isLoggingIn = loc == RouteNames.login;
      final isSignup = loc == RouteNames.signup;
      final isForgotPassword = loc == RouteNames.forgotPassword;
      final isAuthScreen = isLoggingIn || isSignup || isForgotPassword;

      debugPrint('📍 Current location: $loc');
      debugPrint('🔐 Authenticated: $isAuthenticated');
      debugPrint('🎬 Onboarding done: $hasSeenOnboarding');
      debugPrint('👋 Welcome done: $hasCompletedWelcome');

      // 1. Allow access to splash screen always
      if (isSplash) return null;

      // 2. If onboarding is not completed, redirect to onboarding
      if (!hasSeenOnboarding && !isOnboarding) {
        debugPrint('🔄 Redirecting to onboarding (onboarding not completed)');
        return RouteNames.onboarding;
      }

      // 3. If onboarding is completed but welcome is not, handle welcome flow
      if (hasSeenOnboarding && !hasCompletedWelcome && !isAuthenticated) {
        // Allow navigation to auth screens from welcome
        if (isAuthScreen) {
          debugPrint('✅ Allowing navigation to auth screen from welcome');
          return null;
        }
        // Otherwise redirect to welcome
        if (!isWelcome) {
          debugPrint('🔄 Redirecting to welcome (welcome not completed)');
          return RouteNames.welcome;
        }
        return null;
      }

      // 4. Auth flow - if onboarding is complete and not authenticated
      if (hasSeenOnboarding &&
          hasCompletedWelcome &&
          !isAuthenticated &&
          !isAuthScreen) {
        debugPrint('🔄 Not authenticated, redirecting to login');
        return RouteNames.login;
      }

      // 5. If authenticated but viewing auth screens, redirect to dashboard
      if (isAuthenticated && (isAuthScreen || isOnboarding || isWelcome)) {
        debugPrint('🔄 User authenticated, redirecting to dashboard');
        return RouteNames.dashboard;
      }

      // 6. Allow normal navigation
      debugPrint('✅ No redirection needed for $loc');
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
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: slideTransition,
        ),
      ),

      // Main App Routes
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(child: SizedBox()),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(child: SizedBox()),
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
        path: '/transcription/:id',
        name: 'transcriptionDetail',
        pageBuilder: (context, state) {
          final transcript = state.extra as Transcript;

          return CustomTransitionPage(
            key: state.pageKey,
            child: TranscriptionDetailScreen(
              transcript: transcript,
              transcriptionId: '',
            ),
            transitionsBuilder: slideTransition,
          );
        },
      ),
    ],
  );
});
