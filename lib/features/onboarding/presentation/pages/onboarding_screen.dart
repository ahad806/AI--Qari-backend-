import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint('Onboarding Finished');
      Get.offNamed('/login');
      // Get.offNamed('/signup');
    }
  }

  // void _skip() {
  //   _pageController.animateToPage(
  //     2,
  //     duration: const Duration(milliseconds: 400),
  //     curve: Curves.easeInOut,
  //   );
  // }

  List<Widget> get _pages => [
    // Page 1
    OnboardingBackground(
      decorations: [
        Positioned(
          top: -100,
          left: -10,
          child: Image.asset(AppAssets.ob1TopLeft, width: 120),
        ),
        Positioned(
          top: 0,
          right: -25,
          child: Image.asset(AppAssets.ob1TopRight, width: 120),
        ),
        Positioned(
          top: 400,
          left: -30,
          child: Image.asset(AppAssets.ob1MiddleLeft, width: 120),
        ),
        Positioned(
          top: 300,
          right: -10,
          child: Image.asset(AppAssets.ob1MiddleRight, width: 200),
        ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.onboarding1,
            height: Responsive.screenHeight(context) * 0.35,
          ),
          // const SizedBox(height: 40),
          SizedBox(
            width: Responsive.screenWidth(context) * 0.8,
            child: Text(
              "Learn the Quran the Right Way",
              style: GoogleFonts.righteous(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 1.5,
                  //fontWeight: FontWeight.bold,
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(height: Responsive.screenHeight(context) * 0.02),
          SizedBox(
            width: Responsive.screenWidth(context) * 0.8,

            child: Text(
              "Experience accurate Tajweed guidance with real-time feedback.",
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    ),

    // Page 2
    OnboardingBackground(
      decorations: [
        Positioned(
          top: 300,
          right: -10,
          child: Image.asset(AppAssets.ob2MiddleRight, width: 110),
        ),
        Positioned(
          top: 500,
          left: -30,
          child: Image.asset(AppAssets.ob1MiddleLeft, width: 110),
        ),
        Positioned(
          left: 0,
          top: -50,
          child: Image.asset(AppAssets.ob1TopLeft, width: 90),
        ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.onboarding2,
            height: Responsive.screenHeight(context) * 0.35,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: Responsive.screenWidth(context) * 0.8,
            child: Text(
              "Practice Anytime, Anywhere",
              // style: TextStyle(
              //   color: Colors.white,
              //   fontSize: 24,
              //   fontWeight: FontWeight.bold,
              // ),
              style: GoogleFonts.righteous(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 1.5,
                  //fontWeight: FontWeight.bold,
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(height: Responsive.screenHeight(context) * 0.02),
          SizedBox(
            width: Responsive.screenWidth(context) * 0.8,
            child: Text(
              "Recite selected Surahs at your own pace, and get instant corrections from your digital Qari.",
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    ),

    // Page 3
    OnboardingBackground(
      decorations: [
        Positioned(
          top: -40,
          right: -45,
          child: Image.asset(
            AppAssets.ob3TopRight,

            width: Responsive.screenWidth(context) * 0.7,
          ),
        ),
        Positioned(
          left: -80,
          top: -50,
          child: Image.asset(
            AppAssets.ob3TopLeft,
            width: Responsive.screenWidth(context) * 0.7,
          ),
        ),
        Positioned(
          left: -130,
          bottom: 160,
          child: Image.asset(
            AppAssets.ob3BottomLeft,
            width: Responsive.screenWidth(context) * 0.7,
          ),
        ),
        Positioned(
          right: -125,
          top: -170,
          child: Image.asset(
            AppAssets.ob3BottomRight,
            width: Responsive.screenWidth(context) * 0.7,
          ),
        ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.onboarding3,
            height: Responsive.screenHeight(context) * 0.35,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: Responsive.screenWidth(context) * 0.8,
            child: Text(
              "Simple, Accessible,\nand Authentic",
              style: GoogleFonts.righteous(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 1.5,
                  //fontWeight: FontWeight.bold,
                ),
              ),

              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(height: Responsive.screenHeight(context) * 0.02),
          SizedBox(
            width: Responsive.screenWidth(context) * 0.8,
            child: Text(
              "Learn through verified Quran text and audio. All in one easy-to-use app.",
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              textAlign: TextAlign.left,
              maxLines: 3,
            ),
          ),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: _pages,
            onPageChanged: (index) => setState(() => _currentPage = index),
          ),

          // Skip Button
          // Positioned(
          //   top: 50,
          //   right: 20,
          //   child: _currentPage != 2
          //       ? TextButton(
          //           onPressed: _skip,
          //           child: const Text(
          //             "Skip",
          //             style: TextStyle(color: Colors.white70, fontSize: 16),
          //           ),
          //         )
          //       : const SizedBox(),
          // ),

          // Page indicators + Next/Get Started Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 20 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? "Get Started" : "Next",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
