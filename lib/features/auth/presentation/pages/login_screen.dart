import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:al_qari/features/auth/presentation/controllers/auth_controller.dart';
import 'package:al_qari/features/auth/presentation/widgets/custom_textfield_widget.dart';
import 'package:al_qari/features/auth/presentation/widgets/auth_layout.dart';
import 'package:al_qari/widgets/custom_button_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _auth = Get.find();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: "Sign In",
      description: "Welcome back — your Quran learning continues here.",
      topSvgAsset: AppAssets.login,
      child: Form(
        key: _auth.loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: "Enter your email",
              svgSuffixIcon: AppAssets.email,
              controller: _auth.loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _auth.validateEmail,
            ),

            CustomTextField(
              label: "Password",
              controller: _auth.loginPasswordController,
              obscureText: !_passwordVisible,
              textInputAction: TextInputAction.done,
              validator: _auth.validateLoginPassword,
              suffixIconWidget: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.darkPurple,
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),

            // ─── Remember Me + Forgot Password row ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: _auth.rememberMe.value,
                        activeColor: AppColors.primaryPurple,
                        onChanged: (val) =>
                            _auth.rememberMe.value = val ?? false,
                      ),
                    ),
                    Text(
                      "Remember me",
                      style: GoogleFonts.mulish(
                        textStyle: const TextStyle(
                          color: AppColors.darkPurple,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8,
                    ),
                    child: Text(
                      "Forgot Password ?",
                      style: GoogleFonts.mulish(
                        textStyle: const TextStyle(
                          color: AppColors.darkPurple,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Firebase error message
            Obx(() {
              if (_auth.errorMessage.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  _auth.errorMessage.value,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              );
            }),

            const SizedBox(height: 8),

            Obx(
              () => CustomButtonWidget(
                text: _auth.isLoading.value ? "Signing in..." : "Sign In",
                onTap: _auth.isLoading.value ? null : _auth.signIn,
              ),
            ),

            SizedBox(height: Responsive.screenHeight(context) * 0.04),

            Center(
              child: Text(
                "Or create account using social media",
                style: GoogleFonts.mulish(
                  textStyle: const TextStyle(
                    color: AppColors.darkPurple,
                    fontSize: 14,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: Responsive.screenHeight(context) * 0.01),
            Center(
              child: Obx(
                () => GestureDetector(
                  onTap: _auth.isLoading.value ? null : _auth.signInWithGoogle,
                  child: SvgPicture.asset(AppAssets.google, height: 50),
                ),
              ),
            ),
            SizedBox(height: Responsive.screenHeight(context) * 0.02),

            Center(
              child: RichText(
                text: TextSpan(
                  text: "New Member? ",
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  children: [
                    TextSpan(
                      text: "Register now",
                      style: GoogleFonts.mulish(
                        textStyle: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Get.offNamed(AppRoutes.signup),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
