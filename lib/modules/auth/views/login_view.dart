import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/resources/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child:_buildTabletLayout(context),
      ),
    );
  }


  // Tablet/iPad Layout - Centered with larger form
  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icon
                Container(
                  width: 140,
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                // App Title
                AppText(
                  AppStrings.appName,
                  style: AppTextStyle.headlineMedium,
                  textAlign: TextAlign.center,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 56),
                // Username Field
                TextFormField(
                  controller: controller.usernameController,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Enrolment number",
                    hintText: "Enter enrolment number",
                    prefixIcon: const Icon(Icons.person, size: 28),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  validator: (value) {
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.gotoLogin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : AppText(
                              "Login",
                              style: AppTextStyle.titleMedium,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
