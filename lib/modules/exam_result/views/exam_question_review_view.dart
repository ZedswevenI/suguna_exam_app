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
                    // Render everything inside a single TeXViewDocument (one
                    // webview only) using KaTeX. MathJax + a TeXViewColumn was
                    // sometimes stuck on its loading indicator when the user
                    // re-entered this screen quickly because the second
                    // webview's "loaded" event never fired.
                    final combined = StringBuffer();
                    for (var i = 0; i < questions.length; i++) {
                      combined.write(_buildQuestionHtml(controller, questions[i], i));
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TeXView(
                        key: ValueKey('section_${controller.selectedSectionIndex.value}'),
                        loadingWidgetBuilder: (_) => const SizedBox.shrink(),
                        style: const TeXViewStyle(
                          backgroundColor: Colors.white,
                          padding: TeXViewPadding.all(0),
                        ),
                        child: TeXViewDocument(combined.toString()),
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

  // Parses "A:P,Q,R(2,0);B:P,Q(2,0);C:R(2,0);D:R(2,0)" into, for each left
  // key, the list of matched right keys plus its (posMark, negMark).
  Map<String, ({List<String> rightKeys, String posMark, String negMark})>
      _parseMatrixMatches(String correctAnswer) {
    final out = <String, ({List<String> rightKeys, String posMark, String negMark})>{};
    for (final segment in correctAnswer.split(';')) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx == -1) continue;
      final leftKey = trimmed.substring(0, colonIdx).trim();
      final rest = trimmed.substring(colonIdx + 1).trim();

      final marksMatch = RegExp(r'\(([^)]*)\)').firstMatch(rest);
      var rightPart = rest;
      var posMark = '';
      var negMark = '';
      if (marksMatch != null) {
        rightPart = rest.substring(0, marksMatch.start);
        final marksParts = marksMatch.group(1)!.split(',');
        posMark = marksParts.isNotEmpty ? marksParts[0].trim() : '';
        negMark = marksParts.length > 1 ? marksParts[1].trim() : '';
      }
      final rightKeys = rightPart
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (leftKey.isNotEmpty && rightKeys.isNotEmpty) {
        out[leftKey] = (rightKeys: rightKeys, posMark: posMark, negMark: negMark);
      }
    }
    return out;
  }

  // Student's submitted matrix answer. Format isn't guaranteed to match the
  // correctAnswer encoding exactly, so this is deliberately more permissive:
  // right-hand values are split on ',' when present, otherwise split into
  // individual characters if every character is a known right-column key.
  Map<String, List<String>> _parseMatrixAnswer(String raw, Set<String> knownRightKeys) {
    final out = <String, List<String>>{};
    for (final segment in raw.split(';')) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx == -1) continue;
      final leftKey = trimmed.substring(0, colonIdx).trim();
      var rightPart = trimmed.substring(colonIdx + 1).trim();
      final marksMatch = RegExp(r'\(([^)]*)\)').firstMatch(rightPart);
      if (marksMatch != null) {
        rightPart = rightPart.substring(0, marksMatch.start);
      }

      List<String> keys;
      if (rightPart.contains(',')) {
        keys = rightPart.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else if (rightPart.length > 1 &&
          rightPart.split('').every((c) => knownRightKeys.contains(c))) {
        keys = rightPart.split('');
      } else if (rightPart.isNotEmpty) {
        keys = [rightPart];
      } else {
        keys = const [];
      }
      if (leftKey.isNotEmpty && keys.isNotEmpty) {
        out.putIfAbsent(leftKey, () => []).addAll(keys);
      }
    }
    return out;
  }

  // ============================================================
  // Build HTML string for a single question (rendered inside one TeXView)
  // ============================================================
  String _buildQuestionHtml(
      ExamResultController controller, Map<String, dynamic> answer, int index) {
    // Mirror the web `StudentResultComponent` logic:
    //   isSkipped         → SKIPPED (warning)
    //   isCorrect == true → CORRECT (success)
    //   isCorrect == false→ INCORRECT (danger)
    //   isCorrect == null → PARTIAL  (info — partial-marking award)
    final rawIsCorrect = answer['isCorrect'];
    final isSkipped = answer['isSkipped'] == true;
    final isCorrect = rawIsCorrect == true;
    final isIncorrect = rawIsCorrect == false;
    final isPartial = !isSkipped && rawIsCorrect == null;
    final marksAwarded = (answer['marksAwarded'] as num?)?.toDouble() ?? 0.0;
    final positiveMarks = answer['positiveMarks'] ?? 0;
    final negativeMarks = answer['negativeMarks'] ?? 0;
    final timeTakenMs = (answer['timeTaken'] as int?) ?? 0;
    final timeSec = timeTakenMs ~/ 1000;
    final questionType = answer['questionType'] ?? '';
    final questionHtml = answer['questionHtml'] ?? '';
    // Options may live at top level or nested under `question` depending on
    // backend shape. Pick the first non-empty list.
    List<dynamic> _resolveOptions() {
      final top = answer['questionOptions'];
      if (top is List && top.isNotEmpty) return top;
      final q = answer['question'];
      if (q is Map) {
        for (final key in const ['questionOptions', 'options']) {
          final v = q[key];
          if (v is List && v.isNotEmpty) return v;
        }
      }
      return const [];
    }
    final options = List<Map<String, dynamic>>.from(
      _resolveOptions().map((e) => Map<String, dynamic>.from(e as Map)),
    );
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
      statusText =
          'Your answer is correct, You Scored ${marksAwarded.toStringAsFixed(1)}';
      statusColor = '#10B981';
    } else if (isPartial) {
      statusText =
          'Partial answer, You Scored ${marksAwarded.toStringAsFixed(1)}';
      statusColor = '#0EA5E9';
    } else {
      statusText =
          'Your answer is incorrect, You Scored ${marksAwarded.toStringAsFixed(1)}';
      statusColor = '#EF4444';
    }

    // Small uppercase status badge — mirrors the web `<span class="badge ...">`.
    String badgeLabel;
    String badgeBg;
    String badgeFg;
    if (isSkipped) {
      badgeLabel = 'SKIPPED';
      badgeBg = '#FEF3C7';
      badgeFg = '#92400E';
    } else if (isCorrect) {
      badgeLabel = 'CORRECT';
      badgeBg = '#10B981';
      badgeFg = '#FFFFFF';
    } else if (isPartial) {
      badgeLabel = 'PARTIAL';
      badgeBg = '#0EA5E9';
      badgeFg = '#FFFFFF';
    } else {
      badgeLabel = 'INCORRECT';
      badgeBg = '#EF4444';
      badgeFg = '#FFFFFF';
    }

    final buf = StringBuffer();

    // Question card container
    buf.write('''
<div style="border:1px solid #E5E7EB; border-radius:8px; margin-bottom:16px; background:#fff;">
  <!-- Info bar -->
  <div style="padding:10px 14px; background:#F9FAFB; border-bottom:1px solid #E5E7EB; border-radius:8px 8px 0 0; display:flex; align-items:center; flex-wrap:wrap; gap:8px;">
    <span style="font-weight:700; font-size:13px;">Question. ${index + 1}</span>
    <span style="background:$badgeBg; color:$badgeFg; padding:2px 10px; border-radius:12px; font-size:10px; font-weight:700; letter-spacing:0.5px;">$badgeLabel</span>
    <span style="color:$statusColor; font-size:12px; font-weight:500;">$statusText</span>
    <span style="background:rgba(59,130,246,0.1); padding:2px 8px; border-radius:4px; font-size:11px; font-weight:600; color:#3B82F6;">+$positiveMarks, -$negativeMarks</span>
    <span style="font-size:11px; color:#6B7280;">⏱ ${timeSec} Sec</span>
  </div>
  <!-- Question content -->
  <div style="padding:14px;">
''');

    // Passage — check every plausible location in the answer payload. The
    // result API may return the passage merged into the answer, nested under
    // `question`, or referenced by `passageId` at the top level.
    Map? _pickMap(dynamic v) => v is Map ? v : null;
    final candidateSources = <Map?>[
      _pickMap(answer['passageData']),
      _pickMap(answer['passage']),
      _pickMap((answer['question'] is Map) ? answer['question']['passageData'] : null),
      _pickMap((answer['question'] is Map) ? answer['question']['passage'] : null),
      _pickMap((answer['questionData'] is Map) ? answer['questionData']['passageData'] : null),
    ];
    final passageSource = candidateSources.firstWhere(
      (m) => m != null,
      orElse: () => null,
    );
    final directHtmlCandidates = [
      answer['passageHtml'],
      (answer['question'] is Map) ? answer['question']['passageHtml'] : null,
      (answer['questionData'] is Map) ? answer['questionData']['passageHtml'] : null,
    ];
    final directHtml = directHtmlCandidates
        .whereType<String>()
        .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');

    final passageHtml = passageSource?['passageHtml']?.toString() ?? '';
    final passageTitle = passageSource?['title']?.toString();
    final effective = passageHtml.trim().isNotEmpty
        ? passageHtml
        : (directHtml.trim().isNotEmpty ? directHtml : null);

    if (index == 0) {
      // One-time diagnostic so it's obvious in logcat whether the API is
      // sending passage data at all.
      // ignore: avoid_print
      print('[PassageDebug] q${index + 1} keys=${answer.keys.toList()} '
          'passageData=${answer['passageData']} '
          'passageHtml=${answer['passageHtml']} '
          'enablePassage=${answer['enablePassage']}');
    }

    if (effective != null) {
        buf.write('''
<style>
  .passage-box, .passage-box * {
    max-width: 100% !important;
    box-sizing: border-box;
  }
  .passage-box { overflow-x: auto; -webkit-overflow-scrolling: touch; }
  .passage-box img { height: auto !important; display: inline-block; }
  .passage-body {
    word-wrap: break-word;
    overflow-wrap: anywhere;
    white-space: normal;
  }
</style>
<div class="passage-box" style="background:#f0f4ff; border-left:4px solid #4F46E5;
  border-radius:8px; padding:12px 14px; margin-bottom:16px; font-size:13px;
  line-height:1.7; color:#1e293b; width:100%;">
  <div style="font-size:11px; font-weight:700; color:#4F46E5;
    text-transform:uppercase; letter-spacing:0.5px; margin-bottom:6px;">Passage${passageTitle != null && passageTitle.isNotEmpty ? ' — $passageTitle' : ''}</div>
  <div class="passage-body">$effective</div>
</div>
''');
    }

    // Question text
    if (questionHtml.toString().trim().isNotEmpty) {
      buf.write('<div style="font-size:14px; line-height:1.6; margin-bottom:16px;">$questionHtml</div>');
    }


    // MCQ options (single / multiple / single dropdown / multi dropdown)
    if (questionType == 'mcq_single' ||
        questionType == 'mcq_multiple' ||
        questionType == 'mcq_multi' ||
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

    // Match the Following / Matrix — one left key can map to several right
    // keys, e.g. correctAnswer "A:P,Q,R(2,0);B:P,Q(2,0);C:R(2,0);D:R(2,0)".
    if (questionType == 'match_the_following' ||
        questionType == 'maq' ||
        questionType == 'matrix' ||
        questionType == 'matrix_match') {
      final leftColumn = List<Map<String, dynamic>>.from(
          (answer['leftColumn'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));
      final rightColumn = List<Map<String, dynamic>>.from(
          (answer['rightColumn'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));
      final knownRightKeys =
          rightColumn.map((e) => (e['key'] ?? '').toString()).toSet();

      final correctAnswer = answer['correctAnswer']?.toString() ?? '';
      final correctMatches = _parseMatrixMatches(correctAnswer);
      final userMatches = _parseMatrixAnswer(userAnswer, knownRightKeys);

      final lefts = leftColumn.isNotEmpty
          ? leftColumn.map((e) => (e['key'] ?? '').toString()).toList()
          : (<String>{...userMatches.keys, ...correctMatches.keys}.toList()..sort());
      final leftTextByKey = {
        for (final item in leftColumn)
          (item['key'] ?? '').toString(): (item['text'] ?? item['textHtml'] ?? '').toString(),
      };

      if (leftColumn.isNotEmpty || rightColumn.isNotEmpty) {
        buf.write('<div style="display:flex; gap:16px; margin-bottom:12px;">');
        for (final column in [leftColumn, rightColumn]) {
          if (column.isEmpty) continue;
          buf.write('<div style="flex:1; border:1px solid #E5E7EB; border-radius:8px; overflow:hidden;">');
          for (final item in column) {
            final key = item['key'] ?? '';
            final text = item['text'] ?? item['textHtml'] ?? '';
            buf.write('''
<div style="display:flex; gap:8px; padding:10px 12px; border-top:1px solid #E5E7EB;">
  <div style="font-weight:700; font-size:13px;">$key.</div>
  <div style="flex:1; font-size:13px;">$text</div>
</div>
''');
          }
          buf.write('</div>');
        }
        buf.write('</div>');
      }

      buf.write('<div style="border:1px solid #E5E7EB; border-radius:8px; overflow:hidden;">');
      buf.write('<div style="display:flex; padding:8px 12px; background:#F3F4F6; font-size:12px; font-weight:700;">'
          '<div style="flex:3;">Left</div>'
          '<div style="flex:2;">Your Answer</div>'
          '<div style="flex:2;">Correct Answer</div>'
          '</div>');
      for (final left in lefts) {
        final leftText = leftTextByKey[left] ?? '';
        final userKeys = userMatches[left] ?? const <String>[];
        final correctKeys = correctMatches[left]?.rightKeys ?? const <String>[];
        final isRowCorrect = userKeys.isNotEmpty &&
            userKeys.toSet().difference(correctKeys.toSet()).isEmpty &&
            correctKeys.toSet().difference(userKeys.toSet()).isEmpty;
        final userLabel = userKeys.isEmpty ? '-' : userKeys.join(', ');
        final correctLabel = correctKeys.isEmpty ? '-' : correctKeys.join(', ');
        final color = userKeys.isEmpty ? '#6B7280' : (isRowCorrect ? '#10B981' : '#EF4444');
        buf.write('<div style="display:flex; padding:8px 12px; border-top:1px solid #E5E7EB; font-size:13px;">'
            '<div style="flex:3; font-weight:600;">$left. $leftText</div>'
            '<div style="flex:2; color:$color; font-weight:600;">$userLabel</div>'
            '<div style="flex:2; color:#10B981; font-weight:600;">$correctLabel</div>'
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
