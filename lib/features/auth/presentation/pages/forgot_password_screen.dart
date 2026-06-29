import 'dart:async';

import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:al_qari/features/auth/presentation/controllers/auth_controller.dart';
import 'package:al_qari/features/auth/presentation/widgets/custom_textfield_widget.dart';
import 'package:al_qari/features/auth/presentation/widgets/auth_layout.dart';
import 'package:al_qari/widgets/custom_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final AuthController _auth;

  static const _cooldownSeconds = 30;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _auth = Get.find();
    // Defer reactive writes until after the first frame to avoid
    // "setState called during build" when Obx listeners fire.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth.passwordResetSent.value = false;
      _auth.errorMessage.value = '';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _sendLink() async {
    await _auth.sendPasswordReset();
    if (_auth.passwordResetSent.value) {
      _startCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthLayout(
          title: "Forgot Password",
          description: "No worries. Let's help you get back in.",
          topSvgAsset: AppAssets.forgotPassword,
          child: Form(
            key: _auth.forgotFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: "Enter your email",
                  svgSuffixIcon: AppAssets.email,
                  controller: _auth.forgotEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: _auth.validateEmail,
                ),

                // Error message
                Obx(() {
                  if (_auth.errorMessage.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      _auth.errorMessage.value,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  );
                }),

                // Success message
                Obx(() {
                  if (!_auth.passwordResetSent.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      'Password reset link sent! Check your inbox.',
                      style: GoogleFonts.mulish(
                        textStyle: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),

                // Countdown / resend hint
                if (_secondsLeft > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 2,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Resend in $_secondsLeft sec',
                        style: GoogleFonts.mulish(
                          textStyle: const TextStyle(
                            color: AppColors.darkPurple,
                            fontSize: 10,
                          ),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),

                SizedBox(height: Responsive.screenHeight(context) * 0.02),

                Obx(() {
                  final busy = _auth.isLoading.value;
                  final inCooldown = _secondsLeft > 0;
                  return CustomButtonWidget(
                    text: busy
                        ? "Sending..."
                        : (inCooldown ? "Link Sent" : "Send Link"),
                    onTap: (busy || inCooldown) ? null : _sendLink,
                  );
                }),

                SizedBox(height: Responsive.screenHeight(context) * 0.04),
              ],
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 40,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.secondaryPurple,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
