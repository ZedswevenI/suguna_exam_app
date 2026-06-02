import 'package:get/get.dart';

import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/sessions.dart';

/// Lightweight controller for the post-submit / not-yet-published "Exam
/// Analysis" screen. Calls `/exam/result/my-result/analysis` (same response
/// shape as the full result) and exposes the section/subject breakdown.
class ExamAnalysisController extends GetxController {
  final _apiService = ServiceLocator.get<AssignmentApiServices>();

  final resultData = Rxn<Map<String, dynamic>>();
  final examInfo = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      examInfo.value = args;
    }
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final userData = Session.instance.currentUser?['data'];
      final args = examInfo.value ?? {};
      final entiId = userData?['tenantId'] ?? args['entiId'] ?? '';
      final examId = args['examId'] ?? '';
      final admissionNo =
          userData?['admissionNo'] ?? args['admissionNo'] ?? '';

      final response =
      await _apiService.getExamAnalysis(entiId, examId, admissionNo);

      if (response is Exception) {
        errorMessage.value = response.toString();
        return;
      }
      if (response['status'] == true) {
        resultData.value = Map<String, dynamic>.from(response['data'] as Map);
      } else {
        errorMessage.value = response['message'] ?? 'Failed to load analysis';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load analysis: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void retry() => _loadAnalysis();

  // ── Computed accessors (same shape as ExamResultController) ─────────────

  Map<String, dynamic> get data => resultData.value ?? {};

  String get examCode {
    final args = examInfo.value ?? {};
    return (data['examCode'] ?? args['examCode'] ?? '').toString();
  }

  String get examName {
    final args = examInfo.value ?? {};
    return (data['examName'] ?? args['examName'] ?? 'Exam').toString();
  }

  List<Map<String, dynamic>> get answers {
    final list = data['answers'];
    if (list == null) return [];
    return List<Map<String, dynamic>>.from(list);
  }

  List<Map<String, dynamic>> get sectionResults {
    try {
      final list = data['sectionResults'];
      if (list != null && (list as List).isNotEmpty) {
        final sections = list
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (sections.any(
                (s) => ((s['totalQuestions'] as num?)?.toInt() ?? 0) > 0)) {
          return sections;
        }
      }
    } catch (_) {}
    return _computeSectionResultsFromAnswers();
  }

  List<Map<String, dynamic>> _computeSectionResultsFromAnswers() {
    final Map<String, Map<String, dynamic>> sectionMeta = {};
    final rawSections = data['sectionResults'];
    if (rawSections is List) {
      for (var s in rawSections) {
        if (s is Map) {
          final section = Map<String, dynamic>.from(s);
          final subjectId = section['subjectId'];
          String? sid;
          if (subjectId is Map) sid = subjectId['_id']?.toString();
          sid ??= section['sectionId']?.toString();
          if (sid != null) sectionMeta[sid] = section;
        }
      }
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var a in answers) {
      final sid = (a['sectionId'] ?? '').toString();
      grouped.putIfAbsent(sid, () => []).add(a);
    }

    return grouped.entries.map((entry) {
      final sectionId = entry.key;
      final sectionAnswers = entry.value;
      int correct = 0, wrong = 0, skipped = 0, answered = 0;
      double obtained = 0, total = 0;
      int timeTaken = 0;

      for (var a in sectionAnswers) {
        total += (a['positiveMarks'] as num?)?.toDouble() ?? 0;
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
          obtained += (a['marksAwarded'] as num?)?.toDouble() ?? 0;
        }
      }

      final meta = sectionMeta[sectionId];
      return {
        'sectionId': sectionId,
        'subjectId': meta?['subjectId'] ?? sectionId,
        'sectionName': _sectionDisplayName(meta ?? {'sectionId': sectionId}),
        'totalQuestions': sectionAnswers.length,
        'correctCount': correct,
        'wrongCount': wrong,
        'skippedCount': skipped,
        'answeredCount': answered,
        'obtainedMarks': obtained,
        'totalMarks': total,
        'timeTaken': timeTaken,
      };
    }).toList();
  }

  String _sectionDisplayName(Map<String, dynamic> section) {
    final subjectId = section['subjectId'];
    if (subjectId is Map) {
      final name = subjectId['subjectName'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
    }
    return (section['sectionName'] ?? section['sectionId'] ?? '').toString();
  }

  // Overall correct/wrong/skipped stats — used by the donut chart center label.
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

  // Section-wise summary used by the bar chart.
  List<Map<String, dynamic>> getSectionReport() {
    return sectionResults.map((section) {
      return {
        'sectionId': section['sectionId'],
        'sectionName': _sectionDisplayName(section),
        'correct': (section['correctCount'] as num?)?.toInt() ?? 0,
        'wrong': (section['wrongCount'] as num?)?.toInt() ?? 0,
        'skipped': (section['skippedCount'] as num?)?.toInt() ?? 0,
      };
    }).toList();
  }

  // Performance Report 1 — section-wise with +ve/-ve marks
  Map<String, dynamic> getPerformanceReport() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var a in answers) {
      final sid = a['sectionId'] ?? '';
      grouped.putIfAbsent(sid, () => []).add(a);
    }

    double grandPositive = 0,
        grandNegative = 0,
        grandTotal = 0,
        grandObtained = 0;
    int grandCorrect = 0, grandWrong = 0;

    final subjects = sectionResults.map((section) {
      final sId = section['sectionId'] ?? '';
      final name = _sectionDisplayName(section);
      final sectionAnswers = grouped[sId] ?? [];
      double positiveMarks = 0, negativeMarks = 0, totalMarks = 0;
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

      if (sectionAnswers.isEmpty) {
        totalMarks = (section['totalMarks'] as num?)?.toDouble() ?? 0.0;
      }

      final totalScore = positiveMarks - negativeMarks;
      grandPositive += positiveMarks;
      grandNegative += negativeMarks;
      grandTotal += totalMarks;
      grandObtained += totalScore;
      grandCorrect += correct;
      grandWrong += wrong;

      return {
        'subjectName': name,
        'correct': correct,
        'wrong': wrong,
        'positiveMarks': positiveMarks,
        'negativeMarks': negativeMarks,
        'totalMarks': totalMarks,
        'totalScore': totalScore,
      };
    }).toList();

    return {
      'subjects': subjects,
      'correct': grandCorrect,
      'wrong': grandWrong,
      'positiveMarks': grandPositive,
      'negativeMarks': grandNegative,
      'totalMarks': grandTotal,
      'totalScore': grandObtained,
    };
  }
}
