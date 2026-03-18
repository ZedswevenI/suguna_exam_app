import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';
import 'package:suguna_exam_app/core/utils/responsive_helper.dart';
import 'package:suguna_exam_app/modules/assignment_instructions/controllers/assignment_instructions_controller.dart';

import '../../../core/routes/app_routes.dart';
import '../../test_player/controllers/test_player_parser.dart';

class AssignmentInstructionsView
    extends GetView<AssignmentInstructionsController> {
  final bool startTest;
  const AssignmentInstructionsView({super.key,this.startTest = true});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent default pop
      onPopInvoked: (didPop) {
        if (didPop) return;
        if(startTest) {
          Get.offAllNamed(AppRoutes.discussion);
        } else {
          Get.close(1);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (ResponsiveHelper.isTablet(context)) {
              return _buildTabletLayout(context);
            } else {
              return _buildMobileLayout(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white,
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Please read the following instructions carefully",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text("View In: "),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: "English",
                      items: const [
                        DropdownMenuItem(
                            value: "English",
                            child: Text("English")),
                      ],
                      onChanged: (value) {},
                    ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ================= GENERAL INSTRUCTIONS =================
                    _sectionTitle("General Instructions:"),

                    const SizedBox(height: 12),

                    _bulletText(
                        "1. The clock has been set at the server and the countdown timer at the top right corner of your screen will display the time remaining for you to complete the exam. When the clock runs out the exam ends by default - you are not required to end or submit your exam."),

                    _bulletText(
                        "2. The question palette at the right of screen shows one of the following statuses of each of the questions numbered:"),

                    const SizedBox(height: 12),

                    _statusRow(
                      QuestionStatus.notVisited,
                      "You have not visited the question yet.",
                    ),

                    _statusRow(
                      QuestionStatus.notAnswered,
                      "You have not answered the question.",
                    ),

                    _statusRow(
                      QuestionStatus.answered,
                      "You have answered the question.",
                    ),

                    _statusRow(
                      QuestionStatus.markedForReview,
                      "You have NOT answered but marked for review.",
                    ),

                    _statusRow(
                      QuestionStatus.answeredAndMarked,
                      "You have answered and marked for review.",
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "The Marked for Review status simply acts as a reminder that you have set to look at the question again. If an answer is selected for a question that is Marked for Review, the answer will be considered in the final evaluation.",
                      style: TextStyle(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ================= NAVIGATION =================
                    _sectionTitle("Navigating to a question:"),

                    const SizedBox(height: 12),

                    _bulletText(
                        "4. To select a question to answer, you can do one of the following:"),

                    _subBulletText(
                        "a. Click on the question number on the question palette at the right of your screen to go to that numbered question directly. Note that using this option does NOT save your answer to the current question."),

                    _subBulletText(
                        "b. Click on Save and Next to save answer to current question and to go to the next question in sequence."),

                    _subBulletText(
                        "c. Click on Mark for Review and Next to save answer to current question, mark it for review, and to go to the next question in sequence."),

                    _bulletText(
                        "5. You can view the entire paper by clicking on the Question Paper button."),

                    const SizedBox(height: 28),

                    // ================= ANSWERING =================
                    _sectionTitle("Answering questions:"),

                    const SizedBox(height: 12),

                    _bulletText(
                        "6. For multiple choice type question:"),

                    _subBulletText(
                        "a. To select your answer, click on one of the option buttons."),
                    _subBulletText(
                        "b. To change your answer, click the another desired option button"),
                    _subBulletText(
                        "c. To save your answer, you MUST click on Save & Next"),
                    _subBulletText(
                        "d. To deselect a chosen answer, click on the chosen option again or click on the Clear Response button."),
                    _subBulletText(
                        "e. To mark a question for review click on Mark for Review & Next."),

                    const SizedBox(height: 16),

                    const Text(
                      "7. To change an answer to a question, first select the question and then click on the new answer option followed by a click on the Save & Next button.",
                      style: TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "8. Questions that are saved or marked for review after answering will ONLY be considered for evaluation.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= BUTTON =================
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  backgroundColor: const Color(0xFF4F46E5),
                ),
                onPressed: () {
                  if(startTest) {
                    controller.onAccept();
                  } else {
                    Get.close(1);
                  }
                },
                child:  Text(
                  startTest ? "Start Test" : "Close",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _subBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // Widget _statusRow(Color color, String text) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 28,
  //           height: 28,
  //           decoration: BoxDecoration(
  //             color: color,
  //             borderRadius: BorderRadius.circular(6),
  //           ),
  //           alignment: Alignment.center,
  //           child: const Text(
  //             "1",
  //             style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Text(
  //             text,
  //             style: const TextStyle(fontSize: 14),
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }
  Widget _statusRow(
      QuestionStatus status,
      String text,
      ) {
    Color bgColor;
    Color textColor = Colors.white;
    bool showTick = false;
    BorderRadius borderRadius = BorderRadius.circular(4);

    switch (status) {
      case QuestionStatus.notVisited:
        bgColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF111827);
        break;

      case QuestionStatus.notAnswered:
        bgColor = const Color(0xFFDC2626);
        borderRadius = const BorderRadius.vertical(
          bottom: Radius.circular(10),
        );
        break;

      case QuestionStatus.answered:
        bgColor = const Color(0xFF16A34A);
        borderRadius = const BorderRadius.vertical(
          top: Radius.circular(10),
        );
        break;

      case QuestionStatus.markedForReview:
        bgColor = const Color(0xFF7C3AED);
        borderRadius = BorderRadius.circular(12);
        break;

      case QuestionStatus.answeredAndMarked:
        bgColor = const Color(0xFF7C3AED);
        borderRadius = BorderRadius.circular(12);
        showTick = true;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width:  (status == QuestionStatus.answeredAndMarked ||
                    status == QuestionStatus.markedForReview)
                    ? 24
                    : 20,
                height: (status == QuestionStatus.answeredAndMarked ||
                    status == QuestionStatus.markedForReview)
                    ? 24
                    : 20,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: const Color(0xFF9CA3AF),
                    width: 1,
                  ),
                ),
              ),

              if (showTick)
                const Positioned(
                  top: -4,
                  right: -4,
                  child: Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Color(0xFF22C55E),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 500),
        color: Colors.white,
        padding: const EdgeInsets.all(AppConstants.contentPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button and title
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                ),
                const Expanded(
                  child: Text(
                    'eCM – ASSIGNMENT',
                    style: TextStyle(
                      fontSize: AppConstants.sectionTitleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Instructions
            Expanded(
              child: SingleChildScrollView(
                child: Obx(
                  () => Text(
                    controller.instructions.value,
                    style: const TextStyle(
                      fontSize: AppConstants.normalTextSize,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: controller.onDecline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('Decline'),
                ),
                ElevatedButton(
                  onPressed: controller.onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
