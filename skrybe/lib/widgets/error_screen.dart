// TODO Implement this library.

// lib/widgets/error_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:skrybe/routes/app_router.dart';
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
                Lottie.asset(
                  'assets/animations/error.json',
                  width: 200,
                  height: 200,
                ),
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
                  onPressed: () => context.go(RouteNames.dashboard),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Dashboard'),
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
}
