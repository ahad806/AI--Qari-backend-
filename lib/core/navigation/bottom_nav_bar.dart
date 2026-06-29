import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/navigation/bottom_nav_controller.dart';
import 'package:al_qari/features/home/presentation/pages/home_screen.dart';
import 'package:al_qari/features/learn/presentation/pages/learn_screen.dart';
import 'package:al_qari/features/profile/presentation/pages/profile_screen.dart';
import 'package:al_qari/features/progress/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomNavBar extends StatelessWidget {
  BottomNavBar({super.key});

  final BottomNavController controller = Get.find();

  final List<Widget> screens = [
    HomeScreen(),
    LearnScreen(),
    ProgressScreen(),

    // ContactsScreen(),
    ProfileScreen(),
  ];

  final List<SvgPicture> icons = [
    // Icon(Icons.home, size: 30),
    SvgPicture.asset("assets/icons/quran_w.svg"),
    SvgPicture.asset("assets/icons/learn_w.svg"),
    // SvgPicture.asset("assets/icons/add.svg"),
    SvgPicture.asset("assets/icons/progress_w.svg"),
    SvgPicture.asset("assets/icons/profile_w.svg"),
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Obx(() {
        return Scaffold(
          body: IndexedStack(
            index: controller.currentIndex.value,
            children: List.generate(
              screens.length,
              (index) => Navigator(
                key: controller.navigatorKeys[index],
                onGenerateRoute: (settings) =>
                    MaterialPageRoute(builder: (_) => screens[index]),
              ),
            ),
          ),
          bottomNavigationBar: CurvedNavigationBar(
            index: controller.currentIndex.value,
            items: icons,
            onTap: controller.changePage,
            backgroundColor: Colors.transparent,
            color: AppColors.secondaryPurple,
            buttonBackgroundColor: AppColors.secondaryPurple,
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
          ),
        );
      }),
    );
  }
}
