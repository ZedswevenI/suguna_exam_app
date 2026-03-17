import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';
import 'package:suguna_exam_app/core/utils/responsive_helper.dart';
import 'package:suguna_exam_app/modules/question_review/controllers/question_review_controller.dart';

class QuestionReviewView extends GetView<QuestionReviewController> {
  const QuestionReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Question Review',
          style: TextStyle(color: AppColors.textWhite),
        ),
        elevation: 0,
      ),
      body: LayoutBuilder(
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
    return Column(
      children: [
        // Top Question Numbers Strip
        Container(
          height: 60,
          padding: ResponsiveHelper.getHorizontalPadding(context),
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getMaxContentWidth(context),
            ),
            child: Obx(() {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.questions.length,
                itemBuilder: (context, index) {
                  final isCurrent =
                      controller.currentQuestionIndex.value == index;
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () => controller.goToQuestion(index + 1),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: AppConstants.smallLabelSize,
                              color: isCurrent
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        // Question Content
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getMaxContentWidth(context),
            ),
            child: Row(
              children: [
                // Question + Options
                Expanded(child: _buildQuestionContent(context)),
                // Right Side - Bookmark
                Container(
                  width: 60,
                  padding: ResponsiveHelper.getPadding(context),
                  child: Icon(
                    Icons.bookmark_border,
                    size: ResponsiveHelper.getIconSize(context, baseSize: 32),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom Actions
        Container(
          height: 60,
          padding: ResponsiveHelper.getHorizontalPadding(context),
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getMaxContentWidth(context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: controller.goBack,
                  child: const Text('Go Back'),
                ),
                SizedBox(width: ResponsiveHelper.getSpacing(context)),
                TextButton(
                  onPressed: controller.exit,
                  child: const Text('Exit'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Top Question Numbers Strip
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.contentPadding,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Obx(() {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.questions.length,
              itemBuilder: (context, index) {
                final isCurrent =
                    controller.currentQuestionIndex.value == index;
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => controller.goToQuestion(index + 1),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: AppConstants.smallLabelSize,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        // Question Content
        Expanded(
          child: Row(
            children: [
              // Question + Options
              Expanded(child: _buildQuestionContent(context)),
              // Right Side - Bookmark
              Container(
                width: 60,
                padding: const EdgeInsets.all(AppConstants.contentPadding),
                child: const Icon(
                  Icons.bookmark_border,
                  size: 32,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Bottom Actions
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.contentPadding,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: controller.goBack,
                child: const Text('Go Back'),
              ),
              const SizedBox(width: 16),
              TextButton(onPressed: controller.exit, child: const Text('Exit')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionContent(BuildContext context) {
    return Obx(() {
      final question = controller.getCurrentQuestion();
      if (question == null) {
        return const Center(child: Text('No question'));
      }

      return SingleChildScrollView(
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${question.questionNumber}',
              style: const TextStyle(
                fontSize: AppConstants.sectionTitleSize,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: AppConstants.normalTextSize,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isCorrect = index == question.correctAnswerIndex;
              final isUserAnswer = question.userAnswerIndex == index;

              Color getBorderColor() {
                if (isCorrect) return AppColors.success;
                if (isUserAnswer && !isCorrect) return AppColors.error;
                return AppColors.border;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: getBorderColor(),
                      width: isCorrect || isUserAnswer ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: getBorderColor(), width: 2),
                          color: isCorrect || isUserAnswer
                              ? getBorderColor()
                              : Colors.transparent,
                        ),
                        child: isCorrect || isUserAnswer
                            ? Icon(
                                isCorrect ? Icons.check : Icons.close,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: AppConstants.normalTextSize,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isCorrect)
                              const Text(
                                '(Correct)',
                                style: TextStyle(
                                  fontSize: AppConstants.smallLabelSize,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (isUserAnswer && !isCorrect)
                              const Text(
                                '(Your Answer)',
                                style: TextStyle(
                                  fontSize: AppConstants.smallLabelSize,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
