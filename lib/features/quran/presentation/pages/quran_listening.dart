import 'package:al_qari/config/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

class QuranListening extends StatefulWidget {
  const QuranListening({super.key});

  @override
  State<QuranListening> createState() => _QuranListeningState();
}

class _QuranListeningState extends State<QuranListening> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Force the bottom audio player to always be visible
      QuranCtrl.instance.isShowControl.value = true;
      QuranCtrl.instance.update(['isShowControl']);
      // Set default play mode to play-all (not single ayah)
      AudioCtrl.instance.state.playSingleAyahOnly = false;

      final audioCtrl = AudioCtrl.instance;
      final storedSurah = audioCtrl.state.currentAudioListSurahNum.value;
      final targetSurah = storedSurah > 0 ? storedSurah : 1;

      final isDownloaded = await audioCtrl.isAyahSurahFullyDownloaded(
        targetSurah,
      );
      final jumpSurah = isDownloaded ? targetSurah : 1;

      QuranLibrary().jumpToSurah(jumpSurah);

      // QuranLibraryScreen.build() sets currentPageNumber = pageIndex + 1
      // (the last-saved page) synchronously during build, which triggers the
      // ever() listener and overwrites currentAyahUniqueNumber with the wrong
      // surah.  We must update AFTER that build + ever() callback completes.
      // Using a second addPostFrameCallback ensures we run after the full
      // build cycle (including any ever() triggered by the screen build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final quranCtrl = QuranLibrary.quranCtrl;
        if (quranCtrl.surahs.length >= jumpSurah) {
          final surahAyahs = quranCtrl.surahs[jumpSurah - 1].ayahs;
          if (surahAyahs.isNotEmpty) {
            // Directly assign the first ayah UQ number of the target surah.
            // This bypasses getAyahUQNumber(page) which uses page→ayah lookup
            // and may still get an ayah from the wrong surah boundary.
            audioCtrl.state.currentAyahUniqueNumber.value =
                surahAyahs.first.ayahUQNumber;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.secondaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Listening",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // match your theme
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          tabBarTheme: const TabBarThemeData(
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        child: QuranLibraryScreen(
          // surahNameStyle: SurahNameStyle(),
          bannerStyle: BannerStyle.defaults(isDark: false),
          parentContext: context,

          backgroundColor: Colors.white,
          appLanguageCode: "en",
          isShowAudioSlider: true,
          indexTabStyle: IndexTabStyle.defaults(isDark: false, context: context)
              .copyWith(
                // : "Index", // override label
                tabSurahsLabel: "Surahs",
                tabJozzLabel: "Juz",
                tabBarHeight: 40,
              ),
          searchTabStyle:
              SearchTabStyle.defaults(isDark: false, context: context).copyWith(
                //searchTab: "Search"
              ),
          bookmarksTabStyle:
              BookmarksTabStyle.defaults(
                isDark: false,
                context: context,
              ).copyWith(
                emptyStateText: 'No bookmarks saved',
                yellowGroupText: 'Yellow bookmarks',
                redGroupText: 'Red bookmarks',
                greenGroupText: 'Green bookmarks',
              ),
          topBarStyle:
              QuranTopBarStyle.defaults(
                isDark: false,
                context: context,
              ).copyWith(
                showFontsButton: false,
                showAudioButton: true,
                tabSearchLabel: "Search",
                tabBookmarksLabel: "Bookmarks",
                tabIndexLabel: "Index",
                iconColor: AppColors.secondaryPurple,
                height: 55,
              ),

          // ayahMenuStyle: AyahMenuStyle.defaults(isDark: false, context: context)
          //     .copyWith(
          //       showCopyButton: true,
          //       showBookmarkButtons: true,

          //       // ❌ Disabled
          //       showTafsirButton: false,
          //       showPlayButton: false,
          //       showPlayAllButton: false,
          //     ),
          ayahMenuStyle: AyahMenuStyle.defaults(isDark: false, context: context)
              .copyWith(
                showCopyButton: true,
                showBookmarkButtons: true,
                showTafsirButton: false,
                showPlayButton: false,
                showPlayAllButton: true,
              ),

          ayahStyle: AyahAudioStyle.defaults(isDark: false, context: context)
              .copyWith(
                readersTabText: "Readers",
                downloadedSurahsTabText: "Downloaded Surahs",
                dialogHeaderTitle: "Select Reader",
                noInternetConnectionText: "No internet connection",
              ),

          ayahDownloadManagerStyle:
              AyahDownloadManagerStyle.defaults(
                isDark: false,
                context: context,
              ).copyWith(
                titleText: "Manage Surah Downloads",
                countTextBuilder: (downloaded, total) =>
                    "Downloaded $downloaded/$total ayahs",
              ),

          onSurahBannerPress: (surah) {
            // surah is of type SurahNamesModel
            final arabicName = surah.name;
            final englishName = surah.englishName;
            final revelation = surah.revelationType;
            final ayahCount = surah.ayahsNumber;

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.containerPurple.withValues(
                  alpha: .85,
                ),
                title: Text(arabicName),
                content: Text(
                  "English: $englishName\nNumber of Ayahs: $ayahCount\nRevelation: $revelation",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
