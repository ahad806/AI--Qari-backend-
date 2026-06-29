// import 'package:flutter/material.dart';

// class CustomButtonWidget extends StatelessWidget {
//   const CustomButtonWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(decoration: BoxDecoration());
//   }
// }

import 'package:al_qari/config/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color textColor;
  final double borderRadius;
  final double height;
  final double? width;

  const CustomButtonWidget({
    super.key,
    required this.text,
    required this.onTap,
    this.backgroundColor = AppColors.primaryPurple,
    this.gradient,
    this.textColor = Colors.white,
    this.borderRadius = 12,
    this.height = 50,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                color: AppColors.backgroundWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),

          // style: TextStyle(
          //   color: textColor,
          //   fontSize: 16,
          //   fontWeight: FontWeight.bold,
          // ),
        ),
      ),
    );
  }
}
