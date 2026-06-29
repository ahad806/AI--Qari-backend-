import 'package:al_qari/config/routes/app_routes.dart';
import 'package:al_qari/core/services/session_service.dart';
import 'package:al_qari/features/auth/domain/entities/user_entity.dart';
import 'package:al_qari/features/auth/domain/failures/auth_failure.dart';
import 'package:al_qari/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;

  AuthController(this._repository);

  // ─── Observables ────────────────────────────────────────────────────────────

  final Rx<UserEntity?> user = Rx<UserEntity?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool rememberMe = false.obs;

  /// True while a password-reset email was successfully sent (drives UI hint).
  final RxBool passwordResetSent = false.obs;

  // ─── Form controllers — Login ────────────────────────────────────────────────

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  // ─── Form controllers — Sign Up ──────────────────────────────────────────────

  final signupFullNameController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPhoneController = TextEditingController();
  final signupPasswordController = TextEditingController();
  final signupConfirmPasswordController = TextEditingController();
  final signupFormKey = GlobalKey<FormState>();
  final RxString selectedGender = 'male'.obs;
  // ─── Form controllers — Forgot Password ─────────────────────────────────────

  final forgotEmailController = TextEditingController();
  final forgotFormKey = GlobalKey<FormState>();

  // ─── Form controllers — Profile Edit ─────────────────────────────────────

  final profileFullNameController = TextEditingController();
  final profilePhoneController = TextEditingController();
  final profileFormKey = GlobalKey<FormState>();
  final RxString profileGender = 'male'.obs;
  final RxBool isUpdatingProfile = false.obs;
  final RxString profileUpdateError = ''.obs;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    user.value = _repository.currentUser;
    _repository.authStateChanges().listen((u) => user.value = u);
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signupFullNameController.dispose();
    signupEmailController.dispose();
    signupPhoneController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
    forgotEmailController.dispose();
    profileFullNameController.dispose();
    profilePhoneController.dispose();
    super.onClose();
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  Future<void> signIn() async {
    if (!loginFormKey.currentState!.validate()) return;
    _clearError();
    isLoading.value = true;

    try {
      final entity = await _repository.signIn(
        email: loginEmailController.text,
        password: loginPasswordController.text,
      );
      user.value = entity;
      await SessionService.setRememberMe(rememberMe.value);
      Get.offAllNamed(AppRoutes.nav);
    } on AuthFailure catch (f) {
      errorMessage.value = f.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp() async {
    if (!signupFormKey.currentState!.validate()) return;
    _clearError();
    isLoading.value = true;

    try {
      final entity = await _repository.signUp(
        fullName: signupFullNameController.text,
        email: signupEmailController.text,
        phoneNumber: signupPhoneController.text,
        gender: selectedGender.value,
        password: signupPasswordController.text,
      );
      user.value = entity;
      await SessionService.setRememberMe(true); // signup always remembers
      Get.offAllNamed(AppRoutes.nav);
    } on AuthFailure catch (f) {
      errorMessage.value = f.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordReset() async {
    if (!forgotFormKey.currentState!.validate()) return;
    _clearError();
    isLoading.value = true;
    passwordResetSent.value = false;

    try {
      await _repository.sendPasswordResetEmail(
        email: forgotEmailController.text,
      );
      passwordResetSent.value = true;
    } on AuthFailure catch (f) {
      errorMessage.value = f.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await SessionService.clear();
    await _repository.signOut();
    user.value = null;
    rememberMe.value = false;
    Get.offAllNamed(AppRoutes.login);
  }

  /// Signs out without navigating — used by splash when remember_me is false.
  Future<void> signOutSilent() async {
    await SessionService.clear();
    await _repository.signOut();
    user.value = null;
    rememberMe.value = false;
  }

  Future<void> signInWithGoogle() async {
    _clearError();
    isLoading.value = true;
    try {
      final entity = await _repository.signInWithGoogle();
      user.value = entity;
      await SessionService.setRememberMe(true); // Google always remembers
      Get.offAllNamed(AppRoutes.nav);
    } on AuthFailure catch (f) {
      errorMessage.value = f.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads the current user data into profile edit controllers.
  void initProfileEditing() {
    final u = user.value;
    if (u == null) return;
    profileFullNameController.text = u.fullName;
    profilePhoneController.text = u.phoneNumber;
    profileGender.value = u.gender;
    profileUpdateError.value = '';
  }

  Future<void> updateProfile() async {
    if (!profileFormKey.currentState!.validate()) return;
    profileUpdateError.value = '';
    isUpdatingProfile.value = true;

    try {
      final updated = await _repository.updateProfile(
        fullName: profileFullNameController.text,
        phoneNumber: profilePhoneController.text,
        gender: profileGender.value,
      );
      user.value = updated;
    } on AuthFailure catch (f) {
      profileUpdateError.value = f.message;
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  // ─── Validators ─────────────────────────────────────────────────────────────

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    return null;
  }

  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required.';
    if (value.trim().length < 2) return 'Enter your full name.';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != signupPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? validateGender(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please select a gender.';
    return null;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  void _clearError() => errorMessage.value = '';

  bool get isAuthenticated => user.value != null;
}
