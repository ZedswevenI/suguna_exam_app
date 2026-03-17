import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';

import '../../data/services/sessions.dart';
import '../../data/services/store_service.dart';

class AppSidebar extends StatelessWidget {
  final String selectedRoute;

  const AppSidebar({
    super.key,
    required this.selectedRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(

      width: AppConstants.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            _buildUserHeader(),

            const SizedBox(height: 30),

            _buildSectionTitle("Navigation"),

            const SizedBox(height: 10),

            _buildMenuItem(
              context,
              title: 'Home',
              route: AppRoutes.home,
              icon: Icons.home_rounded,
            ),
            _buildMenuItem(
              context,
              title: 'Usage',
              route: AppRoutes.usage,
              icon: Icons.analytics_outlined,
            ),
            _buildMenuItem(
              context,
              title: 'File Manager',
              route: AppRoutes.fileManager,
              icon: Icons.folder_outlined,
            ),

            const Spacer(),

            _buildDangerItem(context),

            const SizedBox(height: 20),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final user = Session.instance.currentUser?['data'];

    final String name = user?['name'] ?? 'Student';
    final String admissionNo = user?['admissionNo'] ?? '';

    final String firstLetter =
    name.isNotEmpty ? name[0].toUpperCase() : "S";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blueAccent,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ENo: $admissionNo",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildDangerItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => showResetConfirmation(AppRoutes.reset),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.refresh_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text(
                "Reset",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        "Version 1.0.0",
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required String title,
        required String route,
        required IconData icon,
      }) {
    final isSelected = selectedRoute == route;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          Get.toNamed(route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected
                  ? Colors.blueAccent
                  : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showResetConfirmation(String route) {
    Get.defaultDialog(
      title: "Reset Application?",
      middleText:
      "This will clear all downloaded assignments and cached data.\n\nAre you sure you want to continue?",
      textCancel: "Cancel",
      textConfirm: "Reset",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      radius: 12,
      barrierDismissible: false,
      onConfirm: () {
        Get.find<StorageService>().clearAllExceptUser();
        Get.back();
        final isSelected = selectedRoute == AppRoutes.home;
        if(!isSelected) {
          Get.toNamed(AppRoutes.home);
        }
        Get.snackbar(
          "Reset Successful",
          "All local data cleared",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }
}
