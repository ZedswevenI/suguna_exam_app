import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';

class AppHeader extends StatelessWidget {
  final String? subjectName;
  final String? classInfo;
  final String? assignmentLabel;
  final bool showMenuIcon;
  final bool showBackButton;

  const AppHeader({
    super.key,
    this.subjectName,
    this.classInfo,
    this.assignmentLabel,
    this.showMenuIcon = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.headerHeight,
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.contentPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Back button / Menu icon + Subject name + Class info
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textWhite,
                  ),
                  onPressed: () {
                    Get.back();
                  },
                ),
              if (showMenuIcon && !showBackButton)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textWhite),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              if (subjectName != null)
                Center(
                  child: Text(
                    subjectName!,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppConstants.sectionTitleSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (subjectName != null && classInfo != null)
                const SizedBox(width: 8),
              if (classInfo != null)
                Text(
                  classInfo!,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: AppConstants.normalTextSize,
                  ),
                ),
            ],
          ),
          // Right: Assignment label
          if (assignmentLabel != null)
            Text(
              assignmentLabel!,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: AppConstants.normalTextSize,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
