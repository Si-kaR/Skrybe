// // lib/features/auth/screens/welcome_screen.dart

// lib/features/auth/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:skrybe/data/providers/auth_repository_provider.dart';
import 'package:skrybe/routes/route_names.dart';
import 'package:skrybe/widgets/custom_button.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize video player
    _videoController =
        VideoPlayerController.asset('asssets/videos/WelcomeScreen.mp4')
          ..initialize().then((_) {
            // Ensure the first frame is shown
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
            }
            // Start playing and looping the video
            _videoController.setLooping(true);
            _videoController.setVolume(0.0); // Mute the video
            _videoController.play();
          });
  }

  @override
  void dispose() {
    // Clean up video controller when the widget is removed
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Color palette derived from background
    final primaryColor =
        isDarkMode ? const Color(0xFF81A4FF) : const Color(0xFF3A6BFF);
    final secondaryColor =
        isDarkMode ? const Color(0xFFB8C7FF) : const Color(0xFF5C85FF);
    final buttonTextColor = Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);

    return Scaffold(
      body: Stack(
        children: [
          // Video Background Layer
          Positioned.fill(
            child: _isVideoInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(
                    color: isDarkMode
                        ? Colors.black
                        : Colors.white), // Placeholder while video loads
          ),

          // Blur and Gradient Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDarkMode
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.6),
                      isDarkMode
                          ? Colors.black.withOpacity(0.8)
                          : Colors.white.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content Layer
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top spacing
                    SizedBox(height: size.height * 0.05),

                    // App Logo with glow effect
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'asssets/logo/lop1.jpeg', // Keep the original logo
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Title
                    Text(
                      'Skrybe',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: primaryColor.withOpacity(0.5),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // App Tagline
                    Text(
                      'Voice transcription reimagined',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: size.height * 0.08),

                    // Login Button
                    CustomButton(
                      onPressed: () => context.go(RouteNames.login),
                      text: 'Login',
                      backgroundColor: primaryColor,
                      textColor: buttonTextColor,
                      borderRadius: 30,
                      height: 56,
                    ),

                    const SizedBox(height: 16),

                    // Signup Button
                    CustomButton(
                      onPressed: () => context.go(RouteNames.signup),
                      text: 'Create Account',
                      backgroundColor: Colors.transparent,
                      textColor: primaryColor,
                      borderRadius: 30,
                      height: 56,
                      borderColor: primaryColor,
                      borderWidth: 2,
                    ),

                    const SizedBox(height: 24),

                    // Divider with "OR" text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: textColor.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: textColor.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Sign-in Button
                    _buildGoogleSignInButton(context, ref),

                    const SizedBox(height: 32),

                    // Terms and Privacy Policy
                    Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Bottom spacing
                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _signInWithGoogle(context, ref),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'asssets/icons/g-logo.png', // Ensure this asset exists
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.g_mobiledata,
                  size: 24,
                  color: Colors.red,
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithGoogle();

      // Add this code to mark welcome as completed
      try {
        final settingsBox = await Hive.openBox('settings');
        await settingsBox.put('welcomeCompleted', true);
      } catch (e) {
        debugPrint('❌ Error marking welcome as completed: $e');
      }

      // Change the route to dashboard
      if (context.mounted) {
        context.go(RouteNames.dashboard);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:skrybe/data/providers/auth_repository_provider.dart';
// import 'package:skrybe/data/repositories/auth_repository.dart';
// import 'package:skrybe/routes/route_names.dart';
// import 'package:skrybe/widgets/custom_button.dart';
// import 'dart:ui';

// class WelcomeScreen extends ConsumerWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Get the screen dimensions for responsive layout
//     final size = MediaQuery.of(context).size;
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     // Color palette derived from background image
//     final primaryColor =
//         isDarkMode ? const Color(0xFF81A4FF) : const Color(0xFF3A6BFF);
//     final secondaryColor =
//         isDarkMode ? const Color(0xFFB8C7FF) : const Color(0xFF5C85FF);
//     final buttonTextColor = Colors.white;
//     final textColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background Image Layer
//           Positioned.fill(
//             child: Image.asset(
//               'assets/images/background.jpg', // Make sure this background image exists in your assets
//               fit: BoxFit.cover,
//             ),
//           ),

//           // Blur and Gradient Overlay
//           Positioned.fill(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       isDarkMode
//                           ? Colors.black.withOpacity(0.6)
//                           : Colors.white.withOpacity(0.6),
//                       isDarkMode
//                           ? Colors.black.withOpacity(0.8)
//                           : Colors.white.withOpacity(0.7),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Content Layer
//           SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 32.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Top spacing
//                     SizedBox(height: size.height * 0.05),

//                     // App Logo with glow effect
//                     Container(
//                       height: 120,
//                       width: 120,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: primaryColor.withOpacity(0.5),
//                             blurRadius: 20,
//                             spreadRadius: 5,
//                           ),
//                         ],
//                       ),
//                       child: ClipOval(
//                         child: Image.asset(
//                           'assets/logo/lop1.jpeg', // Keep the original logo
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // App Title
//                     Text(
//                       'Skrybe',
//                       style: TextStyle(
//                         fontSize: 48,
//                         fontWeight: FontWeight.bold,
//                         color: textColor,
//                         letterSpacing: 1.2,
//                         shadows: [
//                           Shadow(
//                             color: primaryColor.withOpacity(0.5),
//                             blurRadius: 5,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     // App Tagline
//                     Text(
//                       'Voice transcription reimagined',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: textColor.withOpacity(0.8),
//                         fontWeight: FontWeight.w500,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),

//                     SizedBox(height: size.height * 0.08),

//                     // Login Button
//                     CustomButton(
//                       onPressed: () => context.go(RouteNames.login),
//                       text: 'Login',
//                       backgroundColor: primaryColor,
//                       textColor: buttonTextColor,
//                       borderRadius: 30,
//                       height: 56,
//                     ),

//                     const SizedBox(height: 16),

//                     // Signup Button
//                     CustomButton(
//                       onPressed: () => context.go(RouteNames.signup),
//                       text: 'Create Account',
//                       backgroundColor: Colors.transparent,
//                       textColor: primaryColor,
//                       borderRadius: 30,
//                       height: 56,
//                       borderColor: primaryColor,
//                       borderWidth: 2,
//                     ),

//                     const SizedBox(height: 24),

//                     // Divider with "OR" text
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Divider(
//                             color: textColor.withOpacity(0.3),
//                             thickness: 1,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                           child: Text(
//                             'OR',
//                             style: TextStyle(
//                               color: textColor.withOpacity(0.6),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: Divider(
//                             color: textColor.withOpacity(0.3),
//                             thickness: 1,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 24),

//                     // Google Sign-in Button
//                     _buildGoogleSignInButton(context, ref),

//                     const SizedBox(height: 32),

//                     // Terms and Privacy Policy
//                     Text(
//                       'By continuing, you agree to our Terms of Service and Privacy Policy',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: textColor.withOpacity(0.6),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),

//                     // Bottom spacing
//                     SizedBox(height: size.height * 0.05),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
//     return InkWell(
//       onTap: () => _signInWithGoogle(context, ref),
//       borderRadius: BorderRadius.circular(30),
//       child: Container(
//         height: 56,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               spreadRadius: 1,
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset(
//               'assets/icons/g-logo.png', // Ensure this asset exists
//               height: 24,
//               width: 24,
//               errorBuilder: (context, error, stackTrace) {
//                 return const Icon(
//                   Icons.g_mobiledata,
//                   size: 24,
//                   color: Colors.red,
//                 );
//               },
//             ),
//             const SizedBox(width: 12),
//             const Text(
//               'Continue with Google',
//               style: TextStyle(
//                 color: Color(0xFF4285F4),
//                 fontWeight: FontWeight.w500,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
//     try {
//       // // You would implement this in your AuthRepository
//       final authRepository = ref.read(authRepositoryProvider);
//       await authRepository.signInWithGoogle();

//       // For now, let's just show a snackbar
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Google Sign-In would happen here.'),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
// }
