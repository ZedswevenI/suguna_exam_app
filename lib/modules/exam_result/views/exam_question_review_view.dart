import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';

import '../controllers/exam_result_controller.dart';

class ExamQuestionReviewView extends StatelessWidget {
  const ExamQuestionReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamResultController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                // Section tabs
                _buildSectionTabs(controller),
                // Subject + Language row
                _buildSubjectRow(controller),
                // Scrollable questions list
                Expanded(
                  child: Obx(() {
                    final questions = controller.filteredAnswers;
                    if (questions.isEmpty) {
                      return const Center(
                        child: Text(
                          'No questions in this section',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TeXView(
                        key: ValueKey('section_${controller.selectedSectionIndex.value}'),
                        style: const TeXViewStyle(
                          backgroundColor: Colors.white,
                          padding: TeXViewPadding.all(0),
                        ),
                        loadingWidgetBuilder: (_) => const Center(child: CircularProgressIndicator()),
                        child: TeXViewColumn(
                          children: [
                            ...questions.asMap().entries.map((entry) {
                              return TeXViewDocument(
                                _buildQuestionHtml(controller, entry.value, entry.key),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Text(
            'Solutions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TABS (PHYSICS | CHEMISTRY | MATHEMATICS)
  // ============================================================
  Widget _buildSectionTabs(ExamResultController controller) {
    return Obx(() {
      final sections = controller.sectionNames;
      final selected = controller.selectedSectionIndex.value;

      return Container(
        color: AppColors.primaryDark.withOpacity(0.9),
        child: Row(
          children: sections.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            final isSelected = index == selected;

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectSection(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ============================================================
  // SUBJECT + LANGUAGE ROW
  // ============================================================
  Widget _buildSubjectRow(ExamResultController controller) {
    return Obx(() {
      final sectionName = controller.selectedSectionIndex.value <
              controller.sectionNames.length
          ? controller.sectionNames[controller.selectedSectionIndex.value]
          : '';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Language',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'English',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // Build HTML string for a single question (rendered inside one TeXView)
  // ============================================================
  String _buildQuestionHtml(
      ExamResultController controller, Map<String, dynamic> answer, int index) {
    final isCorrect = answer['isCorrect'] == true;
    final isSkipped = answer['isSkipped'] == true;
    final marksAwarded = (answer['marksAwarded'] as num?)?.toDouble() ?? 0.0;
    final positiveMarks = answer['positiveMarks'] ?? 0;
    final negativeMarks = answer['negativeMarks'] ?? 0;
    final timeTakenMs = (answer['timeTaken'] as int?) ?? 0;
    final timeSec = timeTakenMs ~/ 1000;
    final questionType = answer['questionType'] ?? '';
    final questionHtml = answer['questionHtml'] ?? '';
    final options = List<Map<String, dynamic>>.from(answer['questionOptions'] ?? []);
    // Backend may use any of: solutionHtml, solutionText, solution, or nest it
    // under a `question` object — accept all common shapes.
    dynamic _firstNonEmpty(List<dynamic> values) {
      for (final v in values) {
        if (v != null && v.toString().trim().isNotEmpty) return v;
      }
      return null;
    }

    final solutionHtml = _firstNonEmpty([
      answer['solutionHtml'],
      answer['solutionText'],
      answer['solution'],
      (answer['question'] is Map) ? answer['question']['solutionHtml'] : null,
      (answer['question'] is Map) ? answer['question']['solutionText'] : null,
      (answer['question'] is Map) ? answer['question']['solution'] : null,
    ]);
    final userAnswer = answer['answerRaw']?.toString() ?? '';

    String statusText;
    String statusColor;

    if (isSkipped) {
      statusText = 'Skipped, You Scored 0';
      statusColor = '#9CA3AF';
    } else if (isCorrect) {
      statusText = 'Your answer is correct, You Scored ${marksAwarded.toStringAsFixed(0)}';
      statusColor = '#10B981';
    } else {
      statusText = 'Your answer is incorrect, You Scored ${marksAwarded.toStringAsFixed(0)}';
      statusColor = '#EF4444';
    }

    final buf = StringBuffer();

    // Question card container
    buf.write('''
<div style="border:1px solid #E5E7EB; border-radius:8px; margin-bottom:16px; background:#fff;">
  <!-- Info bar -->
  <div style="padding:10px 14px; background:#F9FAFB; border-bottom:1px solid #E5E7EB; border-radius:8px 8px 0 0; display:flex; align-items:center; flex-wrap:wrap; gap:8px;">
    <span style="font-weight:700; font-size:13px;">Question. ${index + 1}</span>
    <span style="color:$statusColor; font-size:12px; font-weight:500;">$statusText</span>
    <span style="background:rgba(59,130,246,0.1); padding:2px 8px; border-radius:4px; font-size:11px; font-weight:600; color:#3B82F6;">+$positiveMarks, -$negativeMarks</span>
    <span style="font-size:11px; color:#6B7280;">⏱ ${timeSec} Sec</span>
  </div>
  <!-- Question content -->
  <div style="padding:14px;">
''');

    // Question text
    if (questionHtml.toString().trim().isNotEmpty) {
      buf.write('<div style="font-size:14px; line-height:1.6; margin-bottom:16px;">$questionHtml</div>');
    }

    // MCQ options (single / multiple / single dropdown / multi dropdown)
    if (questionType == 'mcq_single' ||
        questionType == 'mcq_multiple' ||
        questionType == 'single_dropdown' ||
        questionType == 'dropdown' ||
        questionType == 'multi_dropdown') {
      final selectedLabels = userAnswer.isEmpty
          ? <String>{}
          : userAnswer.toUpperCase().split(';').where((s) => s.isNotEmpty).toSet();
      for (int i = 0; i < options.length; i++) {
        final option = options[i];
        final key = option['key'] ?? String.fromCharCode(65 + i);
        final label = key.toString();
        final optionHtml = option['textHtml'] ?? '';
        final isOptionCorrect = option['isCorrect'] == true;
        final isSelected = selectedLabels.contains(label.toUpperCase());
        final isUserWrong = isSelected && !isOptionCorrect;

        String border, background;
        if (isOptionCorrect) {
          border = '2px solid #10B981';
          background = '#ECFDF5';
        } else if (isUserWrong) {
          border = '2px solid #EF4444';
          background = '#FEE2E2';
        } else {
          border = '1px solid #E5E7EB';
          background = 'transparent';
        }

        final circleBg = isOptionCorrect ? '#10B981' : isUserWrong ? '#EF4444' : isSelected ? '#2563EB' : '#D1D5DB';
        final circleColor = isSelected || isOptionCorrect || isUserWrong ? '#ffffff' : '#374151';

        buf.write('''
<div style="padding:12px; margin-bottom:10px; border-radius:10px; border:$border; background-color:$background;">
  <div style="display:flex; align-items:flex-start; gap:12px;">
    <div style="width:26px; height:26px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:11px; font-weight:700; color:$circleColor; background-color:$circleBg; flex-shrink:0;">$label</div>
    <div style="flex:1; font-size:14px; font-weight:${isSelected ? '600' : '500'};">$optionHtml</div>
  </div>
  ${isUserWrong ? '<div style="margin-top:6px; font-size:12px; font-weight:600; color:#EF4444;">Your Answer</div>' : ''}
  ${isOptionCorrect ? '<div style="margin-top:6px; font-size:12px; font-weight:600; color:#10B981;">Correct Answer</div>' : ''}
</div>
''');
      }
    }

    // Numerical / Integer
    if (questionType == 'numeric' || questionType == 'integer' || questionType == 'numerical') {
      final correctAnswer = answer['correctAnswer']?.toString() ?? '';
      final numericMin = answer['numericMin'];
      final numericMax = answer['numericMax'];
      String correctDisplay = correctAnswer;
      if (numericMin != null && numericMax != null) {
        correctDisplay = 'Range: $numericMin - $numericMax';
      }
      final userBorder = isCorrect ? '#10B981' : '#EF4444';
      final userBg = isCorrect ? '#ECFDF5' : '#FEE2E2';
      final displayAnswer = isSkipped ? 'Skipped' : userAnswer;

      buf.write('''
<div style="padding:12px; border-radius:8px; border:2px solid $userBorder; background:$userBg; margin-bottom:8px;">
  <span style="font-weight:600; color:$userBorder;">${isCorrect ? '✔' : '✘'} Your Answer: $displayAnswer</span>
</div>
<div style="padding:12px; border-radius:8px; border:2px solid #10B981; background:#ECFDF5;">
  <span style="font-weight:600; color:#10B981;">✔ Correct Answer: $correctDisplay</span>
</div>
''');
    }

    // Short answer (text input)
    if (questionType == 'short_answer') {
      final correctAnswer = answer['correctAnswer']?.toString() ?? '';
      final userBorder = isCorrect ? '#10B981' : '#EF4444';
      final userBg = isCorrect ? '#ECFDF5' : '#FEE2E2';
      final displayAnswer = isSkipped || userAnswer.isEmpty ? 'Skipped' : userAnswer;

      buf.write('''
<div style="padding:12px; border-radius:8px; border:2px solid $userBorder; background:$userBg; margin-bottom:8px;">
  <span style="font-weight:600; color:$userBorder;">${isCorrect ? '✔' : '✘'} Your Answer: $displayAnswer</span>
</div>
<div style="padding:12px; border-radius:8px; border:2px solid #10B981; background:#ECFDF5;">
  <span style="font-weight:600; color:#10B981;">✔ Correct Answer: $correctAnswer</span>
</div>
''');
    }

    // True / False
    if (questionType == 'true_false' || questionType == 'boolean') {
      final correctAnswer = answer['correctAnswer']?.toString() ?? '';
      for (final opt in const ['True', 'False']) {
        final isOptionCorrect = opt.toLowerCase() == correctAnswer.toLowerCase();
        final isSelected = opt.toLowerCase() == userAnswer.toLowerCase();
        final isUserWrong = isSelected && !isOptionCorrect;

        String border, background;
        if (isOptionCorrect) {
          border = '2px solid #10B981';
          background = '#ECFDF5';
        } else if (isUserWrong) {
          border = '2px solid #EF4444';
          background = '#FEE2E2';
        } else {
          border = '1px solid #E5E7EB';
          background = 'transparent';
        }
        buf.write('''
<div style="padding:12px; margin-bottom:10px; border-radius:10px; border:$border; background-color:$background;">
  <div style="font-size:14px; font-weight:${isSelected ? '600' : '500'};">$opt</div>
  ${isUserWrong ? '<div style="margin-top:6px; font-size:12px; font-weight:600; color:#EF4444;">Your Answer</div>' : ''}
  ${isOptionCorrect ? '<div style="margin-top:6px; font-size:12px; font-weight:600; color:#10B981;">Correct Answer</div>' : ''}
</div>
''');
      }
    }

    // Match the Following (A:PS;B:QR)
    if (questionType == 'match_the_following' ||
        questionType == 'maq' ||
        questionType == 'matrix' ||
        questionType == 'matrix_match') {
      final correctAnswer = answer['correctAnswer']?.toString() ?? '';
      Map<String, String> parsePairs(String raw) {
        final out = <String, String>{};
        if (raw.isEmpty) return out;
        for (final p in raw.split(';')) {
          final parts = p.split(':');
          if (parts.length == 2) out[parts[0].trim()] = parts[1].trim();
        }
        return out;
      }

      final userPairs = parsePairs(userAnswer);
      final correctPairs = parsePairs(correctAnswer);
      final lefts = {...userPairs.keys, ...correctPairs.keys}.toList()..sort();

      buf.write('<div style="border:1px solid #E5E7EB; border-radius:8px; overflow:hidden;">');
      buf.write('<div style="display:flex; padding:8px 12px; background:#F3F4F6; font-size:12px; font-weight:700;">'
          '<div style="flex:1;">Left</div>'
          '<div style="flex:1;">Your Answer</div>'
          '<div style="flex:1;">Correct Answer</div>'
          '</div>');
      for (final left in lefts) {
        final u = userPairs[left] ?? '-';
        final c = correctPairs[left] ?? '-';
        final ok = u.split('').toSet().toString() == c.split('').toSet().toString();
        final color = (userPairs[left] == null) ? '#6B7280' : (ok ? '#10B981' : '#EF4444');
        buf.write('<div style="display:flex; padding:8px 12px; border-top:1px solid #E5E7EB; font-size:13px;">'
            '<div style="flex:1; font-weight:600;">$left</div>'
            '<div style="flex:1; color:$color; font-weight:600;">$u</div>'
            '<div style="flex:1; color:#10B981; font-weight:600;">$c</div>'
            '</div>');
      }
      buf.write('</div>');
    }

    // Subjective (free-form text)
    if (questionType == 'subjective') {
      final correctAnswer = answer['correctAnswer']?.toString() ?? '';
      final displayAnswer = isSkipped || userAnswer.isEmpty ? 'Skipped' : userAnswer;
      buf.write('''
<div style="padding:12px; border-radius:8px; border:1px solid #E5E7EB; background:#F9FAFB; margin-bottom:8px;">
  <div style="font-size:12px; font-weight:700; color:#6B7280; margin-bottom:6px;">Your Answer</div>
  <div style="font-size:14px; line-height:1.6;">$displayAnswer</div>
</div>
${correctAnswer.isNotEmpty ? '''
<div style="padding:12px; border-radius:8px; border:1px solid #10B981; background:#ECFDF5;">
  <div style="font-size:12px; font-weight:700; color:#10B981; margin-bottom:6px;">Model Answer</div>
  <div style="font-size:14px; line-height:1.6;">$correctAnswer</div>
</div>''' : ''}
''');
    }

    // Solution (always shown inline — no toggle needed with single TeXView)
    if (solutionHtml != null && solutionHtml.toString().trim().isNotEmpty) {
      buf.write('''
<div style="margin-top:12px; padding:12px; background:#F0F9FF; border:1px solid rgba(59,130,246,0.3); border-radius:8px;">
  <div style="font-size:13px; font-weight:600; color:#3B82F6; margin-bottom:8px;">Solution</div>
  <div style="font-size:13px;">$solutionHtml</div>
</div>
''');
    }

    buf.write('</div></div>');
    return buf.toString();
  }
}
