import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/providers/auth_provider.dart';
import 'package:skrybe/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    final user = ref.read(currentUserProvider).valueOrNull;
    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');

    // Initialize animations
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _floatAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.repeat();
    _floatController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _backgroundController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        final user = ref.read(currentUserProvider).valueOrNull;
        _displayNameController.text = user?.displayName ?? '';
        _emailController.text = user?.email ?? '';
      }
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).updateUserProfile(
            displayName: _displayNameController.text,
            email: _emailController.text,
          );

      if (mounted) {
        _showSnackBar('Profile updated successfully', Colors.green);
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update profile: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Change Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimatedTextField(
              controller: passwordController,
              label: 'New Password',
              icon: Icons.key,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildAnimatedTextField(
              controller: confirmPasswordController,
              label: 'Confirm New Password',
              icon: Icons.key,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text != confirmPasswordController.text) {
                _showSnackBar('Passwords do not match', Colors.red);
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                final user = ref.read(currentUserProvider).valueOrNull;
                if (user != null && user.email != null) {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .resetPassword(user.email!);

                  if (mounted) {
                    _showSnackBar('Password reset email sent', Colors.green);
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar(
                      'Failed to update password: ${e.toString()}', Colors.red);
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_outlined, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to delete account: ${e.toString()}', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (userAsyncValue.isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            _AnimatedBackground(
              backgroundAnimation: _backgroundAnimation,
              isDark: isDark,
            ),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    final user = userAsyncValue.valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    final userModel = ref.watch(userModelProvider).valueOrNull;
    final formattedCreationDate = userModel?.createdAt != null
        ? '${userModel!.createdAt.day}/${userModel.createdAt.month}/${userModel.createdAt.year}'
        : user.metadata.creationTime != null
            ? '${user.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
            : 'Unknown date';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
          ).createShader(bounds),
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        theme.primaryColor.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    onPressed: _toggleEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      foregroundColor: theme.primaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _AnimatedBackground(
            backgroundAnimation: _backgroundAnimation,
            isDark: isDark,
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            )
          else
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildAnimatedAvatar(user, theme),
                      const SizedBox(height: 32),
                      if (_isEditing)
                        _buildEditMode(theme, isDark)
                      else
                        _buildDisplayMode(
                            user, formattedCreationDate, theme, isDark),
                      const SizedBox(height: 32),
                      _buildAnimatedThemeSelector(themeMode, theme, isDark),
                      if (!_isEditing) ...[
                        const SizedBox(height: 40),
                        _buildDeleteButton(theme),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAvatar(dynamic user, ThemeData theme) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Hero(
                  tag: 'profile-avatar',
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          theme.primaryColor.withOpacity(0.3),
                          theme.primaryColor.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: theme.primaryColor.withOpacity(0.2),
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Text(
                                (user.displayName?.isNotEmpty == true)
                                    ? user.displayName![0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEditMode(ThemeData theme, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                _buildAnimatedTextField(
                  controller: _displayNameController,
                  label: 'Display Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildAnimatedTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _buildAnimatedButton(
                  onPressed: _updateProfile,
                  icon: Icons.save_outlined,
                  label: 'Save Changes',
                  isPrimary: true,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                _buildAnimatedButton(
                  onPressed: _changePassword,
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  isPrimary: false,
                  theme: theme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.grey[850]!.withOpacity(0.8),
                  Colors.grey[900]!.withOpacity(0.6),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  Colors.grey[50]!.withOpacity(0.7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDisplayMode(
      dynamic user, String formattedDate, ThemeData theme, bool isDark) {
    final items = [
      {
        'icon': Icons.person_outline,
        'label': 'Display Name',
        'value': user.displayName ?? 'Not set'
      },
      {
        'icon': Icons.email_outlined,
        'label': 'Email',
        'value': user.email ?? 'Not set'
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Member Since',
        'value': formattedDate
      },
    ];

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.grey[850]!.withOpacity(0.8),
                              Colors.grey[900]!.withOpacity(0.6),
                            ]
                          : [
                              Colors.white.withOpacity(0.9),
                              Colors.grey[50]!.withOpacity(0.7),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              theme.primaryColor.withOpacity(0.2),
                              theme.primaryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['value'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8)
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: !isPrimary
            ? Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(isPrimary ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : theme.primaryColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildAnimatedThemeSelector(
      ThemeMode currentThemeMode, ThemeData theme, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.grey[850]!.withOpacity(0.8),
                          Colors.grey[900]!.withOpacity(0.6),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.grey[50]!.withOpacity(0.7),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              theme.primaryColor.withOpacity(0.2),
                              theme.primaryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'App Theme',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeOption(
                          title: 'Light',
                          icon: Icons.light_mode_outlined,
                          isSelected: currentThemeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildThemeOption(
                          title: 'Dark',
                          icon: Icons.dark_mode_outlined,
                          isSelected: currentThemeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildThemeOption(
                          title: 'System',
                          icon: Icons.settings_suggest_outlined,
                          isSelected: currentThemeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.2),
                    theme.primaryColor.withOpacity(0.1),
                  ],
                )
              : null,
          color:
              !isSelected ? theme.colorScheme.surface.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.primaryColor
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? theme.primaryColor
                    : theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.red.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: TextButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.delete_forever_outlined,
                    color: Colors.red, size: 20),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final Animation<double> backgroundAnimation;
  final bool isDark;

  const _AnimatedBackground({
    required this.backgroundAnimation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.grey[900]!,
                      Colors.blue[900]!.withOpacity(0.3),
                      Colors.purple[900]!.withOpacity(0.2),
                    ]
                  : [
                      Colors.blue[50]!,
                      Colors.purple[50]!,
                      Colors.white,
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Animated floating blobs
              Positioned(
                top: 100 + (30 * backgroundAnimation.value),
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.blue : Colors.blue[200])!
                        .withOpacity(0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: 200 + (20 * (1 - backgroundAnimation.value)),
                left: -50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.purple : Colors.purple[200])!
                        .withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                top: 250 + (15 * backgroundAnimation.value),
                left: 30,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.green : Colors.green[200])!
                        .withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 400 + (25 * backgroundAnimation.value),
                right: 20,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.orange : Colors.orange[200])!
                        .withOpacity(0.06),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
