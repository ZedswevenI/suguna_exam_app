import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';
import 'package:suguna_exam_app/data/services/sessions.dart';

import '../../../core/routes/app_routes.dart';
import '../controllers/exam_result_controller.dart';

class ExamResultView extends StatelessWidget {
  const ExamResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamResultController>(
      init: ExamResultController(),
      builder: (controller) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),
            body: SafeArea(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage.value.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Color(0xFFEF4444)),
                          const SizedBox(height: 16),
                          Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Get.offAllNamed(AppRoutes.discussion);
                                },
                                icon: const Icon(Icons.home),
                                label: const Text('Home'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: controller.retryLoadResult,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }
                if (controller.resultData.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    _buildDashboardHeader(controller),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildScoreOverview(controller),
                            const SizedBox(height: 24),
                            _buildPerformanceReport1(controller),
                            const SizedBox(height: 24),
                            _buildSectionPerformance(controller),
                            const SizedBox(height: 24),
                            _buildPerformanceChart(controller),
                            const SizedBox(height: 24),
                            _buildKeyMetrics(controller),
                            const SizedBox(height: 24),
                            _buildQuestionsSection(controller),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DASHBOARD HEADER
  // ============================================================
  Widget _buildDashboardHeader(ExamResultController controller) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Get.offAllNamed(AppRoutes.discussion);
                },
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Exam Result',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'ENo: ${controller.data['admissionNo'] ?? ''}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(width: 24),
                Text(
                  'Rank: ${controller.rank}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'Time: ${controller.formatDuration(controller.timeTakenMs)}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCORE OVERVIEW — Big score card
  // ============================================================
  Widget _buildScoreOverview(ExamResultController controller) {
    final percentage = controller.totalMarks > 0
        ? (controller.obtainedMarks / controller.totalMarks * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor(percentage),
            _getScoreColor(percentage).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(percentage).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 120,
            height: 120,
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
                  '${controller.obtainedMarks}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _getScoreColor(percentage),
                  ),
                ),
                Text(
                  '/ ${controller.totalMarks}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScoreBadge(
                      'Rank',
                      '#${controller.rank}',
                      Icons.emoji_events_rounded,
                    ),
                    const SizedBox(width: 16),
                    _buildScoreBadge(
                      'Percentile',
                      '${controller.percentile}%',
                      Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION PERFORMANCE TABLE
  // ============================================================
  // ============================================================
  // PERFORMANCE REPORT 1 — Subject | Score | Correct | +ve | Incorrect | -ve
  // ============================================================
  Widget _buildPerformanceReport1(ExamResultController controller) {
    final report = controller.getPerformanceReport();
    final subjects = report['subjects'] as List<Map<String, dynamic>>;
    final totalMarks = report['totalMarks'] as double;
    final correct = report['correct'] as int;
    final wrong = report['wrong'] as int;
    final positiveMarks = report['positiveMarks'] as double;
    final negativeMarks = report['negativeMarks'] as double;
    final totalScore = report['totalScore'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF009741),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Performance Report 1',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ).marginOnly(left: 16),
              const SizedBox(height: 8),

              // HEADER
              _buildReport1HeaderRow(),

              // SUBJECT ROWS
              ...subjects.map((subject) {
                final name = subject['subjectName'] as String;
                final score = subject['totalScore'] as double;
                final sCorrect = subject['correct'] as int;
                final sWrong = subject['wrong'] as int;
                final sPos = subject['positiveMarks'] as double;
                final sNeg = subject['negativeMarks'] as double;
                final sTotal = subject['totalMarks'] as double;

                return Column(
                  children: [
                    _buildReport1Row(
                      name,
                      '${score.toStringAsFixed(1)} / ${sTotal.toStringAsFixed(1)}',
                      sCorrect.toString(),
                      '+${sPos.toStringAsFixed(1)}',
                      sWrong.toString(),
                      '-${sNeg.toStringAsFixed(1)}',
                    ),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ],
                );
              }),

              // TOTAL ROW
              _buildReport1Row(
                'TOTAL',
                '${totalScore.toStringAsFixed(1)} / ${totalMarks.toStringAsFixed(1)}',
                correct.toString(),
                '+${positiveMarks.toStringAsFixed(1)}',
                wrong.toString(),
                '-${negativeMarks.toStringAsFixed(1)}',
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReport1HeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Subject', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text('Your score', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text('Answered correct', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text('Positive marks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text('Answered incorrect', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text('Negative marks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildReport1Row(
    String subject,
    String score,
    String correct,
    String positive,
    String incorrect,
    String negative,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFF22650B),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subject,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              score,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              correct,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              positive,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              incorrect,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              negative,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPerformance(ExamResultController controller) {
    final sections = controller.getSectionReport();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF009741),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Section-wise Performance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ).marginOnly(left: 16),
              const SizedBox(height: 8),

              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Section',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Score',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Correct',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Wrong',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Skipped',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Accuracy',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                  ],
                ),
              ),

              // Section rows
              ...sections.map((section) {
                return Column(
                  children: [
                    Container(
                      color: const Color(0xFF22650B),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                section['sectionName'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${(section['obtainedMarks'] as double).toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${section['correct']}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${section['wrong']}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${section['skipped']}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${(section['accuracy'] as double).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ],
                );
              }),

              // Total row
              _buildTotalRow(controller),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(ExamResultController controller) {
    final stats = controller.getOverallStats();
    return Container(
      color: const Color(0xFF22650B),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${controller.obtainedMarks} / ${controller.totalMarks}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${stats['correct']}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${stats['wrong']}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${stats['skipped']}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${(stats['percentage'] as double).toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KEY METRICS
  // ============================================================
  Widget _buildKeyMetrics(ExamResultController controller) {
    final stats = controller.getOverallStats();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricCard(
          "Total Questions",
          '${stats['total']}',
          const Color(0xFF3B82F6),
          Icons.quiz_outlined,
        ),
        const SizedBox(width: 18),
        _buildMetricCard(
          "Correct",
          '${stats['correct']}',
          const Color(0xFF10B981),
          Icons.check_circle_outline,
        ),
        const SizedBox(width: 18),
        _buildMetricCard(
          "Wrong",
          '${stats['wrong']}',
          const Color(0xFFEF4444),
          Icons.cancel_outlined,
        ),
        const SizedBox(width: 18),
        _buildMetricCard(
          "Accuracy",
          '${(stats['percentage'] as double).toStringAsFixed(0)}%',
          const Color(0xFFF59E0B),
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PERFORMANCE CHART
  // ============================================================
  Widget _buildPerformanceChart(ExamResultController controller) {
    final sections = controller.getSectionReport();
    final stats = controller.getOverallStats();
    final totalCorrect = stats['correct'] as int;
    final totalQs = stats['total'] as int;
    final pct = totalQs > 0 ? (totalCorrect / totalQs * 100) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Donut
              Column(
                children: [
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(300, 300),
                          painter: _SectionDonutPainter(sections: sections),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const Text(
                              'Overall',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Correct', const Color(0xFF4CAF50)),
                      const SizedBox(width: 20),
                      _buildLegendItem('Wrong', const Color(0xFFE53935)),
                      const SizedBox(width: 20),
                      _buildLegendItem('Skipped', const Color(0xFFFFA726)),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // Bar chart per section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: sections.map((section) {
                        final name = section['sectionName'] as String;
                        final correct = section['correct'] as int;
                        final wrong = section['wrong'] as int;
                        final skipped = section['skipped'] as int;
                        final subTotal = correct + wrong + skipped;

                        return Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildChartBar(correct,
                                      subTotal == 0 ? 1 : subTotal, const Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  _buildChartBar(wrong,
                                      subTotal == 0 ? 1 : subTotal, const Color(0xFFEF4444)),
                                  const SizedBox(width: 4),
                                  _buildChartBar(skipped,
                                      subTotal == 0 ? 1 : subTotal, const Color(0xFFAB8F4A)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Correct', const Color(0xFF10B981)),
                        const SizedBox(width: 24),
                        _buildLegendItem('Wrong', const Color(0xFFEF4444)),
                        const SizedBox(width: 24),
                        _buildLegendItem('Skipped', const Color(0xFFAB8F4A)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(int value, int total, Color color) {
    final percentage = total == 0 ? 0.0 : (value / total) * 100;
    return Column(
      children: [
        Container(
          width: 50,
          height: percentage * 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUESTIONS TABLE
  // ============================================================
  Widget _buildQuestionsSection(ExamResultController controller) {
    final answers = controller.answers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF009741),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: const Text(
            'Question-wise Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF009741),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text('Q', style: TextStyle(color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text('Section', style: TextStyle(color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child:
                          Text('Type', style: TextStyle(color: Colors.white)))),
              Expanded(
                  flex: 2,
                  child: Text('You Marked',
                      style: TextStyle(color: Colors.white))),
              Expanded(
                  flex: 1,
                  child: Text('Time',
                      style: TextStyle(color: Colors.white))),
              Expanded(
                  flex: 2,
                  child: Text('Marks',
                      style: TextStyle(color: Colors.white))),
              Expanded(
                  flex: 1,
                  child: Text('View', style: TextStyle(color: Colors.white))),
            ],
          ),
        ),

        // Question rows
        ...answers.asMap().entries.map((entry) {
          final index = entry.key;
          final answer = entry.value;
          final isCorrect = answer['isCorrect'] == true;
          final isSkipped = answer['isSkipped'] == true;
          final marks = (answer['marksAwarded'] as num?)?.toDouble() ?? 0.0;
          final userAnswer = controller.getUserAnswerDisplay(answer);
          final questionType = answer['questionType'] ?? '';
          final sectionName =
              controller.getSectionName(answer['sectionId'] ?? '');
          final timeTakenMs = (answer['timeTaken'] as num?)?.toInt() ?? 0;
          final timeTakenSec = timeTakenMs ~/ 1000;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF22650B),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    sectionName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      controller.getQuestionTypeName(questionType),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    userAnswer,
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    timeTakenSec >= 60
                        ? '${timeTakenSec ~/ 60}m ${timeTakenSec % 60}s'
                        : '${timeTakenSec}s',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    marks > 0
                        ? '+${marks.toStringAsFixed(1)}'
                        : marks.toStringAsFixed(1),
                    style: TextStyle(
                      color: marks > 0
                          ? const Color(0xFF10B981)
                          : marks < 0
                              ? const Color(0xFFEF4444)
                              : Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      controller.goToReviewQuestion(index);
                      Get.toNamed(AppRoutes.examQuestionReview);
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF10B981);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ============================================================
// DONUT PAINTER for section breakdown
// ============================================================
class _SectionDonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> sections;

  _SectionDonutPainter({required this.sections});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.18;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    // Aggregate totals across all sections
    int totalCorrect = 0, totalWrong = 0, totalSkipped = 0;
    for (var s in sections) {
      totalCorrect += (s['correct'] as num?)?.toInt() ?? 0;
      totalWrong += (s['wrong'] as num?)?.toInt() ?? 0;
      totalSkipped += (s['skipped'] as num?)?.toInt() ?? 0;
    }

    final totalQ = totalCorrect + totalWrong + totalSkipped;
    if (totalQ == 0) return;

    double startAngle = -math.pi / 2;

    // Correct arc (green)
    if (totalCorrect > 0) {
      final angle = (totalCorrect / totalQ) * 2 * math.pi;
      final paint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, angle, false, paint);
      startAngle += angle;
    }

    // Wrong arc (red)
    if (totalWrong > 0) {
      final angle = (totalWrong / totalQ) * 2 * math.pi;
      final paint = Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, angle, false, paint);
      startAngle += angle;
    }

    // Skipped arc (amber)
    if (totalSkipped > 0) {
      final angle = (totalSkipped / totalQ) * 2 * math.pi;
      final paint = Paint()
        ..color = const Color(0xFFFFA726)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, angle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
