import 'package:al_qari/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuranReading extends StatelessWidget {
  const QuranReading({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new reading setup flow, replacing this screen so that
    // pressing back from readingSetup returns to wherever the user came from
    // (e.g. the home page) rather than landing back here on the spinner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offNamed(AppRoutes.readingSetup);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
