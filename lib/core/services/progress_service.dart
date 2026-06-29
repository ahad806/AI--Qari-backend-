import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Session model ────────────────────────────────────────────────────────────

class SessionEntry {
  final String type; // 'reading' | 'recitation'
  final int surahNumber;
  final int ayahNumber; // 0 = full surah
  final double accuracy;
  final int durationSeconds;
  final DateTime createdAt;

  const SessionEntry({
    required this.type,
    required this.surahNumber,
    required this.ayahNumber,
    required this.accuracy,
    required this.durationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'accuracy': accuracy,
    'durationSeconds': durationSeconds,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory SessionEntry.fromDoc(Map<String, dynamic> data) => SessionEntry(
    type: data['type'] as String? ?? 'recitation',
    surahNumber: data['surahNumber'] as int? ?? 1,
    ayahNumber: data['ayahNumber'] as int? ?? 0,
    accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
    durationSeconds: data['durationSeconds'] as int? ?? 0,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class ProgressService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>>? get _statsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('progress').doc('stats');
  }

  static CollectionReference<Map<String, dynamic>>? get _sessionsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('progressSessions');
  }

  /// Persist a completed session and update rolling stats.
  static Future<void> saveSession(SessionEntry entry) async {
    final uid = _uid;
    if (uid == null) {
      dev.log(
        'saveSession: no authenticated user — skipping',
        name: 'ProgressService',
      );
      return;
    }
    dev.log(
      'saveSession: type=${entry.type} surah=${entry.surahNumber} accuracy=${entry.accuracy}',
      name: 'ProgressService',
    );

    final sessionsCol = _db
        .collection('users')
        .doc(uid)
        .collection('progressSessions');
    final statsDoc = _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('stats');

    // 1. Write the session document first (outside the transaction).
    await sessionsCol.add(entry.toMap());

    // 2. Update aggregated stats inside a transaction so reads and writes
    //    are consistent even if two sessions complete simultaneously.
    await _db.runTransaction((tx) async {
      final statsSnap = await tx.get(statsDoc);
      final data = Map<String, dynamic>.from(statsSnap.data() ?? {});

      // ── Running accuracy average ────────────────────────────────────
      if (entry.type == 'recitation') {
        final n = (data['totalRecitationSessions'] as int? ?? 0);
        final oldAvg =
            (data['avgRecitationAccuracy'] as num?)?.toDouble() ?? 0.0;
        data['avgRecitationAccuracy'] = n == 0
            ? entry.accuracy
            : (oldAvg * n + entry.accuracy) / (n + 1);
        data['totalRecitationSessions'] = n + 1;
      } else {
        final n = (data['totalReadingSessions'] as int? ?? 0);
        final oldAvg = (data['avgReadingAccuracy'] as num?)?.toDouble() ?? 0.0;
        data['avgReadingAccuracy'] = n == 0
            ? entry.accuracy
            : (oldAvg * n + entry.accuracy) / (n + 1);
        data['totalReadingSessions'] = n + 1;
      }

      // ── Daily streak ────────────────────────────────────────────────
      final today = _dateString(DateTime.now());
      final yesterday = _dateString(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final lastActive = data['lastActiveDate'] as String? ?? '';

      int currentStreak = data['currentStreak'] as int? ?? 0;
      int longestStreak = data['longestStreak'] as int? ?? 0;

      if (lastActive == today) {
        // Same day — streak already counted.
      } else if (lastActive == yesterday) {
        currentStreak++;
      } else {
        currentStreak = 1; // Streak broken — restart.
      }
      if (currentStreak > longestStreak) longestStreak = currentStreak;

      data['currentStreak'] = currentStreak;
      data['longestStreak'] = longestStreak;
      data['lastActiveDate'] = today;

      // ── Total time ──────────────────────────────────────────────────
      data['totalTimeSeconds'] =
          (data['totalTimeSeconds'] as int? ?? 0) + entry.durationSeconds;

      // ── Unique surahs recited ───────────────────────────────────────
      if (entry.type == 'recitation') {
        final raw = data['recitedSurahNumbers'] as List<dynamic>? ?? [];
        final surahs = raw.map((e) => e as int).toSet();
        surahs.add(entry.surahNumber);
        data['recitedSurahNumbers'] = surahs.toList();
      }

      tx.set(statsDoc, data);
    });
    dev.log('saveSession: done', name: 'ProgressService');
  }

  /// Fetch the aggregated stats document.
  static Future<Map<String, dynamic>> fetchStats() async {
    final ref = _statsRef;
    if (ref == null) return {};
    final doc = await ref.get();
    return doc.data() ?? {};
  }

  /// Fetch the last [limit] recitation sessions ordered oldest → newest.
  /// Uses a simple single-field orderBy to avoid requiring a composite index.
  static Future<List<SessionEntry>> fetchRecentRecitationSessions({
    int limit = 20,
  }) async {
    final ref = _sessionsRef;
    if (ref == null) return [];
    // Fetch the most-recent [limit] docs (any type), filter in Dart.
    // This only requires the auto-created single-field index on createdAt.
    final snap = await ref
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => SessionEntry.fromDoc(d.data()))
        .where((e) => e.type == 'recitation')
        .toList()
        .reversed
        .toList();
  }

  static String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
