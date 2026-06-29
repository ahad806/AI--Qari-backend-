import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:al_qari/features/quran/presentation/controllers/reading_controller.dart';
import 'package:al_qari/features/quran/presentation/pages/reading_setup_screen.dart';
import 'package:al_qari/features/quran/presentation/pages/reading_active_screen.dart';
import 'package:al_qari/features/quran/presentation/pages/reading_result_screen.dart';
import 'package:al_qari/features/recitation/presentation/controllers/recitation_controller.dart';
import 'package:al_qari/features/recitation/presentation/pages/recitation_setup_screen.dart';
import 'package:al_qari/features/recitation/presentation/pages/recitation_active_screen.dart';
import 'package:al_qari/features/recitation/presentation/pages/recitation_result_screen.dart';
import 'package:al_qari/features/auth/presentation/pages/login_screen.dart';
import 'package:al_qari/features/auth/presentation/pages/signup_screen.dart';
import 'package:al_qari/core/navigation/bottom_nav_bar.dart';
import 'package:al_qari/features/home/presentation/pages/home_screen.dart';
import 'package:al_qari/features/learn/presentation/pages/learn_screen.dart';
import 'package:al_qari/features/learn/presentation/pages/quaida_screen.dart';
import 'package:al_qari/features/learn/presentation/pages/tajweed_screen.dart';
import 'package:al_qari/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:al_qari/features/profile/presentation/pages/profile_screen.dart';
import 'package:al_qari/features/progress/progress_screen.dart';
import 'package:al_qari/features/splash/presentation/pages/splash_screen.dart';
import 'package:get/get.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => OnboardingScreen()),
    GetPage(name: AppRoutes.nav, page: () => BottomNavBar()),
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),
    GetPage(name: AppRoutes.home, page: () => HomeScreen()),
    GetPage(name: AppRoutes.signup, page: () => SignupScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPasswordScreen()),
    GetPage(name: AppRoutes.profile, page: () => ProfileScreen()),
    GetPage(name: AppRoutes.progress, page: () => const ProgressScreen()),
    GetPage(name: AppRoutes.learn, page: () => LearnScreen()),
    // GetPage(
    //   name: AppRoutes.quranIndex,
    //   page: () {
    //     final QuranMode mode = Get.arguments as QuranMode;
    //     return QuranIndexScreen(mode: mode);
    //   },
    // ),
    GetPage(name: AppRoutes.tajweed, page: () => TajweedScreen()),
    GetPage(name: AppRoutes.qaida, page: () => QaidaScreen()),
    GetPage(
      name: AppRoutes.recitationSetup,
      page: () => const RecitationSetupScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => RecitationController())),
    ),
    GetPage(
      name: AppRoutes.recitationActive,
      page: () => const RecitationActiveScreen(),
    ),
    GetPage(
      name: AppRoutes.recitationResult,
      page: () => const RecitationResultScreen(),
    ),
    GetPage(
      name: AppRoutes.readingSetup,
      page: () => const ReadingSetupScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ReadingController())),
    ),
    GetPage(
      name: AppRoutes.readingActive,
      page: () => const ReadingActiveScreen(),
    ),
    GetPage(
      name: AppRoutes.readingResult,
      page: () => const ReadingResultScreen(),
    ),
    // GetPage(
    //   name: AppRoutes.mushaf,
    //   page: () => MushafReadingScreen(),
    //   binding: MushafBinding(),
    // ),

    // GetPage(name: AppRoutes.surah, page: () => SurahScreen()),
  ];
}
