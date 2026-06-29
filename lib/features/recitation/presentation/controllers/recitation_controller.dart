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

// ─── Backend URL ──────────────────────────────────────────────────────────────
// Change to your deployed URL when needed.
// const String _kWsUrl = 'ws://10.0.2.2:8000/ws/recite'; // Android emulator
// const String _kWsUrl = 'ws://localhost:8000/ws/recite'; // iOS simulator
const String _kWsUrl = 'ws://13.63.216.254:8000/ws/recite';

enum RecitationState { idle, recording, loading, done, error }

class RecitationController extends GetxController {
  // ── Observable state ────────────────────────────────────────────────────────
  final Rx<RecitationState> state = RecitationState.idle.obs;
  final RxString partialText = ''.obs;
  final RxString errorMessage = ''.obs;
  final Rx<RecitationResultModel?> result = Rx(null);

  // ── Surah / Ayah selection ────────────────────────────────────────────────
  final RxInt selectedSurah = 1.obs;
  final RxInt selectedAyah = 0.obs; // 0 = Full Surah

  // Surah names loaded from quran_library
  List<String> surahNames = [];
  List<String> arabicSurahNames = [];

  // Ayahs for the current selection (shown in the Quran view)
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

    // Use state.surahs (populated by loadQuranDataV3) to get exactly the ayahs
    // belonging to this surah.  The page-based approach is unreliable because
    // downloaded-font AyahModels always have surahNumber == null, so the old
    // null-fallback filter matched every ayah on the shared page (e.g. surahs
    // 112-114 all live on page 604) and leaked Al-Falaq / An-Nas into the
    // Al-Ikhlas view.
    final List<AyahModel> all;
    if (qCtrl.state.surahs.length >= surahId) {
      all = List<AyahModel>.from(qCtrl.state.surahs[surahId - 1].ayahs);
    } else {
      // Fallback: page-based scan for original-fonts-only builds where
      // state.surahs is not populated.  surahNumber is reliable here (v1 JSON).
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

    // Prepend Bismillah for full-surah view (not surah 1 which already has it, not surah 9)
    if (ayahNum == 0 && surahId != 1 && surahId != 9 && all.isNotEmpty) {
      if (!all.first.text.trim().startsWith('بِسْمِ اللَّهِ')) {
        all.insert(
          0,
          AyahModel.fromAya(
            ayah: all.first,
            aya: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            ayaText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
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

  // ── Max ayahs for selected surah ──────────────────────────────────────────
  int get maxAyahForSurah => maxAyahForSurahNumber(selectedSurah.value);

  int maxAyahForSurahNumber(int surahNumber) {
    try {
      final surahs = localRepo.QuranRepository().getSurahs();
      return surahs[surahNumber - 1].verses ?? 7;
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

    // Full Surah mode: keep selectedAyah as 0 — the Quran view shows all ayahs
    // and the backend evaluates against the full surah text.
    // No conversion needed here.

    // 1. Mic permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      errorMessage.value = 'Microphone permission denied.';
      state.value = RecitationState.error;
      return;
    }

    // 2. Open WebSocket
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_kWsUrl));
    } catch (e) {
      errorMessage.value = 'Cannot connect to backend. Is the server running?';
      state.value = RecitationState.error;
      return;
    }

    // 3. Listen for server messages
    _wsSub = _channel!.stream.listen(
      _onWsMessage,
      onError: (e) {
        errorMessage.value = 'Connection error: $e';
        state.value = RecitationState.error;
      },
      onDone: () {
        // Connection dropped — handle in any non-terminal state
        if (state.value == RecitationState.recording ||
            state.value == RecitationState.loading) {
          _audioSub?.cancel();
          _audioSub = null;
          _recorder.cancel();
          errorMessage.value =
              'Connection dropped. Please check your network and try again.';
          state.value = RecitationState.error;
        }
      },
    );

    // 4. Send start message
    _channel!.sink.add(
      jsonEncode({
        'type': 'start',
        'surah': selectedSurah.value,
        'ayah': selectedAyah.value, // 0 = full surah, N = specific ayah
      }),
    );

    // 5. Start streaming PCM audio in chunks
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    state.value = RecitationState.recording;

    _audioSub = stream.listen((Uint8List chunk) {
      if (state.value == RecitationState.recording && _channel != null) {
        _channel!.sink.add(chunk);
      }
    });
  }

  Future<void> stopRecording() async {
    if (state.value != RecitationState.recording) return;
    state.value = RecitationState.loading;

    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();

    // Tell backend we're done
    _channel?.sink.add(jsonEncode({'type': 'done'}));
  }

  Future<void> reset() async {
    await _cleanup();
    partialText.value = '';
    errorMessage.value = '';
    result.value = null;
    state.value = RecitationState.idle;
  }

  // ── WS message handler ────────────────────────────────────────────────────
  void _onWsMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'ready':
          // Server acknowledged start — recording is live
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
            state.value = RecitationState.error;
            _cleanup(closeChannel: false);
            break;
          }

          result.value = r;

          // ── Save session to Firestore ─────────────────────────────
          unawaited(
            ProgressService.saveSession(
                  SessionEntry(
                    type: 'recitation',
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
                    name: 'RecitationController',
                    error: e,
                    stackTrace: st as StackTrace?,
                  );
                }),
          );
          _sessionStart = null;
          // ─────────────────────────────────────────────────────────

          dev.log(
            '═══════════════ RECITATION RESULT ═══════════════',
            name: 'RecitationController',
          );
          dev.log(
            'Overall Accuracy : ${r.matchPercentage.toStringAsFixed(1)}%',
            name: 'RecitationController',
          );
          dev.log(
            'Reference Text   : ${r.referenceText}',
            name: 'RecitationController',
          );
          dev.log(
            'Your Transcription: ${r.transcription.isEmpty ? "(nothing detected)" : r.transcription}',
            name: 'RecitationController',
          );
          dev.log(
            'Word Feedback (${r.wordFeedback.length} words):',
            name: 'RecitationController',
          );
          for (final w in r.wordFeedback) {
            dev.log(
              '  [${w.position.toString().padLeft(2)}] ${w.status.toUpperCase().padRight(8)} '
              '"${w.word}"  → ${w.feedbackEn}',
              name: 'RecitationController',
            );
          }
          dev.log(
            '═════════════════════════════════════════════════',
            name: 'RecitationController',
          );
          // ─────────────────────────────────────────────────────────────

          state.value = RecitationState.done;
          _cleanup(closeChannel: false);
          break;
        case 'error':
          errorMessage.value = json['message'] as String? ?? 'Unknown error';
          state.value = RecitationState.error;
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
    // Await cancel so the native mic is released before returning.
    try {
      await _recorder.cancel();
    } catch (_) {}
  }
}
