import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/features/quran/presentation/controllers/reading_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReadingSetupScreen extends StatelessWidget {
  const ReadingSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReadingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.secondaryPurple,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reading',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // ── Surah picker ─────────────────────────────────────────────
            Text(
              'Select Surah',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.darkPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _SurahDropdown(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Ayah picker ──────────────────────────────────────────────
            Text(
              'Starting Ayah',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.darkPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _AyahDropdown(ctrl: ctrl),
            const SizedBox(height: 40),

            // ── Start button ─────────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book_rounded, size: 22),
              label: const Text(
                'Start Reading',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => Get.toNamed(AppRoutes.readingActive),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahDropdown extends StatelessWidget {
  final ReadingController ctrl;
  const _SurahDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(
        () => DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: ctrl.selectedSurah.value,
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: AppColors.darkPurple,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            items: List.generate(ctrl.surahNames.length, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text('${i + 1}. ${ctrl.surahNames[i]}'),
              );
            }),
            onChanged: (v) {
              if (v == null) return;
              ctrl.selectedSurah.value = v;
              ctrl.selectedAyah.value = 0;
            },
          ),
        ),
      ),
    );
  }
}

class _AyahDropdown extends StatelessWidget {
  final ReadingController ctrl;
  const _AyahDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() {
        final max = ctrl.maxAyahForSurah;
        return DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: ctrl.selectedAyah.value.clamp(0, max),
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: AppColors.darkPurple,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Full Surah')),
              ...List.generate(
                max,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Ayah ${i + 1}'),
                ),
              ),
            ],
            onChanged: (v) {
              if (v != null) ctrl.selectedAyah.value = v;
            },
          ),
        );
      }),
    );
  }
}
