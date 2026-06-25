import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';

import '../../../core/routes/app_routes.dart';
import '../controllers/exam_analysis_controller.dart';

class ExamAnalysisView extends StatelessWidget {
  const ExamAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamAnalysisController>(
      // Controller is created by ExamAnalysisBinding registered on the route.
      // Don't double-init here — under MDM kiosk we've seen the dual
      // controller creation race with the test player teardown and crash.
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
                  return _buildError(controller);
                }
                if (controller.resultData.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Defensive: if the server returned no answers/sections yet
                // (result still processing), show a friendly message instead
                // of trying to render an empty chart that may crash on the
                // first frame.
                final hasData = controller.answers.isNotEmpty ||
                    controller.sectionResults.isNotEmpty;

                return Column(
                  children: [
                    _buildHeader(controller),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: hasData
                            ? Column(
                                children: [
                                  _buildPerformanceReport1(controller),
                                  const SizedBox(height: 24),
                                  _buildPerformanceChart(controller),
                                ],
                              )
                            : const Padding(
                                padding: EdgeInsets.only(top: 80),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_top,
                                          size: 64,
                                          color: Color(0xFF94A3B8)),
                                      SizedBox(height: 16),
                                      Text(
                                        'Your result is being processed.\nIt will appear here shortly.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

  Widget _buildError(ExamAnalysisController controller) {
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
              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(AppRoutes.discussion),
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: controller.retry,
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

  // Topbar — same look as Exam Result, but Rank/Time replaced with Exam Code.
  Widget _buildHeader(ExamAnalysisController controller) {
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
                onPressed: () async {
                  // await controller.unlockBeforeExit();
                  await Get.offAllNamed(AppRoutes.discussion);
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
            'Exam Analysis',
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
                  'Exam Code: ${controller.examCode}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
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

  // Same Performance Report 1 layout as Exam Result.
  Widget _buildPerformanceReport1(ExamAnalysisController controller) {
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
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Performance Report 1',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _headerRow(),
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
                    _dataRow(
                      name,
                      '${score.toStringAsFixed(1)} / ${sTotal.toStringAsFixed(1)}',
                      sCorrect.toString(),
                      '+${sPos.toStringAsFixed(1)}',
                      sWrong.toString(),
                      '-${sNeg.toStringAsFixed(1)}',
                    ),
                    Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  ],
                );
              }),
              _dataRow(
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

  Widget _headerRow() {
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

  Widget _dataRow(String subject, String score, String correct, String positive,
      String incorrect, String negative) {
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
          Expanded(flex: 2, child: Text(score, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFFD700)))),
          Expanded(flex: 2, child: Text(correct, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text(positive, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text(incorrect, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          Expanded(flex: 2, child: Text(negative, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }

  // ─── Performance Chart (donut + per-section bars) ────────────────────────
  Widget _buildPerformanceChart(ExamAnalysisController controller) {
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
                      _legend('Correct', const Color(0xFF4CAF50)),
                      const SizedBox(width: 20),
                      _legend('Wrong', const Color(0xFFE53935)),
                      const SizedBox(width: 20),
                      _legend('Skipped', const Color(0xFFFFA726)),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Per-section bars
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
                                  _bar(correct,
                                      subTotal == 0 ? 1 : subTotal,
                                      const Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  _bar(wrong,
                                      subTotal == 0 ? 1 : subTotal,
                                      const Color(0xFFEF4444)),
                                  const SizedBox(width: 4),
                                  _bar(skipped,
                                      subTotal == 0 ? 1 : subTotal,
                                      const Color(0xFFAB8F4A)),
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
                        _legend('Correct', const Color(0xFF10B981)),
                        const SizedBox(width: 24),
                        _legend('Wrong', const Color(0xFFEF4444)),
                        const SizedBox(width: 24),
                        _legend('Skipped', const Color(0xFFAB8F4A)),
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

  Widget _bar(int value, int total, Color color) {
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

  Widget _legend(String label, Color color) {
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
}

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

    int totalCorrect = 0, totalWrong = 0, totalSkipped = 0;
    for (var s in sections) {
      totalCorrect += (s['correct'] as num?)?.toInt() ?? 0;
      totalWrong += (s['wrong'] as num?)?.toInt() ?? 0;
      totalSkipped += (s['skipped'] as num?)?.toInt() ?? 0;
    }
    final totalQ = totalCorrect + totalWrong + totalSkipped;
    if (totalQ == 0) return;

    double startAngle = -math.pi / 2;
    if (totalCorrect > 0) {
      final angle = (totalCorrect / totalQ) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, angle, false,
          Paint()
            ..color = const Color(0xFF4CAF50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth);
      startAngle += angle;
    }
    if (totalWrong > 0) {
      final angle = (totalWrong / totalQ) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, angle, false,
          Paint()
            ..color = const Color(0xFFE53935)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth);
      startAngle += angle;
    }
    if (totalSkipped > 0) {
      final angle = (totalSkipped / totalQ) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, angle, false,
          Paint()
            ..color = const Color(0xFFFFA726)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
