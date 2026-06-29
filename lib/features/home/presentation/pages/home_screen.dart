import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/navigation/bottom_nav_controller.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:al_qari/features/auth/presentation/controllers/auth_controller.dart';
import 'package:al_qari/features/quran/presentation/pages/quran_listening.dart';
import 'package:al_qari/features/quran/presentation/pages/quran_reading.dart';
import 'package:al_qari/features/quran/presentation/pages/quran_recitation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
          child: Column(
            children: [
              SizedBox(height: Responsive.screenHeight(context) * 0.03),
              Obx(() {
                final user = auth.user.value;
                final isFemale = user?.gender == 'female';
                final avatarAsset = isFemale
                    ? AppAssets.userProfileFemale
                    : AppAssets.userProfile;
                final displayName = user?.fullName.isNotEmpty == true
                    ? user!.fullName
                    : 'Welcome';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage(avatarAsset),
                    ),
                    SizedBox(width: Responsive.screenWidth(context) * 0.02),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          "Assalamo Alykum 👋",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    Spacer(),
                    Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: SvgPicture.asset(AppAssets.search),
                    ),
                    SizedBox(width: Responsive.screenWidth(context) * 0.02),
                    Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: SvgPicture.asset(AppAssets.notification),
                    ),
                  ],
                );
              }),
              SizedBox(height: Responsive.screenHeight(context) * 0.03),

              // Image.asset(AppAssets.homeBanner),
              SizedBox(
                height: 200, // <<< reduced height
                width: double.infinity,
                child: Stack(
                  children: [
                    // Banner Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        AppAssets.homeBanner,
                        width: double.infinity,
                        height: double.infinity, // <<< added
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Text on top of banner
                    Positioned(
                      left: 20,
                      top: 30,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: Responsive.screenWidth(context) * 0.7,
                            child: Text(
                              "Let’s begin your Quran learning journey with AI Qari.",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          SizedBox(height: 8),

                          SizedBox(
                            width: Responsive.screenWidth(context) * 0.45,
                            child: Text(
                              "Start by learning basic Tajweed rules. \nTry reciting short Surahs with real-time feedback.",
                              maxLines: 4,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),

                          // Padding(
                          //   padding: const EdgeInsets.only(left: 200.0),
                          //   child: Align(
                          //     alignment: AlignmentGeometry.centerRight,
                          //     child: Image.asset(AppAssets.quran),
                          //   ),
                          // ), // <<< made height smaller to fit
                        ],
                      ),
                    ),
                    Positioned(
                      left: 60,
                      right: 1,
                      // top: 100,
                      bottom: 2,
                      child: Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: Image.asset(AppAssets.splash, height: 160),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.screenHeight(context) * 0.04),

              StaggeredGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 15,
                children: [
                  // 1st container – short
                  StaggeredGridTile.fit(
                    crossAxisCellCount: 1,
                    child: InkWell(
                      onTap: () {
                        // Get.toNamed('/quranIndex');
                        // Get.to(() => QuranRecitation());
                        Get.to(() => QuranRecitation());
                      },
                      child: Container(
                        height: 170,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.darkGreen,
                              AppColors.lightGreen,
                              AppColors.darkGreen,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Recitation",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                "Start practicing Surahs with real-time Tajweed feedback.",
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Align(
                                alignment: AlignmentGeometry.centerRight,
                                child: Image.asset(
                                  AppAssets.recitation,
                                  height: 60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2nd container – medium
                  StaggeredGridTile.fit(
                    crossAxisCellCount: 1,

                    child: InkWell(
                      onTap: () {
                        // Get.to(
                        //   () => QuranIndexScreen(mode: QuranMode.listening),
                        // );
                        Get.to(() => QuranListening());
                      },
                      child: Container(
                        height: 210,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.darkOrange,
                              AppColors.lightOrange,
                              AppColors.darkOrange,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Listening",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                "Listen to authentic recitation and follow the correct pronunciation.",
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Spacer(),
                              Align(
                                alignment: AlignmentGeometry.centerRight,
                                child: Image.asset(AppAssets.listening),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3rd container – long
                  StaggeredGridTile.fit(
                    crossAxisCellCount: 1,

                    child: InkWell(
                      onTap: () {
                        // Get.to(
                        //   () => QuranIndexScreen(mode: QuranMode.reading),
                        // );
                        Get.to(() => QuranReading());
                      },
                      child: Container(
                        height: 210,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.darkPeach,
                              AppColors.lightPeach,
                              AppColors.darkPeach,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Reading",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                "Read along with clear text and learn pronunciation at your own pace.",
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Spacer(),
                              Align(
                                alignment: AlignmentGeometry.centerRight,
                                child: Image.asset(AppAssets.reading),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4th container – short
                  StaggeredGridTile.fit(
                    crossAxisCellCount: 1,

                    child: InkWell(
                      onTap: () {
                        Get.find<BottomNavController>().changePage(
                          2,
                        ); // Progress tab index
                      },

                      child: Container(
                        height: 170,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.darkMauve,
                              AppColors.lightMauve,
                              AppColors.darkMauve,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Progress",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                "Track your learning and recitation improvement over time.",
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Align(
                                alignment: AlignmentGeometry.centerRight,
                                child: Image.asset(
                                  AppAssets.progress,
                                  height: 60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
