import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:al_qari/core/services/progress_service.dart';

class ProgressController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  // True after the first successful Firestore load. Prevents the full-screen
  // spinner from reappearing if the controller is ever recreated mid-session.
  final RxBool hasData = false.obs;

  // ── Stats ─────────────────────────────────────────────────────────────────
  final RxDouble avgReadingAccuracy = 0.0.obs;
  final RxDouble avgRecitationAccuracy = 0.0.obs;
  final RxInt totalSurahsRecited = 0.obs;
  final RxInt currentStreak = 0.obs;
  final RxInt longestStreak = 0.obs;
  final RxInt totalTimeSeconds = 0.obs;

  // ── Graph data: last N recitation sessions ────────────────────────────────
  final RxList<SessionEntry> recitationHistory = <SessionEntry>[].obs;

  StreamSubscription<User?>? _authSub;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state so we reload as soon as Firebase restores the
    // session. This handles the startup race where currentUser is null
    // when onInit() fires but becomes non-null shortly after.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        dev.log(
          'Auth resolved: ${user.uid} — loading progress',
          name: 'ProgressController',
        );
        loadProgress();
      } else {
        // Signed out — clear stats.
        _clearStats();
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  void _clearStats() {
    avgReadingAccuracy.value = 0.0;
    avgRecitationAccuracy.value = 0.0;
    totalSurahsRecited.value = 0;
    currentStreak.value = 0;
    longestStreak.value = 0;
    totalTimeSeconds.value = 0;
    recitationHistory.clear();
    isLoading.value = false;
  }

  Future<void> loadProgress() async {
    if (FirebaseAuth.instance.currentUser == null) {
      dev.log('loadProgress: no user — skipping', name: 'ProgressController');
      isLoading.value = false;
      return;
    }
    // Only show the full-screen spinner on first load (no data yet).
    // On subsequent calls (e.g. after saving a session) use isRefreshing
    // so the existing data stays visible while the update happens.
    final firstLoad = isLoading.value;
    if (!firstLoad) isRefreshing.value = true;
    try {
      final results = await Future.wait([
        ProgressService.fetchStats(),
        ProgressService.fetchRecentRecitationSessions(limit: 20),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final history = results[1] as List<SessionEntry>;

      avgReadingAccuracy.value =
          (stats['avgReadingAccuracy'] as num?)?.toDouble() ?? 0.0;
      avgRecitationAccuracy.value =
          (stats['avgRecitationAccuracy'] as num?)?.toDouble() ?? 0.0;
      totalSurahsRecited.value =
          (stats['recitedSurahNumbers'] as List<dynamic>? ?? []).length;
      currentStreak.value = stats['currentStreak'] as int? ?? 0;
      longestStreak.value = stats['longestStreak'] as int? ?? 0;
      totalTimeSeconds.value = stats['totalTimeSeconds'] as int? ?? 0;
      recitationHistory.assignAll(history);
      hasData.value = true;
    } catch (e, st) {
      dev.log(
        'loadProgress error: $e',
        name: 'ProgressController',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ── Derived helpers ───────────────────────────────────────────────────────

  /// Combined reading + recitation accuracy (simple average of both).
  double get overallAccuracy {
    final r = avgReadingAccuracy.value;
    final rc = avgRecitationAccuracy.value;
    if (r == 0 && rc == 0) return 0;
    if (r == 0) return rc;
    if (rc == 0) return r;
    return (r + rc) / 2;
  }

  /// Human-readable total time, e.g. "2h 40m" or "35m".
  String get formattedTime {
    final secs = totalTimeSeconds.value;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${secs}s';
  }
}
