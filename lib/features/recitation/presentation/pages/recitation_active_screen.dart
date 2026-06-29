import 'dart:ui';

import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/features/recitation/presentation/controllers/recitation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_library/quran_library.dart';

class RecitationActiveScreen extends StatelessWidget {
  const RecitationActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<RecitationController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (ctrl.state.value == RecitationState.recording) {
          await ctrl.stopRecording();
        }
        await ctrl.reset();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: Obx(() {
            final busy =
                ctrl.state.value == RecitationState.recording ||
                ctrl.state.value == RecitationState.loading;
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.secondaryPurple,
              onPressed: busy
                  ? null
                  : () async {
                      await ctrl.reset();
                      if (context.mounted) Navigator.pop(context);
                    },
            );
          }),
          title: Obx(() {
            final surahName = ctrl.selectedSurah.value <= ctrl.surahNames.length
                ? ctrl.surahNames[ctrl.selectedSurah.value - 1]
                : '';
            final ayahLabel = ctrl.selectedAyah.value == 0
                ? 'Full Surah'
                : 'Ayah ${ctrl.selectedAyah.value}';
            return Text(
              '$surahName · $ayahLabel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.secondaryPurple,
                fontWeight: FontWeight.w700,
              ),
            );
          }),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Obx(() {
          // Auto-navigate when analysis is done
          if (ctrl.state.value == RecitationState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Get.currentRoute == AppRoutes.recitationActive) {
                Get.toNamed(AppRoutes.recitationResult);
              }
            });
          }

          final isBlurred =
              ctrl.state.value == RecitationState.recording ||
              ctrl.state.value == RecitationState.loading ||
              ctrl.state.value == RecitationState.done;

          return Stack(
            children: [
              // ── 1. Quran text (always visible behind) ──────────────────
              _QuranView(ctrl: ctrl),

              // ── 2. Blur overlay (only while recording / loading) ────────
              if (isBlurred)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.white.withValues(alpha: 0.15)),
                ),

              // ── 3. Bottom control sheet (always on top) ─────────────────
              _BottomOverlay(ctrl: ctrl),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Quran view ───────────────────────────────────────────────────────────────

class _QuranView extends StatelessWidget {
  final RecitationController ctrl;
  const _QuranView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ayahs = ctrl.currentAyahs;

      if (ayahs.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryPurple,
            strokeWidth: 3,
          ),
        );
      }

      final quranLib = QuranLibrary();
      final surahIdx = ctrl.selectedSurah.value - 1;
      final arabicName = surahIdx < ctrl.arabicSurahNames.length
          ? ctrl.arabicSurahNames[surahIdx]
          : '';

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 210),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Surah name ──────────────────────────────────────────────
            Text(
              arabicName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.darkPurple,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4),
            Divider(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
            const SizedBox(height: 16),

            // ── Ayahs ────────────────────────────────────────────────────
            for (final ayah in ayahs)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  // Append ayah number marker inline (skip for bismillah where ayahNumber == 0)
                  ayah.ayahNumber > 0
                      ? '${ayah.text} \u06dd${ayah.ayahNumber}\u06dd'
                      : ayah.text,
                  style: quranLib.hafsStyle.copyWith(fontSize: 22),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ─── Bottom overlay ───────────────────────────────────────────────────────────

class _BottomOverlay extends StatelessWidget {
  final RecitationController ctrl;
  const _BottomOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (ctrl.state.value) {
        // ── Idle: unblurred Quran + mic prompt ───────────────────────────
        case RecitationState.idle:
          return _bar(
            context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  final ayahNum = ctrl.selectedAyah.value;
                  final label = ayahNum == 0 ? 'Full Surah' : 'Ayah $ayahNum';
                  return Text(
                    'Recite $label, then tap stop',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkPurple.withValues(alpha: 0.55),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _MicButton(onTap: ctrl.startRecording, isRecording: false),
              ],
            ),
          );

        // ── Recording: blurred Quran + partial text + stop button ────────
        case RecitationState.recording:
          return _bar(
            context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  final ayahNum = ctrl.selectedAyah.value;
                  final label = ayahNum == 0 ? 'Full Surah' : 'Ayah $ayahNum';
                  return Text(
                    'Reciting $label — tap to stop',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryPurple.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Obx(() {
                  final text = ctrl.partialText.value;
                  if (text.isEmpty) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _PulsingDot(),
                        const SizedBox(width: 8),
                        Text(
                          'Listening…',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    );
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkPurple,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                _MicButton(onTap: ctrl.stopRecording, isRecording: true),
              ],
            ),
          );

        // ── Loading / done: spinner ──────────────────────────────────────
        case RecitationState.loading:
        case RecitationState.done:
          return _bar(
            context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 14),
                Text(
                  'Analyzing your recitation…',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.darkPurple),
                ),
              ],
            ),
          );

        // ── Error ────────────────────────────────────────────────────────
        case RecitationState.error:
          return _bar(
            context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                Text(
                  ctrl.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await ctrl.reset();
                    ctrl.startRecording();
                  },
                ),
              ],
            ),
          );
      }
    });
  }

  Widget _bar(BuildContext context, {required Widget child}) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Mic button ───────────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isRecording;
  const _MicButton({required this.onTap, required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? AppColors.error : AppColors.primaryPurple,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? AppColors.error : AppColors.primaryPurple)
                  .withValues(alpha: 0.4),
              blurRadius: isRecording ? 28 : 16,
              spreadRadius: isRecording ? 6 : 0,
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

// ─── Pulsing dot ──────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.error,
        ),
      ),
    );
  }
}
