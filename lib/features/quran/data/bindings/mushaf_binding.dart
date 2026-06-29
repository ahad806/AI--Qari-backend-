import 'package:al_qari/features/quran/data/models/quran_item.dart';
import 'package:al_qari/features/quran/presentation/controllers/mushaf_controller.dart';
import 'package:get/get.dart';

class MushafBinding extends Bindings {
  @override
  void dependencies() {
    final item = Get.arguments as QuranItem;

    Get.put(
      MushafController(
        surahId: item.isSurah ? item.id : null,
        // parahId: item.isParah ? item.id : null,
        arabicName: item.arabic,
        englishName: item.english,
      ),
    );
  }
}
