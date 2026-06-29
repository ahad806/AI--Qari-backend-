// import 'package:al_qari/features/quran/data/constants/mushaf_constants.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:quran_library/quran.dart';

// class MushafController extends GetxController {
//   final QuranLibrary _quran = QuranLibrary();

//   late PageController pageController;

//   final int? surahId;
//   final int? parahId;
//   final String arabicName;
//   final String englishName;

//   MushafController({
//     this.surahId,
//     this.parahId,
//     required this.arabicName,
//     required this.englishName,
//   });

//   final currentPage = 1.obs;
//   final totalPages = 604;

//   @override
//   void onInit() {
//     currentPage.value = getStartPage();
//     pageController = PageController(initialPage: currentPage.value - 1);
//     super.onInit();
//   }

//   int getStartPage() {
//     if (surahId != null) {
//       return MushafConstants.surahStartPages[surahId! - 1];
//     }
//     if (parahId != null) {
//       return MushafConstants.parahStartPages[parahId! - 1];
//     }
//     return 1;
//   }

//   Future<List<AyahModel>> loadPage(int page) async {
//     return _quran.getPageAyahsByPageNumber(pageNumber: page);
//   }

//   /// Surah-based fetching: always starts from first ayah
//   // Future<List<AyahModel>> loadSurah(int surahId) async {
//   //   // fetch all pages of the surah
//   //   final startPage = MushafConstants.surahStartPages[surahId - 1];
//   //   final endPage = (surahId < 114)
//   //       ? MushafConstants.surahStartPages[surahId] - 1
//   //       : 604; // last surah ends at last page

//   //   List<AyahModel> ayahs = [];
//   //   for (int page = startPage; page <= endPage; page++) {
//   //     final pageAyahs = await _quran.getPageAyahsByPageNumber(pageNumber: page);
//   //     ayahs.addAll(pageAyahs.where((a) => a.surahNumber == surahId));
//   //   }

//   //   // Add Bismillah if not Surah 9
//   //   if (surahId != 9) {
//   //     final bismillah = AyahModel.fromAya(
//   //       ayah: ayahs.first,
//   //       aya: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
//   //       ayaText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
//   //     );
//   //     ayahs.insert(0, bismillah);
//   //   }

//   //   return ayahs;
//   // }

//   Future<List<AyahModel>> loadSurah(int surahId) async {
//   final startPage = MushafConstants.surahStartPages[surahId - 1];
//   final endPage = (surahId < 114)
//       ? MushafConstants.surahStartPages[surahId] - 1
//       : 604;

//   // Create a list of futures, one for each page
//   final futures = <Future<List<AyahModel>>>[];
//   for (int page = startPage; page <= endPage; page++) {
//     futures.add(_quran.getPageAyahsByPageNumber(pageNumber: page));
//   }

//   // Wait for all pages to load
//   final pages = await Future.wait(futures); // pages is List<List<AyahModel>>

//   // Flatten the list and filter by this surah
//   List<AyahModel> ayahs = pages
//       .expand((pageAyahs) => pageAyahs.where((a) => a.surahNumber == surahId))
//       .toList();

//   // Add Bismillah if not Surah 9
//   if (surahId != 9 && ayahs.isNotEmpty) {
//     final bismillah = AyahModel.fromAya(
//       ayah: ayahs.first,
//       aya: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
//       ayaText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
//     );
//     ayahs.insert(0, bismillah);
//   }

//   return ayahs;
// }

//   void onPageChanged(int index) {
//     currentPage.value = index + 1;
//   }

//   void nextPage() {
//     if (currentPage.value < totalPages) {
//       pageController.nextPage(
//         duration: 300.milliseconds,
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void previousPage() {
//     if (currentPage.value > 1) {
//       pageController.previousPage(
//         duration: 300.milliseconds,
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void bookmarkPage() {
//     _quran.setBookmark(
//       surahName: arabicName,
//       ayahNumber: 1,
//       ayahId: 1,
//       page: currentPage.value,
//       bookmarkId: currentPage.value,
//     );
//   }
// }

import 'package:al_qari/features/quran/data/constants/mushaf_constants.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:quran_library/quran.dart';

class MushafController extends GetxController {
  final QuranLibrary _quran = QuranLibrary();

  late PageController pageController;

  final int? surahId;
  final int? parahId;
  final String arabicName;
  final String englishName;

  MushafController({
    this.surahId,
    this.parahId,
    required this.arabicName,
    required this.englishName,
  });

  final currentPage = 1.obs;
  final totalPages = 604;

  @override
  void onInit() {
    currentPage.value = getStartPage();
    pageController = PageController(initialPage: currentPage.value - 1);
    super.onInit();
  }

  int getStartPage() {
    if (surahId != null) {
      return MushafConstants.surahStartPages[surahId! - 1];
    }
    if (parahId != null) {
      return MushafConstants.parahStartPages[parahId! - 1];
    }
    return 1;
  }

  Future<List<AyahModel>> loadPage(int page) async {
    return _quran.getPageAyahsByPageNumber(pageNumber: page);
  }

  // Future<List<AyahModel>> loadSurah(int surahId) async {
  //   final startPage = MushafConstants.surahStartPages[surahId - 1];
  //   final endPage = (surahId < 114)
  //       ? MushafConstants.surahStartPages[surahId] - 1
  //       : 604;

  //   List<AyahModel> ayahs = [];

  //   // Load all pages for this surah
  //   for (int page = startPage; page <= endPage; page++) {
  //     final pageAyahs = await _quran.getPageAyahsByPageNumber(pageNumber: page);
  //     ayahs.addAll(pageAyahs.where((a) => a.surahNumber == surahId));
  //   }

  //   // Add Bismillah if not Surah 9
  //   if (surahId != 9 && ayahs.isNotEmpty) {
  //     final bismillah = AyahModel.fromAya(
  //       ayah: ayahs.first,
  //       aya: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  //       ayaText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  //     );
  //     ayahs.insert(0, bismillah);
  //   }

  //   return ayahs; // This returns Future<List<AyahModel>> because it's async
  // }

  List<AyahModel> _insertBismillahIfNeeded(int surahId, List<AyahModel> ayahs) {
    if (ayahs.isEmpty) return ayahs;

    // Surah 1 already contains Bismillah
    if (surahId == 1) return ayahs;

    // Surah 9 has no Bismillah
    if (surahId == 9) return ayahs;

    // Safety check (avoid duplicates)
    if (ayahs.first.text.trim().startsWith('بِسْمِ اللَّهِ')) {
      return ayahs;
    }

    final bismillah = AyahModel.fromAya(
      ayah: ayahs.first,
      aya: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      ayaText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      centered: true,
    );

    ayahs.insert(0, bismillah);
    return ayahs;
  }

  Future<List<AyahModel>> loadSurah(int surahId) async {
    final startPage = MushafConstants.surahStartPages[surahId - 1];

    // Next surah start page OR end of Quran
    final endPage = (surahId < 114)
        ? MushafConstants.surahStartPages[surahId] - 1
        : 604;

    final List<AyahModel> ayahs = [];

    for (int page = startPage; page <= endPage; page++) {
      final pageAyahs = _quran.getPageAyahsByPageNumber(pageNumber: page);

      ayahs.addAll(pageAyahs);
    }

    return _insertBismillahIfNeeded(surahId, ayahs);
  }

  void onPageChanged(int index) {
    currentPage.value = index + 1;
  }

  void nextPage() {
    if (currentPage.value < totalPages) {
      pageController.nextPage(
        duration: 300.milliseconds,
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      pageController.previousPage(
        duration: 300.milliseconds,
        curve: Curves.easeInOut,
      );
    }
  }

  void bookmarkPage() {
    _quran.setBookmark(
      surahName: arabicName,
      ayahNumber: 1,
      ayahId: 1,
      page: currentPage.value,
      bookmarkId: currentPage.value,
    );
  }
}
