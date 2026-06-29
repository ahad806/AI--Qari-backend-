import 'package:al_qari/config/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? svgSuffixIcon;

  /// Overrides [svgSuffixIcon] when provided — use for custom widgets like
  /// an eye-toggle IconButton on password fields.
  final Widget? suffixIconWidget;

  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.label,
    this.svgSuffixIcon,
    this.suffixIconWidget,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onSuffixTap,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    Widget? resolvedSuffix;

    if (suffixIconWidget != null) {
      resolvedSuffix = suffixIconWidget;
    } else if (svgSuffixIcon != null) {
      resolvedSuffix = GestureDetector(
        onTap: onSuffixTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(svgSuffixIcon!, width: 20, height: 20),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        autovalidateMode: AutovalidateMode.disabled,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.lightPurple,
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,

          labelStyle: const TextStyle(
            fontSize: 16,
            color: AppColors.darkPurple,
          ),

          errorStyle: const TextStyle(fontSize: 12, color: Colors.redAccent),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primaryPurple,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),

          suffixIcon: resolvedSuffix,
        ),
      ),
    );
  }
}
