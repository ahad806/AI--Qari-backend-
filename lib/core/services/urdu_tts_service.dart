import 'package:al_qari/features/recitation/data/models/recitation_result_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Singleton TTS service for Urdu voice feedback on result screens.
///
/// Reads out a structured Urdu correction summary:
///  1. Score announcement
///  2. Missed-word count (if any)
///  3. Unique Tajweed error messages (deduplicated so the same rule is
///     only mentioned once, not once per word)
///  4. Encouragement / closing phrase
class UrduTtsService {
  UrduTtsService._();
  static final UrduTtsService instance = UrduTtsService._();

  FlutterTts? _tts;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> _ensureInitialized() async {
    if (_tts != null) return;
    _tts = FlutterTts();
    await _tts!.setLanguage('ur-PK');
    await _tts!.setSpeechRate(0.45); // slightly slow for clarity
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
  }

  /// Speak [text] in Urdu. Calls [onDone] when finished or stopped.
  Future<void> speak(String text, {void Function()? onDone}) async {
    await _ensureInitialized();
    await _tts!.stop();
    _isSpeaking = true;
    _tts!.setCompletionHandler(() {
      _isSpeaking = false;
      onDone?.call();
    });
    _tts!.setCancelHandler(() {
      _isSpeaking = false;
    });
    await _tts!.speak(text);
  }

  Future<void> stop() async {
    if (_tts == null) return;
    await _tts!.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _tts?.stop();
    _tts = null;
    _isSpeaking = false;
  }

  // ── Script builder ─────────────────────────────────────────────────────────

  /// Build a complete Urdu feedback script from [result].
  ///
  /// Set [playWordAudio] to `true` when Qari word audio will follow immediately
  /// after TTS — a transitional sentence is added to prime the listener.
  static String buildScript(
    RecitationResultModel result, {
    bool playWordAudio = false,
  }) {
    final buf = StringBuffer();
    final score = result.matchPercentage.round();

    // 1. Score
    if (score >= 80) {
      buf.write('ماشاء اللہ! آپ نے $score فیصد درست تلاوت کی۔ ');
    } else if (score >= 50) {
      buf.write('آپ نے $score فیصد درست تلاوت کی۔ ');
    } else {
      buf.write('آپ نے $score فیصد درست تلاوت کی۔ ');
    }

    final missed = result.wordFeedback
        .where((w) => w.status == 'missed')
        .toList();
    final errors = result.wordFeedback
        .where((w) => w.status == 'error')
        .toList();

    // 2. Missed words
    if (missed.isNotEmpty) {
      buf.write(
        '${missed.length} الفاظ آپ کی تلاوت میں سنائی نہیں دیے۔ '
        'واضح اور اونچی آواز میں تلاوت کریں۔ ',
      );
    }

    // 3. Unique Tajweed / pronunciation error messages (deduplicated)
    final uniqueMessages = <String>{};
    for (final w in errors) {
      final clean = _cleanText(w.feedbackUr);
      if (clean.isNotEmpty) uniqueMessages.add(clean);
    }
    if (uniqueMessages.isNotEmpty) {
      buf.write('${errors.length} الفاظ میں غلطیاں ہیں۔ ');
      for (final msg in uniqueMessages) {
        buf.write('$msg۔ ');
      }
    }

    // 4. Transition announcement (spoken before Qari audio plays)
    if (playWordAudio && (missed.isNotEmpty || errors.isNotEmpty)) {
      buf.write(
        'ابھی آپ قاری کی آواز میں ان الفاظ کا صحیح تلفظ سنیں گے۔ '
        'غور سے سنیں اور دہرانے کی کوشش کریں۔ ',
      );
    }

    // 5. Closing
    if (missed.isEmpty && errors.isEmpty) {
      buf.write('تمام الفاظ درست ادا ہوئے۔ بہت اچھا!');
    } else {
      buf.write('مزید مشق کریں۔ ان شاء اللہ بہتری آئے گی۔');
    }

    return buf.toString();
  }

  /// Strip emoji and stray punctuation so TTS reads cleanly.
  static String _cleanText(String text) {
    return text
        // Remove common emoji used as prefixes in feedback strings
        .replaceAll('⚠️', '')
        .replaceAll('❌', '')
        .replaceAll('✅', '')
        // Remove em-dash separators
        .replaceAll('—', '')
        .replaceAll('-', ' ')
        // Collapse multiple spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
