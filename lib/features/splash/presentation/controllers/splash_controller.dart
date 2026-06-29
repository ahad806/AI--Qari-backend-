import 'package:flutter/material.dart';

class SplashController {
  late final AnimationController fadeController;
  late final Animation<double> fadeAnimation;

  SplashController(TickerProvider vsync) {
    fadeController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 1),
    );

    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeIn,
    );
  }

  void start(Future<void> Function() onFinish) {
    fadeController.forward();
    Future.delayed(const Duration(seconds: 5), onFinish);
  }

  void dispose() {
    fadeController.dispose();
  }
}
