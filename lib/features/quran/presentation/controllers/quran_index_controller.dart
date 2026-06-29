import 'package:al_qari/features/quran/data/models/quran_item.dart';
import 'package:get/get.dart';
import '../../data/repositories/quran_repository.dart';

class QuranIndexController extends GetxController {
  final QuranRepository _repository = QuranRepository();

  final selectedTab = 0.obs; // 0 = Surah, 1 = Parah
  final isLoading = true.obs;

  final surahs = <QuranItem>[].obs;
  final parahs = <QuranItem>[].obs;

  @override
  void onInit() {
    loadData();
    super.onInit();
  }

  void loadData() {
    surahs.assignAll(_repository.getSurahs());
    parahs.assignAll(_repository.getParahs());
    isLoading.value = false;
  }

  List<QuranItem> get currentList => selectedTab.value == 0 ? surahs : parahs;
}
