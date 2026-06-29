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
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController _auth = Get.find();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: "Sign Up",
      description: "Join AI Qari and make Quran learning easier than ever.",
      topSvgAsset: AppAssets.signup,
      child: Form(
        key: _auth.signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: "Full name",
              svgSuffixIcon: AppAssets.user,
              controller: _auth.signupFullNameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: _auth.validateFullName,
            ),

            CustomTextField(
              label: "Email",
              svgSuffixIcon: AppAssets.email,
              controller: _auth.signupEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _auth.validateEmail,
            ),

            CustomTextField(
              label: "Phone number",
              svgSuffixIcon: AppAssets.phone,
              controller: _auth.signupPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _auth.validatePhone,
            ),

            // ─── Gender Dropdown ─────────────────────────────────────────────
            Obx(() {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _auth.selectedGender.value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.lightPurple,
                    labelText: "Gender",
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkPurple,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryPurple,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.darkPurple,
                    fontSize: 16,
                  ),
                  dropdownColor: AppColors.lightPurple,
                  iconEnabledColor: AppColors.darkPurple,
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (val) {
                    if (val != null) _auth.selectedGender.value = val;
                  },
                  validator: _auth.validateGender,
                ),
              );
            }),

            CustomTextField(
              label: "Password",
              controller: _auth.signupPasswordController,
              obscureText: !_passwordVisible,
              textInputAction: TextInputAction.next,
              validator: _auth.validatePassword,
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

            CustomTextField(
              label: "Confirm Password",
              controller: _auth.signupConfirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              textInputAction: TextInputAction.done,
              validator: _auth.validateConfirmPassword,
              suffixIconWidget: IconButton(
                icon: Icon(
                  _confirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.darkPurple,
                  size: 22,
                ),
                onPressed: () => setState(
                  () => _confirmPasswordVisible = !_confirmPasswordVisible,
                ),
              ),
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
                text: _auth.isLoading.value ? "Creating account..." : "Sign Up",
                onTap: _auth.isLoading.value ? null : _auth.signUp,
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
                  text: "Already a Member? ",
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  children: [
                    TextSpan(
                      text: "Log In",
                      style: GoogleFonts.mulish(
                        textStyle: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Get.offNamed(AppRoutes.login),
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
