import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Background wave animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Floating animation for main icon
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Pulse animation for FAB
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
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
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
    _backgroundController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background matching Dashboard
          _AnimatedBackground(
            backgroundAnimation: _backgroundAnimation,
            isDark: isDark,
          ),
          // Main content
          _buildEmptyState(context, theme, isDark),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () {
                  // Navigate to new transcription - existing functionality
                },
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(Icons.mic, size: 20),
                ),
                label: const Text(
                  'New Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Icon Container with floating effect
                  AnimatedBuilder(
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
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      theme.primaryColor.withOpacity(0.2),
                                      theme.primaryColor.withOpacity(0.05),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          theme.primaryColor.withOpacity(0.2),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              Colors.grey[800]!
                                                  .withOpacity(0.8),
                                              Colors.grey[850]!
                                                  .withOpacity(0.9),
                                            ]
                                          : [
                                              Colors.white.withOpacity(0.9),
                                              Colors.grey[50]!.withOpacity(0.8),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color:
                                          theme.primaryColor.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.history_outlined,
                                    size: 60,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 5),

                  // Main Title with gradient text
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isDark
                          ? [Colors.white, Colors.grey.shade300]
                          : [Colors.grey.shade800, Colors.grey.shade600],
                    ).createShader(bounds),
                    child: Text(
                      'No Transcripts Yet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle with animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Text(
                            'Start your first recording to see your\ntranscript history appear here',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                              height: 1.6,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Enhanced feature highlights with staggered animations
                  _buildAnimatedFeatureList(context, theme, isDark),
                ],
              ),
            ),

            // Enhanced bottom tip with glassmorphism effect
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 90),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 15),
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
                            padding: const EdgeInsets.all(10),
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
                              Icons.lightbulb_outline,
                              color: theme.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Tip: All your recordings are automatically saved and searchable',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFeatureList(
      BuildContext context, ThemeData theme, bool isDark) {
    final features = [
      {
        'icon': Icons.mic_outlined,
        'title': 'High-quality transcription',
        'color': Colors.green,
      },
      {
        'icon': Icons.search_outlined,
        'title': 'Search through all recordings',
        'color': Colors.blue,
      },
      {
        'icon': Icons.cloud_outlined,
        'title': 'Automatically saved to cloud',
        'color': Colors.purple,
      },
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.grey[850]!.withOpacity(0.3),
                              Colors.grey[900]!.withOpacity(0.1),
                            ]
                          : [
                              Colors.white.withOpacity(0.6),
                              Colors.grey[50]!.withOpacity(0.3),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (feature['color'] as Color).withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (feature['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          feature['icon'] as IconData,
                          size: 20,
                          color: feature['color'] as Color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        feature['title'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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
              // Animated blobs matching Dashboard
              Positioned(
                top: 150 + (40 * backgroundAnimation.value),
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.blue : Colors.blue[200])!
                        .withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 300 + (25 * (1 - backgroundAnimation.value)),
                left: -60,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.purple : Colors.purple[200])!
                        .withOpacity(0.08),
                  ),
                ),
              ),
              // Additional floating element
              Positioned(
                top: 300 + (20 * backgroundAnimation.value),
                left: 50,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.green : Colors.green[200])!
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
