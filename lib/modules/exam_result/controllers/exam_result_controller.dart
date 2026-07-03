import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/sessions.dart';

class ExamResultController extends GetxController {
  final _apiService = ServiceLocator.get<AssignmentApiServices>();

  final resultData = Rxn<Map<String, dynamic>>();
  final examInfo = Rxn<Map<String, dynamic>>();
  final reviewIndex = 0.obs;
  final selectedSectionIndex = 0.obs;
  final expandedSolutions = <int>{}.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      examInfo.value = args;
    }
    _loadResult();
  }

  Future<void> _loadResult() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final userData = Session.instance.currentUser?['data'];
      final args = examInfo.value ?? {};

      final entiId = userData?['tenantId'] ?? args['entiId'] ?? '';
      final examId = args['examId'] ?? '';
      final admissionNo = userData?['admissionNo'] ?? args['admissionNo'] ?? '';

      final response = await _apiService.getExamResultWithQuestions(
        entiId,
        examId,
        admissionNo,
      );

      if (response['status'] == true) {
        final raw = Map<String, dynamic>.from(response['data'] as Map);
        // Process LaTeX + download images for all answer HTML fields
        final rawAnswers = (raw['answers'] as List?) ?? [];
        final answers = <Map<String, dynamic>>[];
        for (final a in rawAnswers) {
          final answer = Map<String, dynamic>.from(a as Map);
          if (answer['questionHtml'] is String) {
            answer['questionHtml'] = await _replaceImagesWithBase64(
                _stripLatexSpans(answer['questionHtml'] as String));
          }
          // Process whichever field carries the solution HTML.
          for (final key in const ['solutionHtml', 'solutionText', 'solution']) {
            if (answer[key] is String && (answer[key] as String).isNotEmpty) {
              answer[key] = await _replaceImagesWithBase64(
                  _stripLatexSpans(answer[key] as String));
            }
          }
          // Some payloads nest it under `question`.
          if (answer['question'] is Map) {
            final q = Map<String, dynamic>.from(answer['question'] as Map);
            for (final key in const ['solutionHtml', 'solutionText', 'solution']) {
              if (q[key] is String && (q[key] as String).isNotEmpty) {
                q[key] = await _replaceImagesWithBase64(
                    _stripLatexSpans(q[key] as String));
              }
            }
            answer['question'] = q;
          }
          if (answer['questionOptions'] is List) {
            final opts = <Map<String, dynamic>>[];
            for (final opt in (answer['questionOptions'] as List)) {
              final option = Map<String, dynamic>.from(opt as Map);
              if (option['textHtml'] is String) {
                option['textHtml'] = await _replaceImagesWithBase64(
                    _stripLatexSpans(option['textHtml'] as String));
              }
              opts.add(option);
            }
            answer['questionOptions'] = opts;
          }
          // Matrix/match-the-following left & right columns.
          for (final colKey in const ['leftColumn', 'rightColumn']) {
            if (answer[colKey] is! List) continue;
            final cells = <Map<String, dynamic>>[];
            for (final c in (answer[colKey] as List)) {
              final cell = Map<String, dynamic>.from(c as Map);
              for (final key in const ['text', 'textHtml']) {
                if (cell[key] is String && (cell[key] as String).isNotEmpty) {
                  cell[key] = await _replaceImagesWithBase64(
                      _stripLatexSpans(cell[key] as String));
                }
              }
              cells.add(cell);
            }
            answer[colKey] = cells;
          }
          answers.add(answer);
        }
        raw['answers'] = answers;
        print("Data came ${raw}");
        resultData.value = raw;
      } else {
        final message = (response['message'] ?? '').toString();
        if (_handleKnownFailure(message)) return;
        errorMessage.value = message.isNotEmpty ? message : 'Failed to load result';
      }
    } catch (e) {
      // Both known cases below come back from the backend with a non-2xx
      // status, so ApiService throws before the `if (response['status'] ==
      // true)` branch above ever runs — they have to be checked here too.
      if (_handleKnownFailure(e.toString())) return;
      errorMessage.value = 'Failed to load result: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Redirects to the right fallback screen for two expected backend
  /// failures. Returns true if it redirected (caller should stop).
  bool _handleKnownFailure(String message) {
    final lower = message.toLowerCase();
    // Both cases land on the same question-paper-with-answers screen: the
    // exam itself is published either way, this student's own result just
    // isn't ready (absent, or not graded/visible yet) — show the questions
    // instead of a generic error screen.
    if (lower.contains('result not found') || lower.contains('not visible yet')) {
      _goToAbsentQuestions();
      return true;
    }
    return false;
  }

  void _goToAbsentQuestions() {
    final args = examInfo.value ?? {};
    final userData = Session.instance.currentUser?['data'];
    final tenantId = userData?['tenantId'] ?? args['entiId'] ?? '';
    Get.offNamed(AppRoutes.absentExamQuestions, arguments: {
      'tenantId': tenantId,
      'examId': args['examId'] ?? '',
      'examCode': args['examCode'] ?? '',
      'examName': args['examName'] ?? '',
    });
  }

  /// Retry loading result
  void retryLoadResult() => _loadResult();

  // ── Image processing (download & embed as base64) ────────────────────────
  List<String> _extractImageUrls(String html) {
    final regex = RegExp(r'''<img[^>]+src\s*=\s*["']([^"'>]+)["']''');
    return regex
        .allMatches(html)
        .map((m) => m.group(1)!)
        .where((u) => !u.startsWith('data:'))
        .toList();
  }

  String _mimeFromUrl(String url) {
    final ext = url.split('?').first.split('#').first.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  Future<String> _replaceImagesWithBase64(String html) async {
    final urls = _extractImageUrls(html);
    for (final url in urls) {
      try {
        String? signedUrl;
        try {
          final signed = await _apiService.downloadExamQuestionImage(url);
          final ok = signed['status'] == true ||
              signed['status']?.toString() == 'true' ||
              signed['success'] == true;
          final returnedUrl = (signed['url'] ?? signed['data']?['url'])?.toString();
          if (ok && returnedUrl != null && returnedUrl.isNotEmpty) {
            signedUrl = returnedUrl;
          }
        } catch (e) {
          print('Exam result signed-url failed for $url: $e');
        }
        final fetchUrl = signedUrl ?? url;
        final bytes = await _apiService.downloadImageBytes(fetchUrl);
        if (bytes.isEmpty) continue;
        final base64Tag =
            'data:${_mimeFromUrl(url)};base64,${base64Encode(bytes)}';
        html = html.replaceAll(url, base64Tag);
      } catch (e) {
        print('Exam result image convert failed for $url: $e');
      }
    }
    return html;
  }

  /// Converts <span class="latex">$...$</span> to \(...\) for TeXView rendering
  static String _stripLatexSpans(String html) {
    // Step 1: Unwrap <span class="latex">...</span> tags
    var result = html.replaceAllMapped(
      RegExp(r'<span\s+class="latex">\s*(.*?)\s*</span>', dotAll: true),
      (match) => match.group(1) ?? '',
    );
    // Step 2: Convert $...$ delimiters to \(...\) which TeXView supports
    result = result.replaceAllMapped(
      RegExp(r'\$(.+?)\$', dotAll: true),
      (match) => '\\(${match.group(1)}\\)',
    );
    return result;
  }

  // ── Computed getters ──────────────────────────────────────────────────────

  Map<String, dynamic> get data => resultData.value ?? {};

  int get obtainedMarks {
    final v = (data['obtainedMarks'] as num?)?.toInt() ?? 0;
    if (v != 0) return v;
    // Fallback: sum marksAwarded from answers
    double sum = 0;
    for (var a in answers) {
      sum += (a['marksAwarded'] as num?)?.toDouble() ?? 0;
    }
    return sum.round();
  }

  int get totalMarks {
    final v = (data['totalMarks'] as num?)?.toInt() ?? 0;
    if (v != 0) return v;
    // Fallback: sum positiveMarks from answers
    double sum = 0;
    for (var a in answers) {
      sum += (a['positiveMarks'] as num?)?.toDouble() ?? 0;
    }
    return sum.round();
  }

  int get rank => (data['rank'] as num?)?.toInt() ?? 0;
  num get percentile => (data['percentile'] as num?) ?? 0;
  int get timeTakenMs {
    final v = (data['timeTaken'] as num?)?.toInt() ?? 0;
    if (v != 0) return v;
    // Fallback: sum timeTaken from answers
    int sum = 0;
    for (var a in answers) {
      sum += (a['timeTaken'] as num?)?.toInt() ?? 0;
    }
    return sum;
  }

  List<Map<String, dynamic>> get sectionResults {
    try {
      final list = data['sectionResults'];
      if (list != null && (list as List).isNotEmpty) {
        final sections = list.map<Map<String, dynamic>>((e) =>
            Map<String, dynamic>.from(e as Map)).toList();
        // Check if any section has meaningful totalQuestions data
        final hasMeaningfulData = sections.any((s) =>
            ((s['totalQuestions'] as num?)?.toInt() ?? 0) > 0);
        if (hasMeaningfulData) return sections;
      }
    } catch (e) {
      print('⚠️ sectionResults parse error: $e');
    }
    // Fallback: compute from answers
    final computed = _computeSectionResultsFromAnswers();
    print('📊 sectionResults computed from answers: ${computed.length} sections');
    for (var s in computed) {
      print('  → ${s['sectionName']}: total=${s['totalQuestions']}, correct=${s['correctCount']}, wrong=${s['wrongCount']}, skipped=${s['skippedCount']}');
    }
    return computed;
  }

  List<Map<String, dynamic>> get answers {
    final list = data['answers'];
    if (list == null) return [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Computes section-level stats from the answers array when sectionResults is missing.
  List<Map<String, dynamic>> _computeSectionResultsFromAnswers() {
    // Build a sectionId → subjectId/name mapping from the backend's sectionResults
    // (which may exist with subjectId objects even if totalQuestions = 0)
    final Map<String, Map<String, dynamic>> sectionMeta = {};
    final rawSections = data['sectionResults'];
    if (rawSections is List) {
      for (var s in rawSections) {
        if (s is Map) {
          final section = Map<String, dynamic>.from(s);
          final subjectId = section['subjectId'];
          String? sid;
          if (subjectId is Map) {
            sid = subjectId['_id']?.toString();
          }
          sid ??= section['sectionId']?.toString();
          if (sid != null) {
            sectionMeta[sid] = section;
          }
        }
      }
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var a in answers) {
      final sid = (a['sectionId'] ?? '').toString();
      grouped.putIfAbsent(sid, () => []);
      grouped[sid]!.add(a);
    }

    return grouped.entries.map((entry) {
      final sectionId = entry.key;
      final sectionAnswers = entry.value;

      int correct = 0, wrong = 0, skipped = 0, answered = 0;
      double obtainedMarks = 0, sectionTotalMarks = 0;
      int timeTaken = 0;

      for (var a in sectionAnswers) {
        sectionTotalMarks += (a['positiveMarks'] as num?)?.toDouble() ?? 0;
        timeTaken += (a['timeTaken'] as num?)?.toInt() ?? 0;

        if (a['isSkipped'] == true) {
          skipped++;
        } else {
          answered++;
          if (a['isCorrect'] == true) {
            correct++;
          } else {
            wrong++;
          }
          obtainedMarks += (a['marksAwarded'] as num?)?.toDouble() ?? 0;
        }
      }

      // Resolve section display name from backend metadata
      final meta = sectionMeta[sectionId];
      final subjectIdObj = meta?['subjectId'];

      return {
        'sectionId': sectionId,
        'subjectId': subjectIdObj ?? sectionId,
        'sectionName': _sectionDisplayName(meta ?? {'sectionId': sectionId}),
        'totalQuestions': sectionAnswers.length,
        'correctCount': correct,
        'wrongCount': wrong,
        'skippedCount': skipped,
        'answeredCount': answered,
        'obtainedMarks': obtainedMarks,
        'totalMarks': sectionTotalMarks,
        'timeTaken': timeTaken,
      };
    }).toList();
  }

  // ── Statistics ─────────────────────────────────────────────────────────────

  Map<String, dynamic> getOverallStats() {
    int total = 0, correct = 0, wrong = 0, skipped = 0;
    for (var section in sectionResults) {
      total += (section['totalQuestions'] as num?)?.toInt() ?? 0;
      correct += (section['correctCount'] as num?)?.toInt() ?? 0;
      wrong += (section['wrongCount'] as num?)?.toInt() ?? 0;
      skipped += (section['skippedCount'] as num?)?.toInt() ?? 0;
    }
    final percentage = total > 0 ? (correct / total * 100) : 0.0;
    return {
      'total': total,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'percentage': percentage,
    };
  }


  /// Extracts the display name for a section from the new API shape.
  /// `subjectId` is now an object: { "_id": "...", "subjectName": "BOTANY" }
  String _sectionDisplayName(Map<String, dynamic> section) {
    final subjectId = section['subjectId'];
    if (subjectId is Map) {
      final name = subjectId['subjectName'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
    }
    return (section['sectionName'] ?? section['sectionId'] ?? '').toString();
  }

  // Section-wise report for performance table
  List<Map<String, dynamic>> getSectionReport() {
    return sectionResults.map((section) {
      final totalQ = (section['totalQuestions'] as num?)?.toInt() ?? 0;
      final correct = (section['correctCount'] as num?)?.toInt() ?? 0;
      final wrong = (section['wrongCount'] as num?)?.toInt() ?? 0;
      final skipped = (section['skippedCount'] as num?)?.toInt() ?? 0;
      final obtained = (section['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
      final sectionTotal = (section['totalMarks'] as num?)?.toDouble() ?? 0.0;
      final timeTaken = (section['timeTaken'] as num?)?.toInt() ?? 0;
      final answered = (section['answeredCount'] as num?)?.toInt() ?? 0;
      final percentage = totalQ > 0 ? (correct / totalQ * 100) : 0.0;
      final accuracy = answered > 0 ? (correct / answered * 100) : 0.0;
      final avgTime = totalQ > 0 ? (timeTaken / totalQ) : 0.0;

      return {
        'sectionId': section['sectionId'],
        'sectionName': _sectionDisplayName(section),
        'totalQuestions': totalQ,
        'correct': correct,
        'wrong': wrong,
        'skipped': skipped,
        'obtainedMarks': obtained,
        'totalMarks': sectionTotal,
        'timeTakenMs': timeTaken,
        'percentage': percentage,
        'accuracy': accuracy,
        'avgTimeMs': avgTime,
      };
    }).toList();
  }

  // Performance Report 1 — section-wise with +ve/-ve marks (computed from answers)
  Map<String, dynamic> getPerformanceReport() {
    // Group answers by sectionId
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var a in answers) {
      final sid = a['sectionId'] ?? '';
      grouped.putIfAbsent(sid, () => []);
      grouped[sid]!.add(a);
    }

    double grandPositive = 0, grandNegative = 0, grandTotal = 0, grandObtained = 0,obtainedMarks = 0;
    int grandCorrect = 0, grandWrong = 0;

    final subjects = sectionResults.map((section) {
      final sId = section['sectionId'] ?? '';
      final name = _sectionDisplayName(section);
      final sectionAnswers = grouped[sId] ?? [];

      double positiveMarks = 0, negativeMarks = 0, totalMarks = 0,obtainedMark = 0;
      int correct = 0, wrong = 0;

      for (var a in sectionAnswers) {
        final posM = (a['positiveMarks'] as num?)?.toDouble() ?? 4.0;
        final negM = (a['negativeMarks'] as num?)?.toDouble() ?? 1.0;
        totalMarks += posM;

        if (a['isSkipped'] == true) continue;
        if (a['isCorrect'] == true) {
          correct++;
          positiveMarks += posM;
        } else {
          wrong++;
          negativeMarks += negM;
        }
      }

      // If no answers in section, calculate totalMarks from section metadata
      if (sectionAnswers.isEmpty) {
        totalMarks = (section['totalMarks'] as num?)?.toDouble() ?? 0.0;
      }
      obtainedMark = (section['obtainedMarks'] as num?)?.toDouble() ?? 0.0;

      final totalScore = positiveMarks - negativeMarks;

      grandPositive += positiveMarks;
      grandNegative += negativeMarks;
      grandTotal += totalMarks;
      grandObtained += totalScore;
      grandCorrect += correct;
      grandWrong += wrong;
      obtainedMarks += obtainedMark;

      return {
        'subjectName': name,
        'correct': correct,
        'wrong': wrong,
        'skipped': (section['skippedCount'] as int?) ?? 0,
        'totalMarks': totalMarks,
        'positiveMarks': positiveMarks,
        'negativeMarks': negativeMarks,
        'totalScore': totalScore,
        "obtainedMarks" : obtainedMark
      };
    }).toList();

    return {
      'subjects': subjects,
      'totalQuestions': answers.length,
      'totalMarks': grandTotal,
      'correct': grandCorrect,
      'wrong': grandWrong,
      'positiveMarks': grandPositive,
      'negativeMarks': grandNegative,
      'totalScore': grandObtained,
      "obtainedMarks" : obtainedMarks
    };
  }

  // ── Section tab helpers ─────────────────────────────────────────────────────

  List<String> get sectionNames {
    return sectionResults.map((s) => _sectionDisplayName(s)).toList();
  }

  /// Returns every identifier the currently-selected section might match an
  /// answer on — backend payloads vary between `sectionId`, `subjectId._id`,
  /// and a plain id string.
  Set<String> get selectedSectionMatchKeys {
    if (selectedSectionIndex.value >= sectionResults.length) return {};
    final section = sectionResults[selectedSectionIndex.value];
    final keys = <String>{};
    final sectionId = section['sectionId'];
    if (sectionId != null) keys.add(sectionId.toString());
    final subjectId = section['subjectId'];
    if (subjectId is Map) {
      final id = subjectId['_id'];
      if (id != null) keys.add(id.toString());
    } else if (subjectId is String) {
      keys.add(subjectId);
    }
    keys.removeWhere((k) => k.isEmpty);
    return keys;
  }

  String? get selectedSectionId {
    final keys = selectedSectionMatchKeys;
    return keys.isEmpty ? null : keys.first;
  }

  List<Map<String, dynamic>> get filteredAnswers {
    final keys = selectedSectionMatchKeys;
    if (keys.isEmpty) return answers;
    final filtered = answers
        .where((a) => keys.contains((a['sectionId'] ?? '').toString()))
        .toList();
    // If nothing matches, fall back to showing all answers rather than an
    // empty "No questions in this section" screen.
    return filtered.isEmpty ? answers : filtered;
  }

  void selectSection(int index) {
    selectedSectionIndex.value = index;
    expandedSolutions.clear();
  }

  void toggleSolution(int index) {
    if (expandedSolutions.contains(index)) {
      expandedSolutions.remove(index);
    } else {
      expandedSolutions.add(index);
    }
  }

  bool isSolutionExpanded(int index) => expandedSolutions.contains(index);

  // ── Question helpers ───────────────────────────────────────────────────────

  Map<String, dynamic> getAnswer(int index) {
    if (index < 0 || index >= answers.length) return {};
    return answers[index];
  }

  Map<String, dynamic> get currentReviewAnswer => getAnswer(reviewIndex.value);

  void goToReviewQuestion(int index) {
    if (index >= 0 && index < answers.length) {
      reviewIndex.value = index;
    }
  }

  String getQuestionTypeName(String type) {
    switch (type) {
      case 'mcq_single':
        return 'MCQ Single';
      case 'mcq_multiple':
        return 'MCQ Multiple';
      case 'numeric':
      case 'integer':
      case 'numerical':
        return 'Numerical';
      case 'text':
        return 'Short Answer';
      case 'subjective':
        return 'Subjective';
      case 'true_false':
        return 'True/False';
      case 'match':
        return 'Match';
      default:
        return type.replaceAll('_', ' ').capitalizeFirst ?? type;
    }
  }

  String getUserAnswerDisplay(Map<String, dynamic> answer) {
    if (answer['isSkipped'] == true) return 'Skipped';
    final raw = answer['answerRaw'];
    if (raw == null) return 'Not Answered';
    return raw.toString();
  }

  String formatDuration(int ms) {
    if (ms <= 0) return '0s';
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String getSectionName(String sectionId) {
    for (var section in sectionResults) {
      final subjectId = section['subjectId'];
      if (subjectId is Map && subjectId['_id'] == sectionId) {
        return _sectionDisplayName(section);
      } else if (subjectId is String && subjectId == sectionId) {
        return section['sectionName']?.toString() ?? sectionId;
      } else if (section['sectionId'] == sectionId) {
        return _sectionDisplayName(section);
      }
    }
    return sectionId;
  }

  String getSubjectName(Map<String, dynamic> section) {
    final subjectId = section['subjectId'];
    if (subjectId is Map) {
      final name = subjectId['subjectName'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
    }
    return (section['sectionName'] ?? section['sectionId'] ?? '').toString();
  }
}
