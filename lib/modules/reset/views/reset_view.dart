import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/utils/responsive_helper.dart';
import 'package:suguna_exam_app/core/widgets/app_layout.dart';

class ResetView extends GetView {
  const ResetView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedRoute: AppRoutes.reset,
      showBackButton: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (ResponsiveHelper.isTablet(context)) {
            return _buildTabletLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.getMaxContentWidth(context),
        ),
        child: Text(
          'Reset',
          style: TextStyle(
            fontSize: AppConstants.sectionTitleSize *
                ResponsiveHelper.getFontSizeMultiplier(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return const Center(
      child: Text(
        'Reset',
        style: TextStyle(fontSize: AppConstants.sectionTitleSize),
      ),
    );
  }
}
