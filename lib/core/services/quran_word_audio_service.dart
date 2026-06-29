import 'dart:async';

import 'package:al_qari/features/recitation/data/models/recitation_result_model.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays word-by-word Quran audio (Mishary Alafasy) for every error or missed
/// word in a recitation result.
///
/// Audio CDN: https://audio.qurancdn.com/wbw/{surah:03}_{ayah:03}_{word:03}.mp3
/// Word numbers in the URL are 1-indexed; [WordFeedback.position] is 0-indexed.
class QuranWordAudioService {
  QuranWordAudioService._();
  static final QuranWordAudioService instance = QuranWordAudioService._();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _shouldStop = false;

  bool get isPlaying => _isPlaying;

  /// Play audio for each word in [words] whose status is 'error' or 'missed'.
  ///
  /// Uses per-word [WordFeedback.ayahNum] and [WordFeedback.wordInAyah] fields
  /// (populated by the backend for both single-ayah and full-surah modes).
  /// Words with unknown ayah data (ayahNum == 0) are skipped gracefully.
  /// [onDone] is called once all words have played or [stop] was called.
  Future<void> playWords({
    required List<WordFeedback> words,
    required int surahNumber,
    void Function()? onDone,
  }) async {
    _shouldStop = false;
    _isPlaying = true;
    _player ??= AudioPlayer();

    final targets = words
        .where(
          (w) =>
              (w.status == 'error' || w.status == 'missed') &&
              w.ayahNum > 0 &&
              w.wordInAyah > 0,
        )
        .toList();

    debugPrint(
      '[QuranWordAudio] playing ${targets.length} word(s) for surah $surahNumber',
    );
    for (final word in targets) {
      if (_shouldStop) break;
      final url = _wordUrl(surahNumber, word.ayahNum, word.wordInAyah);
      debugPrint('[QuranWordAudio] playing: ${word.word} → $url');
      await _playOne(url);
      if (!_shouldStop) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _isPlaying = false;
    if (!_shouldStop) onDone?.call();
  }

  Future<void> _playOne(String url) async {
    StreamSubscription? sub;
    try {
      // setUrl() transitions the player to ready state (not completed).
      // We must subscribe AFTER setUrl() so that the BehaviorSubject-style
      // playerStateStream does not immediately replay the previous
      // ProcessingState.completed event from the last word, which would
      // resolve the Completer before this word even starts playing.
      await _player!.setUrl(url);

      final completer = Completer<void>();
      sub = _player!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      await _player!.play();
      await completer.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[QuranWordAudio] _playOne error for $url: $e');
    } finally {
      await sub?.cancel();
    }
  }

  Future<void> stop() async {
    _shouldStop = true;
    _isPlaying = false;
    await _player?.stop();
  }

  void dispose() {
    _shouldStop = true;
    _isPlaying = false;
    _player?.dispose();
    _player = null;
  }

  static String _wordUrl(int surah, int ayah, int wordNum) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    final w = wordNum.toString().padLeft(3, '0');
    return 'https://audio.qurancdn.com/wbw/${s}_${a}_$w.mp3';
  }
}
