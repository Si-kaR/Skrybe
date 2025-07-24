import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:skrybe/data/providers/auth_provider.dart';
import 'package:skrybe/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _floatController;
  late AnimationController _slideController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _slideAnimation;

  // Settings state
  bool _notificationsEnabled = true;
  bool _autoSaveEnabled = true;
  bool _highQualityMode = true;
  double _audioQuality = 0.8;
  String _selectedLanguage = 'English';
  bool _privacyMode = false;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Background wave animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // Floating animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Slide animation for cards
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _backgroundController.repeat();
    _floatController.repeat(reverse: true);
    _slideController.forward();
  }

  void _loadSettings() {
    final settings = Hive.box('settings');
    setState(() {
      _notificationsEnabled = settings.get('notifications', defaultValue: true);
      _autoSaveEnabled = settings.get('autoSave', defaultValue: true);
      _highQualityMode = settings.get('highQuality', defaultValue: true);
      _audioQuality = settings.get('audioQuality', defaultValue: 0.8);
      _selectedLanguage = settings.get('language', defaultValue: 'English');
      _privacyMode = settings.get('privacyMode', defaultValue: false);
    });
  }

  void _saveSetting(String key, dynamic value) {
    final settings = Hive.box('settings');
    settings.put(key, value);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.8),
            ],
          ).createShader(bounds),
          child: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.primaryColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Animated background matching History
          _AnimatedBackground(
            backgroundAnimation: _backgroundAnimation,
            isDark: isDark,
          ),
          // Main content
          _buildContent(context, theme, isDark, themeMode),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ThemeData theme, bool isDark, ThemeMode themeMode) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _slideAnimation.value)),
            child: Opacity(
              opacity: _slideAnimation.value,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 20),

                  // Profile Header with floating animation
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.3),
                        child: _buildProfileHeader(theme, isDark),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Appearance Section
                  _buildAnimatedSection(
                    theme,
                    isDark,
                    'Appearance',
                    Icons.palette_outlined,
                    Colors.purple,
                    _buildAppearanceSettings(theme, isDark, themeMode),
                    0,
                  ),

                  const SizedBox(height: 20),

                  // Recording Settings
                  _buildAnimatedSection(
                    theme,
                    isDark,
                    'Recording',
                    Icons.mic_outlined,
                    Colors.green,
                    _buildRecordingSettings(theme, isDark),
                    200,
                  ),

                  const SizedBox(height: 20),

                  // Privacy & Security
                  _buildAnimatedSection(
                    theme,
                    isDark,
                    'Privacy & Security',
                    Icons.security_outlined,
                    Colors.orange,
                    _buildPrivacySettings(theme, isDark),
                    400,
                  ),

                  const SizedBox(height: 20),

                  // Language Settings
                  _buildAnimatedSection(
                    theme,
                    isDark,
                    'Language',
                    Icons.language_outlined,
                    Colors.blue,
                    _buildLanguageSettings(theme, isDark),
                    600,
                  ),

                  const SizedBox(height: 20),

                  // Account Section
                  _buildAnimatedSection(
                    theme,
                    isDark,
                    'Account',
                    Icons.person_outline,
                    Colors.red,
                    _buildAccountSettings(theme, isDark),
                    800,
                  ),

                  const SizedBox(height: 20),

                  // About Section
                  _buildAnimatedSection(
                    theme,
                    isDark,
                    'About',
                    Icons.info_outline,
                    Colors.cyan,
                    _buildAboutSettings(theme, isDark),
                    1000,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    return Container(
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
                  Colors.blue[50]!.withOpacity(0.7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@example.com',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(
    ThemeData theme,
    bool isDark,
    String title,
    IconData icon,
    Color accentColor,
    Widget content,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
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
                  color: accentColor.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                accentColor.withOpacity(0.2),
                                accentColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icon,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppearanceSettings(
      ThemeData theme, bool isDark, ThemeMode themeMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest),
                  label: Text('System'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                ref.read(themeModeProvider.notifier).state = selection.first;
                _saveSetting('themeMode', selection.first.index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSettings(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          _buildSwitchTile(
            theme,
            'Auto-save recordings',
            'Automatically save recordings to cloud',
            Icons.cloud_upload_outlined,
            _autoSaveEnabled,
            (value) {
              setState(() => _autoSaveEnabled = value);
              _saveSetting('autoSave', value);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            theme,
            'High quality mode',
            'Better audio quality, larger file size',
            Icons.high_quality_outlined,
            _highQualityMode,
            (value) {
              setState(() => _highQualityMode = value);
              _saveSetting('highQuality', value);
            },
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audio Quality',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: theme.primaryColor,
                  inactiveTrackColor: theme.primaryColor.withOpacity(0.3),
                  thumbColor: theme.primaryColor,
                  overlayColor: theme.primaryColor.withOpacity(0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _audioQuality,
                  min: 0.3,
                  max: 1.0,
                  divisions: 7,
                  label: '${(_audioQuality * 100).round()}%',
                  onChanged: (value) {
                    setState(() => _audioQuality = value);
                    _saveSetting('audioQuality', value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          _buildSwitchTile(
            theme,
            'Notifications',
            'Receive notifications about recordings',
            Icons.notifications_outlined,
            _notificationsEnabled,
            (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications', value);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            theme,
            'Privacy Mode',
            'Hide sensitive content in recent apps',
            Icons.visibility_off_outlined,
            _privacyMode,
            (value) {
              setState(() => _privacyMode = value);
              _saveSetting('privacyMode', value);
            },
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            theme,
            'Clear Cache',
            'Free up storage space',
            Icons.cleaning_services_outlined,
            () => _showClearCacheDialog(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recognition Language',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
              items: _languages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedLanguage = newValue);
                  _saveSetting('language', newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          _buildActionTile(
            theme,
            'Export Data',
            'Download your recordings and transcripts',
            Icons.download_outlined,
            () => _showExportDialog(context, theme),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            theme,
            'Delete Account',
            'Permanently delete your account and data',
            Icons.delete_forever_outlined,
            () => _showDeleteAccountDialog(context, theme),
            isDestructive: true,
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            theme,
            'Sign Out',
            'Sign out of your account',
            Icons.logout,
            () => _showSignOutDialog(context, theme),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          _buildInfoTile(theme, 'App Version', '1.0.0', Icons.info_outline),
          const SizedBox(height: 16),
          _buildActionTile(
            theme,
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip_outlined,
            () => _showPrivacyPolicy(context, theme),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            theme,
            'Terms of Service',
            'Read our terms of service',
            Icons.description_outlined,
            () => _showTermsOfService(context, theme),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            theme,
            'Contact Support',
            'Get help with the app',
            Icons.support_agent_outlined,
            () => _showContactSupport(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: color.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      ThemeData theme, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showSignOutDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('SIGN OUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.cleaning_services, color: theme.primaryColor),
            const SizedBox(width: 12),
            const Text('Clear Cache'),
          ],
        ),
        content: const Text(
            'This will free up storage space by clearing temporary files. Your recordings will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement cache clearing logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.download, color: theme.primaryColor),
            const SizedBox(width: 12),
            const Text('Export Data'),
          ],
        ),
        content: const Text(
            'This will create a ZIP file containing all your recordings and transcripts. The download may take a few minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement data export logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Export started. You will be notified when complete.')),
              );
            },
            child: const Text('EXPORT'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
            'This action cannot be undone. All your recordings, transcripts, and account data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion logic
              _showFinalDeleteConfirmation(context, theme);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context, ThemeData theme) {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type "DELETE" to confirm account deletion:'),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'Type DELETE here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (confirmController.text == 'DELETE') {
                Navigator.pop(context);
                // Implement final account deletion logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deletion initiated')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please type DELETE to confirm')),
                );
              }
            },
            child: const Text('CONFIRM DELETION',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: theme.primaryColor),
            const SizedBox(width: 12),
            const Text('Privacy Policy'),
          ],
        ),
        content: const Text(
            'This would typically open your privacy policy document or redirect to a web page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open privacy policy URL
            },
            child: const Text('VIEW ONLINE'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.description, color: theme.primaryColor),
            const SizedBox(width: 12),
            const Text('Terms of Service'),
          ],
        ),
        content: const Text(
            'This would typically open your terms of service document or redirect to a web page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open terms URL
            },
            child: const Text('VIEW ONLINE'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: theme.primaryColor),
            const SizedBox(width: 12),
            const Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Get help with:'),
            const SizedBox(height: 12),
            const Text('• Technical issues'),
            const Text('• Account problems'),
            const Text('• Feature requests'),
            const Text('• General questions'),
            const SizedBox(height: 16),
            const Text('Email: support@skrybe.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open email client or contact form
            },
            child: const Text('EMAIL SUPPORT'),
          ),
        ],
      ),
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
              // Animated blobs matching History screen
              Positioned(
                top: 100 + (50 * backgroundAnimation.value),
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.blue : Colors.blue[200])!
                        .withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 200 + (30 * (1 - backgroundAnimation.value)),
                left: -70,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.purple : Colors.purple[200])!
                        .withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                top: 250 + (25 * backgroundAnimation.value),
                left: 30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.green : Colors.green[200])!
                        .withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 100 + (35 * (1 - backgroundAnimation.value)),
                right: 20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.orange : Colors.orange[200])!
                        .withOpacity(0.07),
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
