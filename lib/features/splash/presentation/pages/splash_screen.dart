import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/core/services/session_service.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:al_qari/features/auth/presentation/controllers/auth_controller.dart';
import 'package:al_qari/features/splash/presentation/controllers/splash_controller.dart';
import 'package:al_qari/widgets/gradient_background_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late SplashController controller;

  @override
  void initState() {
    super.initState();
    controller = SplashController(this);
    controller.start(_navigate);
  }

  Future<void> _navigate() async {
    final auth = Get.find<AuthController>();
    if (auth.isAuthenticated) {
      final remembered = SessionService.getRememberMe();
      if (remembered) {
        Get.offNamed(AppRoutes.nav);
      } else {
        // Firebase persists the token on mobile — sign out if user didn't
        // choose to be remembered.
        await auth.signOutSilent();
        Get.offNamed(AppRoutes.onboarding);
      }
    } else {
      Get.offNamed(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: FadeTransition(
          opacity: controller.fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.logoFull,
                height: Responsive.screenHeight(context) * 0.35,
              ),
              Image.asset(
                AppAssets.splash,
                height: Responsive.screenHeight(context) * 0.4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
