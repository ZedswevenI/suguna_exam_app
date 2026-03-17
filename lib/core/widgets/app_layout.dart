import 'package:flutter/material.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/widgets/app_header.dart';
import 'package:suguna_exam_app/core/widgets/app_sidebar.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String? subjectName;
  final String? classInfo;
  final String? assignmentLabel;
  final String selectedRoute;
  final bool showSidebar;
  final bool showBackButton;

  const AppLayout({
    super.key,
    required this.child,
    this.subjectName,
    this.classInfo,
    this.assignmentLabel,
    required this.selectedRoute,
    this.showSidebar = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Force landscape layout
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        if (!isLandscape) {
          return const Scaffold(
            body: Center(child: Text('Please rotate device to landscape mode')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: showSidebar
              ? Drawer(
                  width: AppConstants.sidebarWidth,
                  child: AppSidebar(selectedRoute: selectedRoute),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                // Top Header
                AppHeader(
                  subjectName: subjectName,
                  classInfo: classInfo,
                  assignmentLabel: assignmentLabel,
                  showMenuIcon: showSidebar,
                  showBackButton: showBackButton,
                ),
                // Main Content Area
                Expanded(
                  child: Container(color: Colors.white, child: child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
