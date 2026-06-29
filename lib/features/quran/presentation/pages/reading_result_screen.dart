import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/services/quran_word_audio_service.dart';
import 'package:al_qari/core/services/urdu_tts_service.dart';
import 'package:al_qari/features/recitation/data/models/recitation_result_model.dart';
import 'package:al_qari/features/quran/presentation/controllers/reading_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReadingResultScreen extends StatelessWidget {
  const ReadingResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReadingController>();
    final result = ctrl.result.value;

    if (result == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () =>
                Get.until((r) => r.settings.name == AppRoutes.readingSetup),
            child: const Text('Go Back'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.secondaryPurple,
          onPressed: () =>
              Get.until((r) => r.settings.name == AppRoutes.readingSetup),
        ),
        title: Text(
          'Your Result',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Score gauge ─────────────────────────────────────────────
            _ScoreCard(percentage: result.matchPercentage),
            const SizedBox(height: 16),

            // ── Urdu voice feedback ──────────────────────────────────────
            _VoiceFeedbackCard(result: result),
            const SizedBox(height: 20),

            // ── Word-by-word feedback ────────────────────────────────────
            if (result.wordFeedback.isNotEmpty) ...[
              _SectionTitle('Word Feedback'),
              const SizedBox(height: 6),
              const _WordFeedbackLegend(),
              const SizedBox(height: 10),
              _WordFeedbackGrid(words: result.wordFeedback),
              const SizedBox(height: 20),
            ],

            // ── Transcription ────────────────────────────────────────────
            _SectionTitle('Your Transcription'),
            const SizedBox(height: 8),
            _TextCard(
              text: result.transcription.isNotEmpty
                  ? result.transcription
                  : '(nothing detected)',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              fontSize: 18,
              fontFamily: 'Amiri',
            ),
            const SizedBox(height: 12),

            // ── Reference text ───────────────────────────────────────────
            _SectionTitle('Reference'),
            const SizedBox(height: 8),
            _TextCard(
              text: result.referenceText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              fontSize: 20,
              fontFamily: 'Amiri',
            ),
            const SizedBox(height: 32),

            // ── Actions ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryPurple,
                      side: const BorderSide(color: AppColors.primaryPurple),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await ctrl.reset();
                      Get.back();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(
                      result.ayahNumber == 0 ? 'Next Surah' : 'Next Ayah',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _nextAyah(ctrl),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _nextAyah(ReadingController ctrl) async {
    final r = ctrl.result.value!;
    final evaluatedSurah = r.surahNumber;
    final evaluatedAyah = r.ayahNumber;

    if (evaluatedAyah == 0) {
      final nextSurah = evaluatedSurah < 114 ? evaluatedSurah + 1 : 114;
      ctrl.selectedSurah.value = nextSurah;
      ctrl.selectedAyah.value = 0;
    } else {
      final maxAyah = ctrl.maxAyahForSurahNumber(evaluatedSurah);
      if (evaluatedAyah < maxAyah) {
        ctrl.selectedSurah.value = evaluatedSurah;
        ctrl.selectedAyah.value = evaluatedAyah + 1;
      } else {
        final nextSurah = evaluatedSurah < 114 ? evaluatedSurah + 1 : 114;
        ctrl.selectedSurah.value = nextSurah;
        ctrl.selectedAyah.value = 1;
      }
    }

    await ctrl.reset();
    Get.back();
  }
}

// ─── Score card ───────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final double percentage;
  const _ScoreCard({required this.percentage});

  Color get _color {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String get _label {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 50) return 'Keep Practicing';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: _color,
                    ),
                  ),
                  Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Word feedback legend ─────────────────────────────────────────────────────

class _WordFeedbackLegend extends StatelessWidget {
  const _WordFeedbackLegend();

  static const _items = [
    (color: Color(0xFF22c55e), label: 'Correct'),
    (color: Color(0xFFef4444), label: 'Error'),
    (color: Color(0xFF8b5cf6), label: 'Missed'),
    (color: Color(0xFF94a3b8), label: 'No rule'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: _items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: const TextStyle(fontSize: 11, color: AppColors.darkPurple),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Word feedback grid ───────────────────────────────────────────────────────

class _WordFeedbackGrid extends StatelessWidget {
  final List<WordFeedback> words;
  const _WordFeedbackGrid({required this.words});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: words.map((w) => _WordChip(word: w)).toList(),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final WordFeedback word;
  const _WordChip({required this.word});

  Color get _background {
    try {
      final hex = word.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMissed = word.status == 'missed';
    return GestureDetector(
      onTap: word.feedbackEn.isNotEmpty ? () => _showFeedback(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _background.withValues(alpha: isMissed ? 0.12 : 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _background, width: 1.4),
        ),
        child: Text(
          word.word,
          style: TextStyle(
            color: _background.withValues(alpha: isMissed ? 0.6 : 1.0),
            fontWeight: FontWeight.w700,
            fontSize: 17,
            fontFamily: 'Amiri',
            decoration: isMissed ? TextDecoration.lineThrough : null,
            decorationColor: _background,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          word.word,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(word.feedbackEn, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.darkPurple,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double fontSize;
  final String? fontFamily;

  const _TextCard({
    required this.text,
    required this.textAlign,
    required this.textDirection,
    required this.fontSize,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: textAlign,
        textDirection: textDirection,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          color: AppColors.darkPurple,
          height: 1.8,
        ),
      ),
    );
  }
}

// ─── Urdu voice feedback card ─────────────────────────────────────────────────

class _VoiceFeedbackCard extends StatefulWidget {
  final RecitationResultModel result;
  const _VoiceFeedbackCard({required this.result});

  @override
  State<_VoiceFeedbackCard> createState() => _VoiceFeedbackCardState();
}

enum _PlayState { idle, tts, qari }

class _VoiceFeedbackCardState extends State<_VoiceFeedbackCard> {
  _PlayState _state = _PlayState.idle;
  final _tts = UrduTtsService.instance;
  final _qari = QuranWordAudioService.instance;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), _play);
  }

  @override
  void dispose() {
    _tts.stop();
    _qari.stop();
    super.dispose();
  }

  bool get _hasWordAudio => widget.result.wordFeedback.any(
    (w) =>
        (w.status == 'error' || w.status == 'missed') &&
        w.ayahNum > 0 &&
        w.wordInAyah > 0,
  );

  Future<void> _play() async {
    if (!mounted) return;
    setState(() => _state = _PlayState.tts);
    final script = UrduTtsService.buildScript(
      widget.result,
      playWordAudio: _hasWordAudio,
    );
    await _tts.speak(script, onDone: _onTtsDone);
  }

  void _onTtsDone() {
    if (!mounted) return;
    final has = _hasWordAudio;
    debugPrint('[VoiceFeedback] _onTtsDone called — _hasWordAudio=$has');
    if (has) {
      setState(() => _state = _PlayState.qari);
      _qari.playWords(
        words: widget.result.wordFeedback,
        surahNumber: widget.result.surahNumber,
        onDone: () {
          if (mounted) setState(() => _state = _PlayState.idle);
        },
      );
    } else {
      for (final w in widget.result.wordFeedback) {
        if (w.status == 'error' || w.status == 'missed') {
          debugPrint(
            '[VoiceFeedback] ${w.word} status=${w.status} ayahNum=${w.ayahNum} wordInAyah=${w.wordInAyah}',
          );
        }
      }
      setState(() => _state = _PlayState.idle);
    }
  }

  Future<void> _stop() async {
    await Future.wait([_tts.stop(), _qari.stop()]);
    if (mounted) setState(() => _state = _PlayState.idle);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _state != _PlayState.idle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _state == _PlayState.qari
                  ? Icons.headphones_rounded
                  : _state == _PlayState.tts
                  ? Icons.graphic_eq_rounded
                  : Icons.record_voice_over_rounded,
              color: AppColors.primaryPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آواز سے اصلاح',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.darkPurple,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 2),
                Text(
                  _state == _PlayState.qari
                      ? 'قاری کی آواز میں صحیح الفاظ سن رہے ہیں...'
                      : _state == _PlayState.tts
                      ? 'اردو میں رائے سن رہے ہیں...'
                      : 'اردو میں تلاوت کی رائے سنیں',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryPurple,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isActive ? _stop : _play,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.error.withValues(alpha: 0.12)
                    : AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: isActive
                  ? const Icon(
                      Icons.stop_rounded,
                      color: AppColors.error,
                      size: 22,
                    )
                  : const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
