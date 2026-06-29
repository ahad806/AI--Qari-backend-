import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Learning Basics",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w800,
            // letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10,
              ),
              child: Align(
                alignment: AlignmentGeometry.center,
                child: Text(
                  "Choose what you want to Learn",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            Center(
              child: InkWell(
                onTap: () {
                  Get.toNamed('/qaida');
                },
                child: Container(
                  width: Responsive.screenWidth(context) * 0.9,
                  //height: Responsive.screenHeight(context) * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.containerPurple.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: Offset(0, 4), // changes position of shadow
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Image.asset(AppAssets.quaida, height: 70),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: Responsive.screenWidth(context) * 0.6,
                              child: Text(
                                "Quaida (Basics)",
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.secondaryPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.screenHeight(context) * 0.005,
                            ),
                            SizedBox(
                              width: Responsive.screenWidth(context) * 0.5,
                              child: Text(
                                maxLines: 3,
                                "Start with the foundation of Quranic letters and pronunciation.",
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: Responsive.screenHeight(context) * 0.02),
            Center(
              child: InkWell(
                onTap: () {
                  Get.toNamed('/tajweed');
                },
                child: Container(
                  width: Responsive.screenWidth(context) * 0.9,
                  //height: Responsive.screenHeight(context) * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.containerPurple.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: Offset(0, 4), // changes position of shadow
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Image.asset(AppAssets.tajweed, height: 70),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: Responsive.screenWidth(context) * 0.6,
                              child: Text(
                                "Tajweed (Rules)",
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.secondaryPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.screenHeight(context) * 0.005,
                            ),
                            SizedBox(
                              width: Responsive.screenWidth(context) * 0.5,
                              child: Text(
                                maxLines: 3,
                                "Learn how to recite with proper articulation and beauty.",
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.screenHeight(context) * 0.02),
            Center(
              child: Container(
                width: Responsive.screenWidth(context) * 0.9,
                // height: Responsive.screenHeight(context) * 0.12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.containerPurple.withValues(alpha: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      spreadRadius: 2,
                      offset: Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Image.asset(AppAssets.kirat, height: 70),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: Responsive.screenWidth(context) * 0.6,
                            child: Text(
                              "Kirat (Recitation Practice)",
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.secondaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          SizedBox(
                            height: Responsive.screenHeight(context) * 0.005,
                          ),
                          SizedBox(
                            width: Responsive.screenWidth(context) * 0.5,
                            child: Text(
                              maxLines: 3,
                              "Practice small ayahs with guidance and AI feedback.",
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Responsive.screenHeight(context) * 0.02),
          ],
        ),
      ),
    );
  }
}
