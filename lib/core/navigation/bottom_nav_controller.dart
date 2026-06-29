import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  var currentIndex = 0.obs;

  // One navigator key per tab for nested navigation
  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  void changePage(int index) {
    currentIndex.value = index;
  }

  // Push a new screen inside the current tab
  void pushToCurrentTab(Widget page) {
    navigatorKeys[currentIndex.value].currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
