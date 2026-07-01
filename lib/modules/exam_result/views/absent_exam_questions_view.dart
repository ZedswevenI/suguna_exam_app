import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';

import '../../../core/routes/app_routes.dart';
import '../controllers/absent_exam_questions_controller.dart';

/// Read-only question paper (no answer key, no marks) shown to a student who
/// was absent for the exam.
class AbsentExamQuestionsView extends StatelessWidget {
  const AbsentExamQuestionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AbsentExamQuestionsController>(
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
                return Column(
                  children: [
                    _buildHeader(controller),
                    _buildSectionTabs(controller),
                    Expanded(child: _buildQuestionsList(controller)),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(AbsentExamQuestionsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AbsentExamQuestionsController controller) {
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
                onPressed: () => Get.offAllNamed(AppRoutes.discussion),
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Question Paper',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You were absent for this exam — Exam Code: ${controller.examCode}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs(AbsentExamQuestionsController controller) {
    return Obx(() {
      final sections = controller.sectionNames;
      if (sections.length <= 1) return const SizedBox.shrink();
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
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white60,
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

  Widget _buildQuestionsList(AbsentExamQuestionsController controller) {
    return Obx(() {
      final questions = controller.filteredQuestions;
      if (questions.isEmpty) {
        return const Center(
          child: Text(
            'No questions available',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }
      final combined = StringBuffer();
      for (var i = 0; i < questions.length; i++) {
        combined.write(_buildQuestionHtml(questions[i], i));
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: TeXView(
            key: ValueKey('absent_section_${controller.selectedSectionIndex.value}'),
            loadingWidgetBuilder: (_) => const SizedBox.shrink(),
            style: const TeXViewStyle(
              backgroundColor: Colors.white,
              padding: TeXViewPadding.all(0),
            ),
            child: TeXViewDocument(combined.toString()),
          ),
        ),
      );
    });
  }

  // Drops a trailing ".0" for whole-number answers (backend numericMin/Max
  // are doubles even when the question expects an integer).
  String _formatNumber(dynamic n) {
    if (n == null) return '';
    final value = n is num ? n : num.tryParse(n.toString());
    if (value == null) return n.toString();
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String _buildQuestionHtml(Map<String, dynamic> question, int index) {
    final questionType = question['questionType'] ?? '';
    final questionHtml = question['questionHtml'] ?? '';

    List<dynamic> resolveOptions() {
      final top = question['questionOptions'];
      if (top is List && top.isNotEmpty) return top;
      return const [];
    }

    final options = List<Map<String, dynamic>>.from(
      resolveOptions().map((e) => Map<String, dynamic>.from(e as Map)),
    );

    final buf = StringBuffer();
    buf.write('''
<div style="border:1px solid #E5E7EB; border-radius:8px; margin-bottom:16px; background:#fff;">
  <div style="padding:10px 14px; background:#F9FAFB; border-bottom:1px solid #E5E7EB; border-radius:8px 8px 0 0;">
    <span style="font-weight:700; font-size:13px;">Question. ${index + 1}</span>
  </div>
  <div style="padding:14px;">
''');

    if (questionHtml.toString().trim().isNotEmpty) {
      buf.write(
          '<div style="font-size:14px; line-height:1.6; margin-bottom:16px;">$questionHtml</div>');
    }

    if (questionType == 'mcq_single' ||
        questionType == 'mcq_multiple' ||
        questionType == 'mcq_multi' ||
        questionType == 'single_dropdown' ||
        questionType == 'dropdown' ||
        questionType == 'multi_dropdown') {
      for (int i = 0; i < options.length; i++) {
        final option = options[i];
        final key = option['key'] ?? String.fromCharCode(65 + i);
        final optionHtml = option['textHtml'] ?? '';
        final isOptionCorrect = option['isCorrect'] == true;
        final border = isOptionCorrect ? '2px solid #10B981' : '1px solid #E5E7EB';
        final background = isOptionCorrect ? '#ECFDF5' : 'transparent';
        final circleBg = isOptionCorrect ? '#10B981' : '#D1D5DB';
        final circleColor = isOptionCorrect ? '#ffffff' : '#374151';
        buf.write('''
<div style="padding:12px; margin-bottom:10px; border-radius:10px; border:$border; background-color:$background;">
  <div style="display:flex; align-items:flex-start; gap:12px;">
    <div style="width:26px; height:26px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:11px; font-weight:700; color:$circleColor; background-color:$circleBg; flex-shrink:0;">$key</div>
    <div style="flex:1; font-size:14px; font-weight:500;">$optionHtml</div>
  </div>
  ${isOptionCorrect ? '<div style="margin-top:6px; font-size:12px; font-weight:600; color:#10B981;">Correct Answer</div>' : ''}
</div>
''');
      }
    }

    if (questionType == 'true_false' || questionType == 'boolean') {
      final correctAnswer = question['correctAnswer']?.toString() ?? '';
      for (final opt in const ['True', 'False']) {
        final isOptionCorrect = opt.toLowerCase() == correctAnswer.toLowerCase();
        final border = isOptionCorrect ? '2px solid #10B981' : '1px solid #E5E7EB';
        final background = isOptionCorrect ? '#ECFDF5' : 'transparent';
        buf.write('''
<div style="padding:12px; margin-bottom:10px; border-radius:10px; border:$border; background-color:$background;">
  <div style="font-size:14px; font-weight:500;">$opt</div>
  ${isOptionCorrect ? '<div style="margin-top:6px; font-size:12px; font-weight:600; color:#10B981;">Correct Answer</div>' : ''}
</div>
''');
      }
    }

    // Numerical / Integer
    if (questionType == 'numeric' ||
        questionType == 'integer' ||
        questionType == 'numerical') {
      final correctAnswer = question['correctAnswer']?.toString() ?? '';
      final numericMin = question['numericMin'];
      final numericMax = question['numericMax'];
      String correctDisplay = correctAnswer;
      if (numericMin != null && numericMax != null) {
        correctDisplay =
            'Range : ${_formatNumber(numericMin)} - ${_formatNumber(numericMax)}';
      }
      buf.write('''
<div style="padding:12px; border-radius:8px; border:2px solid #10B981; background:#ECFDF5;">
  <span style="font-weight:600; color:#10B981;">Correct Answer: $correctDisplay</span>
</div>
''');
    }

    // Short answer / Subjective
    if (questionType == 'short_answer' || questionType == 'subjective') {
      final correctAnswer = question['correctAnswer']?.toString() ?? '';
      if (correctAnswer.trim().isNotEmpty) {
        buf.write('''
<div style="padding:12px; border-radius:8px; border:1px solid #10B981; background:#ECFDF5;">
  <div style="font-size:12px; font-weight:700; color:#10B981; margin-bottom:6px;">${questionType == 'subjective' ? 'Model Answer' : 'Correct Answer'}</div>
  <div style="font-size:14px; line-height:1.6;">$correctAnswer</div>
</div>
''');
      }
    }

    // Match-the-following / matrix — show both columns with the correct pairing.
    if (questionType == 'match_the_following' ||
        questionType == 'maq' ||
        questionType == 'matrix' ||
        questionType == 'matrix_match') {
      final leftColumn = List<Map<String, dynamic>>.from(
          (question['leftColumn'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));
      final rightColumn = List<Map<String, dynamic>>.from(
          (question['rightColumn'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));
      final rightTextByKey = {
        for (final item in rightColumn) (item['key'] ?? '').toString(): (item['text'] ?? item['textHtml'] ?? '').toString(),
      };

      // correctAnswer looks like "A:P(2,0);B:Q(2,0);..." — take the leading
      // letters of the right-hand side as the matched key.
      final pairs = <String, String>{};
      final correctAnswer = question['correctAnswer']?.toString() ?? '';
      for (final part in correctAnswer.split(';')) {
        final segments = part.split(':');
        if (segments.length == 2) {
          final rightKey = RegExp(r'^[A-Za-z0-9]+').firstMatch(segments[1].trim())?.group(0) ?? '';
          pairs[segments[0].trim()] = rightKey;
        }
      }

      if (leftColumn.isNotEmpty) {
        buf.write('<div style="border:1px solid #E5E7EB; border-radius:8px; overflow:hidden;">');
        buf.write('<div style="display:flex; padding:8px 12px; background:#F3F4F6; font-size:12px; font-weight:700;">'
            '<div style="flex:1;">Column I</div>'
            '<div style="flex:2;">Column II (Correct Match)</div>'
            '</div>');
        for (final item in leftColumn) {
          final key = (item['key'] ?? '').toString();
          final text = item['text'] ?? item['textHtml'] ?? '';
          final matchedKey = pairs[key] ?? '';
          final matchedText = rightTextByKey[matchedKey] ?? matchedKey;
          buf.write('''
<div style="display:flex; padding:10px 12px; border-top:1px solid #E5E7EB; font-size:13px;">
  <div style="flex:1;"><b>$key.</b> $text</div>
  <div style="flex:2; color:#10B981; font-weight:600;">$matchedKey. $matchedText</div>
</div>
''');
        }
        buf.write('</div>');
      }
    }

    dynamic firstNonEmpty(List<dynamic> values) {
      for (final v in values) {
        if (v != null && v.toString().trim().isNotEmpty) return v;
      }
      return null;
    }

    final solutionHtml = firstNonEmpty([
      question['solutionHtml'],
      question['solutionText'],
      question['solution'],
    ]);
    if (solutionHtml != null) {
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
