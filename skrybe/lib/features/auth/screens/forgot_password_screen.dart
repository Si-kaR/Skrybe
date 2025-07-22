// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skrybe/data/providers/auth_provider.dart';
import 'package:skrybe/routes/route_names.dart';
import 'package:skrybe/widgets/custom_button.dart';
import 'package:skrybe/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _resetEmailSent = false;

  // Animation controllers
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start the animation when the screen is built
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the authNotifierProvider to reset password
      await ref.read(authNotifierProvider.notifier).resetPassword(
            _emailController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _resetEmailSent = true;
          _isLoading = false;
        });

        // Reset animation and play again for success view
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        // Shake animation for error
        _showErrorShakeAnimation();
      }
    }
  }

  void _showErrorShakeAnimation() {
    // Simple shake animation using the ScaffoldMessenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(_errorMessage ?? 'An error occurred'),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the auth state to handle loading and errors
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Update local state based on the provider state
    if (authState.isLoading && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    } else if (authState.hasError && _errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _errorMessage = authState.error.toString();
          _isLoading = false;
        });
        _showErrorShakeAnimation();
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.login),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
                'assets/logo/auth_background.jpg'), // Add your background image
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.8),
                colorScheme.surface.withOpacity(0.9),
                colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _resetEmailSent
                                ? _buildSuccessView()
                                : _buildResetForm(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Hero(
            tag: 'auth_icon',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lock_reset,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Forgot Password',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter your email address and we will send you instructions to reset your password.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 1),
          Card(
            elevation: 8,
            shadowColor: colorScheme.primary.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.95),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(Icons.email_outlined,
                          color: colorScheme.primary),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    CustomButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      text: 'Send Reset Instructions',
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: TextButton.icon(
              onPressed: () => context.go(RouteNames.login),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Login'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const Spacer(flex: 1),
        Card(
          elevation: 12,
          shadowColor: Colors.green.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_read,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Email Sent',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We have sent password reset instructions to:',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _emailController.text,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please check your inbox and follow the instructions to reset your password.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    onPressed: () => context.go(RouteNames.login),
                    text: 'Back to Login',
                    icon: const Icon(Icons.login),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
// // lib/features/auth/screens/forgot_password_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:skrybe/data/providers/auth_provider.dart';
// import 'package:skrybe/routes/route_names.dart';
// import 'package:skrybe/widgets/custom_button.dart';
// import 'package:skrybe/widgets/custom_text_field.dart';

// class ForgotPasswordScreen extends ConsumerStatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   ConsumerState<ForgotPasswordScreen> createState() =>
//       _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   bool _isLoading = false;
//   String? _errorMessage;
//   bool _resetEmailSent = false;

//   // Animation controllers
//   late final AnimationController _animationController;
//   late final Animation<double> _fadeAnimation;
//   late final Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeIn,
//       ),
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0.0, 0.2),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeOut,
//       ),
//     );

//     // Start the animation when the screen is built
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _resetPassword() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       // Use the authNotifierProvider to reset password
//       await ref.read(authNotifierProvider.notifier).resetPassword(
//             _emailController.text.trim(),
//           );

//       if (mounted) {
//         setState(() {
//           _resetEmailSent = true;
//           _isLoading = false;
//         });

//         // Reset animation and play again for success view
//         _animationController.reset();
//         _animationController.forward();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//           _isLoading = false;
//         });

//         // Shake animation for error
//         _showErrorShakeAnimation();
//       }
//     }
//   }

//   void _showErrorShakeAnimation() {
//     // Simple shake animation using the ScaffoldMessenger
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     scaffoldMessenger.clearSnackBars();
//     scaffoldMessenger.showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Text(_errorMessage ?? 'An error occurred'),
//             ),
//           ],
//         ),
//         backgroundColor: Theme.of(context).colorScheme.error,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Listen to the auth state to handle loading and errors
//     final authState = ref.watch(authNotifierProvider);
//     final colorScheme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     // Update local state based on the provider state
//     if (authState.isLoading && !_isLoading) {
//       setState(() {
//         _isLoading = true;
//       });
//     } else if (authState.hasError && _errorMessage == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         setState(() {
//           _errorMessage = authState.error.toString();
//           _isLoading = false;
//         });
//         _showErrorShakeAnimation();
//       });
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reset Password'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.go(RouteNames.login),
//         ),
//         elevation: 0,
//         backgroundColor: colorScheme.surface,
//         foregroundColor: colorScheme.onSurface,
//       ),
//       body: SafeArea(
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 colorScheme.surface,
//                 colorScheme.surface.withOpacity(0.95),
//               ],
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: SlideTransition(
//                 position: _slideAnimation,
//                 child:
//                     _resetEmailSent ? _buildSuccessView() : _buildResetForm(),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResetForm() {
//     final colorScheme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     return Form(
//       key: _formKey,
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const SizedBox(height: 24),
//             Hero(
//               tag: 'auth_icon',
//               child: Icon(
//                 Icons.lock_reset,
//                 size: 80,
//                 color: colorScheme.primary,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'Forgot Password',
//               style: textTheme.headlineMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onSurface,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Enter your email address and we will send you instructions to reset your password.',
//               style: textTheme.bodyMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 40),
//             Card(
//               elevation: 4,
//               shadowColor: colorScheme.primary.withOpacity(0.3),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     CustomTextField(
//                       controller: _emailController,
//                       hintText: 'Email',
//                       keyboardType: TextInputType.emailAddress,
//                       prefixIcon: Icon(Icons.email_outlined,
//                           color: colorScheme.primary),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your email';
//                         }
//                         if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                             .hasMatch(value)) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 24),
//                     if (_errorMessage != null)
//                       Container(
//                         padding: const EdgeInsets.all(12.0),
//                         decoration: BoxDecoration(
//                           color: colorScheme.errorContainer,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.error_outline,
//                               color: colorScheme.error,
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 _errorMessage!,
//                                 style: textTheme.bodyMedium?.copyWith(
//                                   color: colorScheme.onErrorContainer,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     const SizedBox(height: 24),
//                     CustomButton(
//                       onPressed: _isLoading ? null : _resetPassword,
//                       text: 'Send Reset Instructions',
//                       isLoading: _isLoading,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 32),
//             TextButton.icon(
//               onPressed: () => context.go(RouteNames.login),
//               icon: const Icon(Icons.arrow_back),
//               label: const Text('Back to Login'),
//               style: TextButton.styleFrom(
//                 foregroundColor: colorScheme.primary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSuccessView() {
//     final colorScheme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     return Center(
//       child: Card(
//         elevation: 8,
//         shadowColor: Colors.green.withOpacity(0.4),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(24),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.mark_email_read,
//                 size: 80,
//                 color: Colors.green,
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Reset Email Sent',
//                 style: textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.onSurface,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'We have sent password reset instructions to:',
//                 style: textTheme.bodyLarge?.copyWith(
//                   color: colorScheme.onSurfaceVariant,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _emailController.text,
//                 style: textTheme.bodyLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.primary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Please check your inbox and follow the instructions to reset your password.',
//                 style: textTheme.bodyMedium?.copyWith(
//                   color: colorScheme.onSurfaceVariant,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),
//               CustomButton(
//                 onPressed: () => context.go(RouteNames.login),
//                 text: 'Back to Login',
//                 icon: Icon(Icons.login),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
