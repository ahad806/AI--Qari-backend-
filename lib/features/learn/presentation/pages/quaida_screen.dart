import 'package:al_qari/config/themes/app_colors.dart';
import 'package:flutter/material.dart';

class QaidaScreen extends StatelessWidget {
  const QaidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Qaida',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon / Illustration
              Icon(
                Icons.menu_book_rounded,
                size: 100,
                color: AppColors.secondaryPurple.withValues(alpha: 0.8),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Qaida Coming Soon',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'We are preparing structured Qaida lessons to help you build a strong foundation in Quran recitation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 32),

              // Optional hint / CTA
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Stay tuned 🌙',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
