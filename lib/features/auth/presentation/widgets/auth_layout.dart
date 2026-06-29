import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String description;
  final String topSvgAsset;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.title,
    required this.description,
    required this.topSvgAsset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = Responsive.screenHeight(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.topLeft,
            colors: [AppColors.primaryPurple, AppColors.darkPurple],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Space above the white container
              SizedBox(height: screenHeight * 0.18),

              /// Stack to overlay the icon on top of white container
              Stack(
                clipBehavior: Clip.none,
                children: [
                  /// White container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 60,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 60,
                        ), // space for the icon overlap
                        /// Title
                        Center(
                          child: Text(
                            title,
                            style: GoogleFonts.roboto(
                              textStyle: const TextStyle(
                                color: AppColors.darkPurple,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        /// Description
                        Center(
                          child: Text(
                            description,
                            style: GoogleFonts.mulish(
                              textStyle: const TextStyle(
                                color: AppColors.darkPurple,
                                fontSize: 14,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// Screen content
                        child,
                      ],
                    ),
                  ),

                  /// Top Icon (overlaps container)
                  Positioned(
                    top: -50, // half of icon height to overlap
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SvgPicture.asset(topSvgAsset, height: 100),
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
