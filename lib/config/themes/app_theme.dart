import 'package:al_qari/core/utils/responsive.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    final baseFontSize = Responsive.responsiveSize(context);

    return ThemeData(
      primaryColor: AppColors.primaryPurple,
      scaffoldBackgroundColor: AppColors.backgroundWhite,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.darkPurple,
        surface: AppColors.backgroundWhite,
        error: AppColors.error,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.fixed),
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          fontSize: baseFontSize * 0.04,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: baseFontSize * 0.045,
          color: AppColors.textPrimary,
          // color: Colors.red,
        ),
        bodySmall: TextStyle(
          fontSize: baseFontSize * 0.04,
          color: AppColors.textSecondary,
        ),
        titleLarge: TextStyle(
          fontSize: baseFontSize * 0.06,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: baseFontSize * 0.05,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: baseFontSize * 0.045,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: baseFontSize * 0.035,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontSize: baseFontSize * 0.04,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: TextStyle(
          fontSize: baseFontSize * 0.03,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
