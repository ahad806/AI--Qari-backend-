class QuranItem {
  final int id;
  final String arabic;
  final String english;
  final int? verses; // null for Parah
  final bool isSurah;

  QuranItem({
    required this.id,
    required this.arabic,
    required this.english,
    this.verses,
    required this.isSurah,
  });
}
