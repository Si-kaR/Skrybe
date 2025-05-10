// Modified error_screen.dart to handle missing assets gracefully

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:skrybe/routes/route_names.dart';

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie animation with fallback
                _buildLottieOrFallback(context),
                const SizedBox(height: 24),
                Text(
                  'Oops! Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ).animate().fade(duration: 500.ms).slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ).animate().fade(duration: 500.ms).slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Check if we can go to dashboard, or fallback to onboarding
                    try {
                      context.go(RouteNames.home);
                    } catch (e) {
                      debugPrint('Error navigating to dashboard: $e');
                      try {
                        context.go(RouteNames.onboarding);
                      } catch (e) {
                        debugPrint('Error navigating to onboarding: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go Back to Safety'),
                ).animate().fade(duration: 500.ms).slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLottieOrFallback(BuildContext context) {
    try {
      return Lottie.asset(
        'asssets/animations/errorb.json',
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Failed to load Lottie animation: $error');
          // Fallback to an icon
          return Icon(
            Icons.error_outline,
            size: 100,
            color: Theme.of(context).colorScheme.error,
          );
        },
      );
    } catch (e) {
      debugPrint('Exception loading Lottie animation: $e');
      // Fallback to an icon
      return Icon(
        Icons.error_outline,
        size: 100,
        color: Theme.of(context).colorScheme.error,
      );
    }
  }
}

// // lib/widgets/error_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lottie/lottie.dart';
// import 'package:skrybe/routes/route_names.dart';

// class ErrorScreen extends StatelessWidget {
//   final String error;

//   const ErrorScreen({
//     super.key,
//     required this.error,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Lottie.asset(
//                   'assets/animations/errorb.json',
//                   width: 200,
//                   height: 200,
//                 ),
//                 const SizedBox(height: 24),
//                 Text(
//                   'Oops! Something went wrong',
//                   style: Theme.of(context).textTheme.headlineSmall,
//                   textAlign: TextAlign.center,
//                 ).animate().fade(duration: 500.ms).slideY(
//                     begin: 0.3,
//                     end: 0,
//                     duration: 500.ms,
//                     curve: Curves.easeOut),
//                 const SizedBox(height: 16),
//                 Text(
//                   error,
//                   style: Theme.of(context).textTheme.bodyMedium,
//                   textAlign: TextAlign.center,
//                 ).animate().fade(duration: 500.ms).slideY(
//                     begin: 0.3,
//                     end: 0,
//                     duration: 500.ms,
//                     curve: Curves.easeOut),
//                 const SizedBox(height: 32),
//                 ElevatedButton(
//                   onPressed: () => context.go(RouteNames.dashboard),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text('Go to Dashboard'),
//                 ).animate().fade(duration: 500.ms).slideY(
//                     begin: 0.3,
//                     end: 0,
//                     duration: 500.ms,
//                     curve: Curves.easeOut),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
