import 'package:flutter/material.dart';
import 'package:al_qari/config/themes/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondaryPurple,
            AppColors.darkPurple,
            AppColors.primaryPurple,
          ],
        ),
      ),

      child: child,
    );
  }
}
