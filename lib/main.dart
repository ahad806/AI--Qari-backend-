import 'package:al_qari/config/bindings/initial_binding.dart';
import 'package:al_qari/config/routes/app_pages.dart';
import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/config/themes/app_theme.dart';
import 'package:al_qari/core/navigation/bottom_nav_controller.dart';
import 'package:al_qari/core/services/session_service.dart';
import 'package:al_qari/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_library/quran.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await QuranLibrary.init();
  await SessionService.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  Get.put(BottomNavController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(context),
      initialRoute: AppRoutes.splash,
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
    );
  }
}
