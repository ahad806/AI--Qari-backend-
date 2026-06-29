import 'package:al_qari/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuranRecitation extends StatelessWidget {
  const QuranRecitation({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace this stub with the setup screen so that system back from setup
    // returns to wherever the user came from (e.g. home) instead of landing
    // back here and re-pushing setup in an infinite loop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offNamed(AppRoutes.recitationSetup);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
