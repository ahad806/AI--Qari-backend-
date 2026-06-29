class WordFeedback {
  final int position;
  final String word;
  final String status; // 'correct' | 'error' | 'missed' | 'no_rule'
  final String color; // hex string e.g. '#4CAF50'
  final String feedbackEn;
  final String feedbackUr;
  final int ayahNum; // which ayah this word belongs to (1-indexed, 0 = unknown)
  final int
  wordInAyah; // word position within that ayah (1-indexed, 0 = unknown)

  const WordFeedback({
    required this.position,
    required this.word,
    required this.status,
    required this.color,
    required this.feedbackEn,
    required this.feedbackUr,
    required this.ayahNum,
    required this.wordInAyah,
  });

  factory WordFeedback.fromJson(Map<String, dynamic> json) => WordFeedback(
    position: json['position'] as int,
    word: json['word'] as String,
    status: json['status'] as String? ?? 'no_rule',
    color: json['color'] as String? ?? '#9E9E9E',
    feedbackEn: json['feedback_en'] as String? ?? '',
    feedbackUr: json['feedback_ur'] as String? ?? '',
    ayahNum: json['ayah_num'] as int? ?? 0,
    wordInAyah: json['word_in_ayah'] as int? ?? 0,
  );
}

class RecitationResultModel {
  final String transcription;
  final double matchPercentage;
  final String referenceText;
  final List<WordFeedback> wordFeedback;
  final int surahNumber;
  final int ayahNumber;

  const RecitationResultModel({
    required this.transcription,
    required this.matchPercentage,
    required this.referenceText,
    required this.wordFeedback,
    required this.surahNumber,
    required this.ayahNumber,
  });

  /// Built from the WebSocket {"type": "result", …} payload.
  factory RecitationResultModel.fromWsJson(Map<String, dynamic> json) {
    final annotations = (json['word_annotations'] as List<dynamic>? ?? []);
    return RecitationResultModel(
      transcription: json['transcription'] as String? ?? '',
      matchPercentage: (json['overall_accuracy'] as num?)?.toDouble() ?? 0.0,
      referenceText: json['arabic_text'] as String? ?? '',
      wordFeedback: annotations
          .map((e) => WordFeedback.fromJson(e as Map<String, dynamic>))
          .toList(),
      surahNumber: json['surah_number'] as int? ?? 1,
      ayahNumber: json['ayah_number'] as int? ?? 1,
    );
  }
}
