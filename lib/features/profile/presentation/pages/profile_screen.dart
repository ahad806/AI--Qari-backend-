import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:al_qari/features/auth/presentation/controllers/auth_controller.dart';
import 'package:al_qari/features/auth/presentation/widgets/custom_textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _auth = Get.find();
  bool _isEditing = false;

  void _toggleEdit() {
    if (!_isEditing) {
      _auth.initProfileEditing();
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveChanges() async {
    await _auth.updateProfile();
    if (_auth.profileUpdateError.isEmpty) {
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.backgroundWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryPurple,
      ),
      body: Stack(
        children: [
          /// Purple header area
          Container(
            width: double.infinity,
            height: Responsive.screenHeight(context) * 0.35,
            decoration: const BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          /// Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Obx(() {
                final user = _auth.user.value;
                final isFemale =
                    (_isEditing ? _auth.profileGender.value : user?.gender) ==
                    'female';
                final avatarAsset = isFemale
                    ? AppAssets.userProfileFemale
                    : AppAssets.userProfile;

                return Column(
                  children: [
                    const SizedBox(height: 16),

                    /// Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(avatarAsset),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// Name display under avatar
                    Text(
                      user?.fullName.isNotEmpty == true ? user!.fullName : '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: Colors.white70),
                    ),

                    const SizedBox(height: 24),

                    /// White card with form fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _auth.profileFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              /// Full Name
                              CustomTextField(
                                label: "Full Name",
                                controller: _isEditing
                                    ? _auth.profileFullNameController
                                    : TextEditingController(
                                        text: user?.fullName ?? '',
                                      ),
                                svgSuffixIcon: AppAssets.user,
                                readOnly: !_isEditing,
                                textInputAction: TextInputAction.next,
                                validator: _isEditing
                                    ? _auth.validateFullName
                                    : null,
                              ),

                              /// Email (always read-only)
                              CustomTextField(
                                label: "Email",
                                controller: TextEditingController(
                                  text: user?.email ?? '',
                                ),
                                svgSuffixIcon: AppAssets.email,
                                readOnly: true,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              /// Phone Number
                              CustomTextField(
                                label: "Phone Number",
                                controller: _isEditing
                                    ? _auth.profilePhoneController
                                    : TextEditingController(
                                        text: user?.phoneNumber ?? '',
                                      ),
                                svgSuffixIcon: AppAssets.phone,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                validator: _isEditing
                                    ? _auth.validatePhone
                                    : null,
                              ),

                              /// Gender
                              if (_isEditing)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 8,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _auth.profileGender.value,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.lightPurple,
                                      labelText: "Gender",
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      labelStyle: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.darkPurple,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.darkPurple,
                                      fontSize: 16,
                                    ),
                                    dropdownColor: AppColors.lightPurple,
                                    iconEnabledColor: AppColors.darkPurple,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'male',
                                        child: Text('Male'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'female',
                                        child: Text('Female'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        _auth.profileGender.value = val;
                                      }
                                    },
                                    validator: _auth.validateGender,
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (user?.gender ?? 'male') == 'female'
                                                ? 'Female'
                                                : 'Male',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: AppColors.darkPurple,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.wc_outlined,
                                          color: AppColors.darkPurple,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              /// Profile update error
                              if (_auth.profileUpdateError.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    _auth.profileUpdateError.value,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              /// Edit / Save button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Obx(
                                  () => ElevatedButton(
                                    onPressed: _auth.isUpdatingProfile.value
                                        ? null
                                        : (_isEditing
                                              ? _saveChanges
                                              : _toggleEdit),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryPurple,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _auth.isUpdatingProfile.value
                                          ? "Saving..."
                                          : (_isEditing
                                                ? "Save Changes"
                                                : "Edit Profile"),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (_isEditing) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: TextButton(
                                    onPressed: () =>
                                        setState(() => _isEditing = false),
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: AppColors.darkPurple,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),

                              /// Logout button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: _auth.signOut,
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                  ),
                                  label: const Text(
                                    "Logout",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    side: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
