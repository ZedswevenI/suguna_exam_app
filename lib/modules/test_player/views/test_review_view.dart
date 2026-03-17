import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';
import 'package:suguna_exam_app/core/widgets/app_layout.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/sessions.dart';
import '../controllers/assignment_questions_controller.dart';
import '../controllers/test_player_controller.dart';
import '../controllers/test_player_parser.dart';

// ============================================================
// TEST RESULT VIEW
// ============================================================

class TestResultView extends StatelessWidget {
  const TestResultView({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: AssignmentQuestionsController(),
        builder: (controller){
      return AppLayout(
        selectedRoute: '',
        showBackButton: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: Column(
              children: [
                // _buildHeader(controller),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildQuestionReview(controller),
                      ),
                      if(controller.categories.isNotEmpty)
                      _buildSummaryPanel(controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });

  }

  // ============================================================
  // HEADER WITH SCORE
  // ============================================================

  Widget _buildHeader(TestPlayerController controller) {
    return Obx(() {
      final stats = controller.getTestStatistics();
      final percentage = stats['percentage'] as double;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Score Circle
            // Container(
            //   width: 100,
            //   height: 100,
            //   decoration: BoxDecoration(
            //     shape: BoxShape.circle,
            //     color: Colors.white,
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.1),
            //         blurRadius: 10,
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Text(
            //         '${percentage.toStringAsFixed(0)}%',
            //         style: TextStyle(
            //           fontSize: 28,
            //           fontWeight: FontWeight.w900,
            //           color: _getScoreColor(percentage),
            //         ),
            //       ),
            //       const Text(
            //         'Score',
            //         style: TextStyle(
            //           fontSize: 12,
            //           color: Colors.grey,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // const SizedBox(width: 32),
            // Stats
            Expanded(
              child: Row(
                children: [
                  _buildStatCard(
                    'Correct',
                    stats['correct'].toString(),
                    const Color(0xFF10B981),
                    Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Wrong',
                    stats['wrong'].toString(),
                    const Color(0xFFEF4444),
                    Icons.cancel_rounded,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Skipped',
                    stats['skipped'].toString(),
                    const Color(0xFF6B7280),
                    Icons.remove_circle_outline_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 32),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                   },
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Exit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUESTION REVIEW PANEL
  // ============================================================

  Widget _buildQuestionReview(AssignmentQuestionsController controller) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildQuestionNavigator(controller),
          Expanded(
            child: Obx(() {
              final question = controller.currentReviewQuestion;
              return _buildQuestionContent(controller,question);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigator(AssignmentQuestionsController controller) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Navigation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              final allQuestions = controller.getAllQuestions();
              final currentIndex = controller.reviewIndex.value;
              print("All ques  s ${controller.reviewIndex.value}");

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allQuestions.length,
                itemBuilder: (_, index) {
                  final question = allQuestions[index];
                  final isCorrect = controller.isQuestionCorrect(question);
                  final isSkipped = controller.isQuestionSkipped(question);
                  final isCurrent = currentIndex == index;

                  Color bgColor;
                  IconData? icon;

                  if (isSkipped) {
                    bgColor = const Color(0xFF6B7280);
                    icon = Icons.remove_rounded;
                  } else if (isCorrect) {
                    bgColor = const Color(0xFF10B981);
                    icon = Icons.check_rounded;
                  } else {

                    bgColor = const Color(0xFFEF4444);
                    icon = Icons.close_rounded;
                  }

                  return GestureDetector(
                    onTap: () => controller.goToReviewQuestion(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent
                            ? Border.all(color: AppColors.textPrimary, width: 3)
                            : null,
                        boxShadow: isCurrent
                            ? [
                          BoxShadow(
                            color: bgColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (icon != null)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Icon(
                                icon,
                                size: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(AssignmentQuestionsController controller, Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number & Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Question ${question.number}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getQuestionTypeName(question.type),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showReportQuestionDialog(
                          TestPlayerController.to,
                          question.questionId,
                          question.number,
                        );
                        },
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: (){
                      TestPlayerController.to.toggleBookmark(question.questionId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: TestPlayerController.to.isBookmarked(question.questionId)
                            ? const Color(0xFFEDE9FE)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TestPlayerController.to.isBookmarked(question.questionId) ? Icons.bookmark : Icons.bookmark_border,
                            size: 16,
                            color: TestPlayerController.to.isBookmarked(question.questionId)
                                ? const Color(0xFF7C3AED)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TestPlayerController.to.isBookmarked(question.questionId) ? "Bookmarked" : "Bookmark",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TestPlayerController.to.isBookmarked(question.questionId)
                                  ? const Color(0xFF7C3AED)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  )
                ],
              ),

              // IconButton(
              //   icon: Icon(
              //     controller.isBookmarked(question.questionId)
              //         ? Icons.bookmark
              //         : Icons.bookmark_border,
              //     color: controller.isBookmarked(question.questionId)
              //         ? const Color(0xFF4F46E5)
              //         : Colors.grey,
              //   ),
              //   onPressed: () => controller.toggleBookmark(question.questionId),
              // ),
            ],
          ),
          const SizedBox(height: 24),

          // // Question Text
          // MathAndHtmlRenderer(
          //   content: question.questionHtml ?? question.text,
          //   fontSize: 16,
          //   fontWeight: FontWeight.w500,
          // ),
          //
          // const SizedBox(height: 32),

          // Options/Answer Display
          if (question.type == QuestionType.mcqSingle ||
              question.type == QuestionType.mcqMultiple)
            _buildMCQSingleReview(question,controller),

          if (question.type == QuestionType.numerical)...[
             texText(question.questionHtml ?? '',fontSize: 14),
            SizedBox(height: 15,),
            _buildNumericalReview(controller, question),
          ],
          if (question.type == QuestionType.textType ||
              question.type == QuestionType.subjective)...[
            texText(question.questionHtml ?? '',fontSize: 14),
            SizedBox(height: 15,),
            _buildTextReview(controller, question),
          ]
        ],
      ),
    );
  }

  Widget texText(
      String text, {
        required double fontSize,
        String extraCss = '',
      }) {
    return TeXView(
      style: const TeXViewStyle(
        backgroundColor: Colors.transparent,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewColumn(
        children: [
          TeXViewDocument(
            text,
            style: TeXViewStyle.fromCSS(
              '''
            font-size:${fontSize}px;
            $extraCss
            ''',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMCQSingleReview(
      Question question,
      AssignmentQuestionsController controller,
      ) {
    return TeXView(
      key: UniqueKey(),
      style: const TeXViewStyle(
        backgroundColor: Colors.transparent,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewColumn(
        children: [
          TeXViewDocument(
            question.questionHtml ?? question.text,
            style: TeXViewStyle.fromCSS(
              'font-size:14px; margin-bottom:16px;',
            ),
          ),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final label = String.fromCharCode(65 + index);
            final isSelected = question.selectedAnswer == label;
            final isCorrect = controller.isOptionCorrect(question, label);
            final isUserWrong = isSelected && !isCorrect;
            // -------- Styling --------
            String border;
            String background;

            if (isCorrect) {
              border = '2px solid #10B981';
              background = '#ECFDF5';
            } else if (isUserWrong) {
              border = '2px solid #EF4444';
              background = '#FEE2E2';
            } else {
              border = '1px solid #E5E7EB';
              background = 'transparent';
            }

            return TeXViewDocument(
              '''
<div style="
  padding:12px;
  margin-bottom:12px;
  border-radius:10px;
  border:$border;
  background-color:$background;
">

  <div style="display:flex; align-items:flex-start; gap:12px;">

    <!-- LABEL CIRCLE -->
    <div style="
      width:26px;
      height:26px;
      border-radius:50%;
      display:flex;
      align-items:center;
      justify-content:center;
      font-size:11px;
      font-weight:700;
      color:${isSelected ? '#ffffff' : '#374151'};
      background-color:${
                  isCorrect
                      ? '#10B981'
                      : isUserWrong
                      ? '#EF4444'
                      : isSelected
                      ? '#2563EB'
                      : '#D1D5DB'
              };
      flex-shrink:0;
    ">
      $label
    </div>

    <!-- OPTION TEXT -->
    <div style="
      flex:1;
      font-size:14px;
      font-weight:${isSelected ? '600' : '500'};
    ">
      $option
    </div>

  </div>

  ${isUserWrong ? '''
  <div style="
    margin-top:6px;
    font-size:12px;
    font-weight:600;
    color:#EF4444;
  ">
    ❌ Your Answer
  </div>
  ''' : ''}

  ${isCorrect ? '''
  <div style="
    margin-top:6px;
    font-size:12px;
    font-weight:600;
    color:#10B981;
  ">
    ✔ Correct Answer
  </div>
  ''' : ''}

</div>
''',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNumericalReview(AssignmentQuestionsController controller, Question question) {
    final userAnswer = question.numericalAnswer?.toString() ?? 'Not Answered';
    final correctAnswer = controller.getCorrectAnswer(question);
    final isCorrect = controller.isQuestionCorrect(question);

    return Column(
      children: [
        _buildAnswerCard('Your Answer', userAnswer, isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444), false),
        const SizedBox(height: 16),
        _buildAnswerCard('Correct Answer', correctAnswer, const Color(0xFF10B981), true),
      ],
    );
  }

  Widget _buildTextReview(AssignmentQuestionsController controller, Question question) {
    final userAnswer = question.textAnswer ?? 'Not Answered';
    final correctAnswer = controller.getCorrectAnswer(question);

    return Column(
      children: [
        _buildAnswerCard('Your Answer', userAnswer, const Color(0xFF6366F1), false),
        const SizedBox(height: 16),
        _buildAnswerCard('Suggested Answer', correctAnswer, const Color(0xFF10B981), true),
      ],
    );
  }

  Widget _buildAnswerCard(String label, String answer, Color color, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.edit_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(AssignmentQuestionsController controller) {
    return Container(
      width: 350,
      margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final question = controller.currentReviewQuestion;
        final isCorrect = controller.isQuestionCorrect(question);
        final stats = controller.getTestStatistics();
        final report = controller.getPerformanceReport();

        // final percentage = stats['percentage'] as double;
        final percentage = report["totalScore"];

        return Column(
          children: [
            // Result Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCorrect
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCorrect ? 'Correct!' : 'Incorrect',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryItem('Question Type', _getQuestionTypeName(question.type)),
                    _buildSummaryItem('Question Number', '${question.number}'),
                    // _buildSummaryItem('Difficulty', 'Medium'),
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFF8F9FC),
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       const Text(
                    //         'Your score',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w600,
                    //           color: Colors.grey,
                    //         ),
                    //       ),
                    //       Text(
                    //         isCorrect ? '+1' : '0',
                    //         style: TextStyle(
                    //           fontSize: 20,
                    //           fontWeight: FontWeight.w900,
                    //           color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // const Text(
                    //   'Your Performance',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w700,
                    //     color: AppColors.textPrimary,
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    //
                    // _buildPerformanceBar('Correct', stats['correct'], const Color(0xFF10B981)),
                    // _buildPerformanceBar('Wrong', stats['wrong'], const Color(0xFFEF4444)),
                    // _buildPerformanceBar('Skipped', stats['skipped'], const Color(0xFF6B7280)),

                    // const SizedBox(height: 24),
                    Center(
                      child: _buildDonutChart(
                        percentage: percentage,
                        correct: stats['correct'] as int,
                        wrong: (stats['wrong'] as int) + stats['skipped'] as int,
                        skipped: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 10, // Assuming max 10 questions
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF10B981);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getQuestionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.mcqSingle:
        return 'MCQ Single';
      case QuestionType.mcqMultiple:
        return 'MCQ Multiple';
      case QuestionType.numerical:
        return 'Numerical';
      case QuestionType.textType:
        return 'Short Answer';
      case QuestionType.subjective:
        return 'Subjective';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.matchTheFollowing:
        return 'Match';
      default:
        return 'MCQ';
    }
  }

  void _showSubmitConfirmation(TestPlayerController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Results'),
        content: const Text('Are you sure you want to submit your test results to the server?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.submitTestResults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart({
    required double percentage,
    required int correct,
    required int wrong,
    required int skipped,
  }) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Donut Chart
          CustomPaint(
            size: const Size(200, 200),
            painter: DonutChartPainter(
              correct: correct,
              wrong: wrong,
              skipped: skipped,
            ),
          ),

          // Center Content
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  percentage.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRetestConfirmation(TestPlayerController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.refresh_rounded, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('Retest?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to retake this test? All your current answers will be cleared and the timer will restart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.until((route) => route.settings.name == AppRoutes.assignmentInstructions);
              Get.toNamed(AppRoutes.assignmentInstructions);
              Session.instance.isRetest = true;
              // controller.takeRetest();
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Restart Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportQuestionDialog(
      TestPlayerController controller,
      String questionId,
      int questionNumber,
      ) {
    final TextEditingController commentController = TextEditingController();
    String selectedIssue = "Incorrect Answer";

    final List<String> issueTypes = [
      "Incorrect Answer",
      "Typo / Spelling Mistake",
      "Question Not Clear",
      "Options Missing / Incorrect",
      "Duplicate Question",
      "Other",
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 500, // wider dialog
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          color: Colors.red, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        "Report Question $questionNumber",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// ISSUE TYPE DROPDOWN
                  const Text(
                    "Type of Issue",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedIssue,
                    items: issueTypes
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedIssue = value!;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// COMMENT BOX
                  const Text(
                    "Describe the issue",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    maxLength: 250,
                    decoration: InputDecoration(
                      hintText: "Write your comment here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ACTION BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (commentController.text.trim().isEmpty) {
                            Get.snackbar(
                              "Error",
                              "Please enter a comment",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          Get.back();


                          controller.reportQuestion(
                            questionId: questionId,
                            issueType: selectedIssue,
                            comment: commentController.text.trim(),
                          );
                          Get.snackbar(
                            "Reported",
                            "Question reported successfully",
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );


                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text("Submit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final int correct;
  final int wrong;
  final int skipped;

  DonutChartPainter({
    required this.correct,
    required this.wrong,
    required this.skipped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 35.0;

    final total = correct + wrong + skipped;
    if (total == 0) return;

    // Calculate angles
    final correctAngle = (correct / total) * 2 * math.pi;
    final wrongAngle = (wrong / total) * 2 * math.pi;
    final skippedAngle = (skipped / total) * 2 * math.pi;

    // Paint for each segment
    final correctPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final wrongPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final skippedPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Starting angle (top of circle)
    var startAngle = -math.pi / 2;

    // Draw correct segment
    if (correct > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        correctAngle,
        false,
        correctPaint,
      );
      startAngle += correctAngle;
    }

    // Draw wrong segment
    if (wrong > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        wrongAngle,
        false,
        wrongPaint,
      );
      startAngle += wrongAngle;
    }

    // Draw skipped segment
    if (skipped > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        skippedAngle,
        false,
        skippedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.correct != correct ||
        oldDelegate.wrong != wrong ||
        oldDelegate.skipped != skipped;
  }

}