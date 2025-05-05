// // TODO Implement this library.
// import 'package:flutter/material.dart';

// class OnboardingScreen extends StatelessWidget {
//   const OnboardingScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text('Onboarding Screen'),
//       ),
//     );
//   }
// }

// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _lottieController;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Record Audio',
      description:
          'Capture high-quality audio and get real-time transcription with just a tap.',
      lottieAsset: 'assets/animations/recording.json',
      color: const Color(0xFF6C63FF),
    ),
    OnboardingItem(
      title: 'Upload Files',
      description:
          'Import audio and video files from your device to transcribe instantly.',
      lottieAsset: 'assets/animations/uploading.json',
      color: const Color(0xFF4CAF50),
    ),
    OnboardingItem(
      title: 'View Transcripts',
      description:
          'Access, edit, and share your transcripts in multiple formats.',
      lottieAsset: 'assets/animations/documents.json',
      color: const Color(0xFFFF9800),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  void _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
  }

  void _navigateToWelcome() {
    _markOnboardingComplete();
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient based on current page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _onboardingItems[_currentPage].color.withOpacity(0.8),
                  _onboardingItems[_currentPage].color.withOpacity(0.2),
                ],
              ),
            ),
          ),

          // Onboarding content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: _navigateToWelcome,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingItems.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(context, _onboardingItems[index]);
                    },
                  ),
                ),

                // Page indicator and button
                Padding(
                  padding: const EdgeInsets.only(bottom: 48.0),
                  child: Column(
                    children: [
                      // Page indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingItems.length,
                          (index) => _buildPageIndicator(index == _currentPage),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Next or Get Started button
                      _currentPage < _onboardingItems.length - 1
                          ? _buildNextButton()
                          : _buildGetStartedButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Lottie.asset(
              item.lottieAsset,
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration
                  ..repeat();
              },
            ),
          ),
          const SizedBox(height: 40),

          // Title with animated reveal
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              item.title,
              style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Description with animated reveal
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              item.description,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _onboardingItems[_currentPage].color,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: const Text('Next',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGetStartedButton() {
    return Hero(
      tag: 'getStartedButton',
      child: ElevatedButton(
        onPressed: _navigateToWelcome,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _onboardingItems[_currentPage].color,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String lottieAsset;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.lottieAsset,
    required this.color,
  });
}
