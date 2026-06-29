import 'package:get/get.dart';

class HafizRecitationCtrl extends GetxController {
  RxBool isRecording = false.obs;
  RxBool isRevealed = true.obs;

  void startRecording() {
    isRecording.value = true;
    isRevealed.value = false;
  }

  void stopRecording() {
    isRecording.value = false;
    isRevealed.value = true; // reveal text after recitation
  }

  void reset() {
    isRecording.value = false;
    isRevealed.value = false;
  }
}
