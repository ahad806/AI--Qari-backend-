import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:quran_library/quran_library.dart';

import 'package:al_qari/features/recitation/data/models/recitation_result_model.dart';
import 'package:al_qari/features/quran/data/repositories/quran_repository.dart'
    as localRepo;
import 'package:al_qari/core/services/progress_service.dart';
import 'package:al_qari/features/progress/progress_controller.dart';

// ─── Backend URL (same as RecitationController) ───────────────────────────────
const String _kReadingWsUrl = 'ws://13.63.216.254:8000/ws/recite';

enum ReadingState { idle, recording, loading, done, error }

class ReadingController extends GetxController {
  // ── Observable state ────────────────────────────────────────────────────────
  final Rx<ReadingState> state = ReadingState.idle.obs;
  final RxString partialText = ''.obs;
  final RxString errorMessage = ''.obs;
  final Rx<RecitationResultModel?> result = Rx(null);

  // ── Surah / Ayah selection ────────────────────────────────────────────────
  final RxInt selectedSurah = 1.obs;
  final RxInt selectedAyah = 0.obs; // 0 = Full Surah

  List<String> surahNames = [];
  List<String> arabicSurahNames = [];

  final RxList<AyahModel> currentAyahs = <AyahModel>[].obs;

  // ── Internals ─────────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  StreamSubscription? _audioSub;
  DateTime? _sessionStart;

  @override
  void onInit() {
    super.onInit();
    surahNames = QuranLibrary.getAllSurahs(isArabic: false);
    arabicSurahNames = QuranLibrary.getAllSurahs(isArabic: true);
    loadAyahsForSelection();
    ever(selectedSurah, (_) => loadAyahsForSelection());
    ever(selectedAyah, (_) => loadAyahsForSelection());
  }

  @override
  Future<void> onClose() async {
    await _cleanup();
    await _recorder.dispose();
    super.onClose();
  }

  // ── Ayah loading ────────────────────────────────────────────────────────────
  void loadAyahsForSelection() {
    final surahId = selectedSurah.value;
    final ayahNum = selectedAyah.value;

    final qCtrl = QuranLibrary.quranCtrl;

    final List<AyahModel> all;
    if (qCtrl.state.surahs.length >= surahId) {
      all = List<AyahModel>.from(qCtrl.state.surahs[surahId - 1].ayahs);
    } else {
      final startIdx = qCtrl.surahsStart[surahId - 1];
      final endIdx = surahId == 114 ? 603 : qCtrl.surahsStart[surahId];
      final quranLib = QuranLibrary();
      final fallback = <AyahModel>[];
      for (int idx = startIdx; idx <= endIdx; idx++) {
        final pageAyahs = quranLib.getPageAyahsByPageNumber(
          pageNumber: idx + 1,
        );
        for (final ayah in pageAyahs) {
          if (ayah.surahNumber == surahId) fallback.add(ayah);
        }
      }
      all = fallback;
    }

    if (ayahNum == 0 && surahId != 1 && surahId != 9 && all.isNotEmpty) {
      if (!all.first.text.trim().startsWith('بِسْمِ اللَّهِ')) {
        all.insert(
          0,
          AyahModel.fromAya(
            ayah: all.first,
            aya: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            ayaText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            centered: true,
          ),
        );
      }
    }

    if (ayahNum == 0) {
      currentAyahs.assignAll(all);
    } else {
      currentAyahs.assignAll(
        all.where((a) => a.ayahNumber == ayahNum).toList(),
      );
    }
  }

  // ── Max ayahs ─────────────────────────────────────────────────────────────
  int get maxAyahForSurah => maxAyahForSurahNumber(selectedSurah.value);

  int maxAyahForSurahNumber(int surahNumber) {
    try {
      return localRepo.QuranRepository().getSurahs()[surahNumber - 1].verses ??
          7;
    } catch (_) {
      return 7;
    }
  }

  // ── Recording ─────────────────────────────────────────────────────────────
  Future<void> startRecording() async {
    errorMessage.value = '';
    result.value = null;
    partialText.value = '';
    _sessionStart = DateTime.now();

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      errorMessage.value = 'Microphone permission denied.';
      state.value = ReadingState.error;
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_kReadingWsUrl));
    } catch (e) {
      errorMessage.value = 'Cannot connect to backend. Is the server running?';
      state.value = ReadingState.error;
      return;
    }

    _wsSub = _channel!.stream.listen(
      _onWsMessage,
      onError: (e) {
        errorMessage.value = 'Connection error: $e';
        state.value = ReadingState.error;
      },
      onDone: () {
        if (state.value == ReadingState.recording ||
            state.value == ReadingState.loading) {
          _audioSub?.cancel();
          _audioSub = null;
          _recorder.cancel();
          errorMessage.value =
              'Connection dropped. Please check your network and try again.';
          state.value = ReadingState.error;
        }
      },
    );

    _channel!.sink.add(
      jsonEncode({
        'type': 'start',
        'surah': selectedSurah.value,
        'ayah': selectedAyah.value,
      }),
    );

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    state.value = ReadingState.recording;

    _audioSub = stream.listen((Uint8List chunk) {
      if (state.value == ReadingState.recording && _channel != null) {
        _channel!.sink.add(chunk);
      }
    });
  }

  Future<void> stopRecording() async {
    if (state.value != ReadingState.recording) return;

    // Stop the recorder BEFORE changing state.  The stream listener guard
    // checks `state == recording`, so changing state first would cause the
    // final 0.5–1 s of audio chunks to be dropped and never sent to the
    // backend — resulting in a truncated (and less accurate) transcription.
    await _recorder.stop();

    // Allow any last chunks already in Dart's event queue to be delivered
    // (the stream is closed but events queued before close still fire).
    await Future<void>.delayed(Duration.zero);

    state.value = ReadingState.loading;

    await _audioSub?.cancel();
    _audioSub = null;

    _channel?.sink.add(jsonEncode({'type': 'done'}));
  }

  Future<void> reset() async {
    await _cleanup();
    partialText.value = '';
    errorMessage.value = '';
    result.value = null;
    state.value = ReadingState.idle;
  }

  // ── WS message handler ────────────────────────────────────────────────────
  void _onWsMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'ready':
          break;
        case 'partial':
          partialText.value = json['transcription'] as String? ?? '';
          break;
        case 'result':
          final r = RecitationResultModel.fromWsJson(json);

          // Empty transcription = no speech detected — don't show results
          // or save an empty session to Firestore.
          if (r.transcription.trim().isEmpty) {
            _sessionStart = null;
            errorMessage.value =
                'No speech detected. Please try again and recite clearly.';
            state.value = ReadingState.error;
            _cleanup(closeChannel: false);
            break;
          }

          result.value = r;

          // ── Save session to Firestore ─────────────────────────────
          unawaited(
            ProgressService.saveSession(
                  SessionEntry(
                    type: 'reading',
                    surahNumber: r.surahNumber,
                    ayahNumber: r.ayahNumber,
                    accuracy: r.matchPercentage,
                    durationSeconds: _sessionStart == null
                        ? 0
                        : DateTime.now().difference(_sessionStart!).inSeconds,
                    createdAt: DateTime.now(),
                  ),
                )
                .then((_) {
                  if (Get.isRegistered<ProgressController>()) {
                    Get.find<ProgressController>().loadProgress();
                  }
                })
                .catchError((e, st) {
                  dev.log(
                    'saveSession failed: $e',
                    name: 'ReadingController',
                    error: e,
                    stackTrace: st as StackTrace?,
                  );
                }),
          );
          _sessionStart = null;
          // ─────────────────────────────────────────────────────────

          dev.log(
            '═══════════════ READING RESULT ═══════════════',
            name: 'ReadingController',
          );
          dev.log(
            'Overall Accuracy : ${r.matchPercentage.toStringAsFixed(1)}%',
            name: 'ReadingController',
          );
          dev.log(
            'Reference Text   : ${r.referenceText}',
            name: 'ReadingController',
          );
          dev.log(
            'Your Transcription: ${r.transcription.isEmpty ? "(nothing detected)" : r.transcription}',
            name: 'ReadingController',
          );
          dev.log(
            'Word Feedback (${r.wordFeedback.length} words):',
            name: 'ReadingController',
          );
          for (final w in r.wordFeedback) {
            dev.log(
              '  [${w.position.toString().padLeft(2)}] ${w.status.toUpperCase().padRight(8)} '
              '"${w.word}"  → ${w.feedbackEn}',
              name: 'ReadingController',
            );
          }
          dev.log(
            '══════════════════════════════════════════════',
            name: 'ReadingController',
          );

          state.value = ReadingState.done;
          _cleanup(closeChannel: false);
          break;
        case 'error':
          errorMessage.value = json['message'] as String? ?? 'Unknown error';
          state.value = ReadingState.error;
          _cleanup(closeChannel: false);
          break;
      }
    } catch (_) {}
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  Future<void> _cleanup({bool closeChannel = true}) async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _wsSub?.cancel();
    _wsSub = null;
    if (closeChannel) {
      _channel?.sink.close();
      _channel = null;
    }
    try {
      await _recorder.cancel();
    } catch (_) {}
  }
}
