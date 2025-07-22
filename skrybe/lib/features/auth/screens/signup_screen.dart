// lib/features/auth/screens/signup_screen.dart
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skrybe/data/providers/auth_provider.dart';
import 'package:skrybe/data/providers/auth_repository_provider.dart';
import 'package:skrybe/routes/route_names.dart';
import 'package:skrybe/widgets/custom_button.dart';
import 'package:skrybe/widgets/custom_text_field.dart';
import 'dart:ui';

import 'package:hive/hive.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCountryCode = '+1';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'(?=.*?[A-Z])').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'(?=.*?[a-z])').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'(?=.*?[0-9])').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);

    try {
      await authNotifier.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        context.go(RouteNames.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Color palette derived from background image
    final primaryColor =
        isDarkMode ? const Color(0xFF81A4FF) : const Color(0xFF3A6BFF);
    final secondaryColor =
        isDarkMode ? const Color(0xFFB8C7FF) : const Color(0xFF5C85FF);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/logo/freepik__the-style-is-candid-image-photography-with-natural__59130.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDarkMode
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                  isDarkMode
                      ? Colors.black.withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              // child: SingleChildScrollView(
              //   padding: const EdgeInsets.symmetric(
              //       horizontal: 24.0, vertical: 32.0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        64, // Subtract padding
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Logo with glow effect
                          Center(
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo/b3722b70-3858-47e0-bbbc-497c279ecbee.png', // Fixed path
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Back button and title row
                          Row(
                            children: [
                              // IconButton(
                              //   icon: Icon(Icons.arrow_back, color: textColor),
                              //   onPressed: () => context.go(RouteNames.welcome),
                              // ),
                              const Spacer(),
                              const Spacer(),
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(
                                  width: 48), // Balance the back button
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Full Name Field
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: _validateName,
                          ),

                          const SizedBox(height: 16),

                          // Email Field
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: _validateEmail,
                          ),

                          const SizedBox(height: 16),

                          // Phone Number Field with Country Code
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .inputDecorationTheme
                                  .fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                        .inputDecorationTheme
                                        .enabledBorder
                                        ?.borderSide
                                        .color ??
                                    Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Country Code Picker
                                CountryCodePicker(
                                  onChanged: (CountryCode code) {
                                    setState(() {
                                      _selectedCountryCode =
                                          code.dialCode ?? '+1';
                                    });
                                  },
                                  initialSelection: 'US',
                                  favorite: const ['US', 'CA', 'GB'],
                                  showCountryOnly: false,
                                  showOnlyCountryWhenClosed: false,
                                  alignLeft: false,
                                  padding: EdgeInsets.zero,
                                  textStyle: TextStyle(color: textColor),
                                ),

                                // Vertical divider
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),

                                // Phone number field
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    validator: _validatePhone,
                                    decoration: InputDecoration(
                                      hintText: 'Phone Number',
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16),
                                      prefixIcon:
                                          const Icon(Icons.phone_outlined),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                        minWidth: 0,
                                        minHeight: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Password Field
                          CustomTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            obscureText: !_isPasswordVisible,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: _validatePassword,
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password Field
                          CustomTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm Password',
                            obscureText: !_isConfirmPasswordVisible,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            validator: _validateConfirmPassword,
                          ),

                          const SizedBox(height: 24),

                          // Terms and Conditions Checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Sign Up Button
                          CustomButton(
                            onPressed: authState.isLoading ? null : _signUp,
                            text: 'Create Account',
                            isLoading: authState.isLoading,
                            backgroundColor: primaryColor,
                            textColor: Colors.white,
                            borderRadius: 30,
                            height: 56,
                          ),

                          const SizedBox(height: 20),

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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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

                          const SizedBox(height: 20), // Reduced spacing

                          // Google Sign-in Button
                          _buildGoogleSignInButton(context, ref),

                          const SizedBox(height: 24), // Reduced spacing

                          // Already have an account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go(RouteNames.login),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);

    return InkWell(
      onTap: () => _signInWithGoogle(context, ref),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
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
              'assets/logo/g-logo.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to built-in icon
                return Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: Color(0xFF4285F4),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign up with Google',
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
