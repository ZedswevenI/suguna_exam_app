import 'package:flutter/material.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';
import 'package:suguna_exam_app/core/widgets/app_text.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person,
                    size: 64,
                    color: AppColors.textWhite,
                  ),
                  const SizedBox(height: 8),
                  AppText.headlineMedium(
                    'Assignment App',
                    color: AppColors.textWhite,
                  ),
                ],
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Divider(),
                _buildLogoutMenuItem(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutMenuItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: AppColors.error),
      title: AppText.bodyLarge('Logout', color: AppColors.error),
      onTap: () {
        Navigator.pop(context); // Close drawer
        _showLogoutDialog(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: AppText.titleLarge('Logout'),
          content: AppText.bodyMedium('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: AppText.bodyMedium('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // TODO: Implement logout functionality
              },
              child: AppText.bodyMedium('Logout', color: AppColors.error),
            ),
          ],
        );
      },
    );
  }
}
