import 'dart:convert';

import 'package:get/get.dart';

import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/sessions.dart';

/// Shows the question paper (no answer key, no marks) for a student who was
/// absent for the exam. Reached from [ExamResultController] when
/// `/exam/result/my-result/with/questions` comes back with
/// `status:false, message:"Result not found for this student"`.
class AbsentExamQuestionsController extends GetxController {
  final _apiService = ServiceLocator.get<AssignmentApiServices>();

  final examInfo = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final sections = <Map<String, dynamic>>[].obs;
  final selectedSectionIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      examInfo.value = args;
    }
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final args = examInfo.value ?? {};
      final userData = Session.instance.currentUser?['data'];
      final tenantId = (userData?['tenantId'] ?? args['tenantId'] ?? '').toString();
      final examId = (args['examId'] ?? '').toString();
      final examCode = (args['examCode'] ?? '').toString();

      final response =
          await _apiService.getAbsentExamQuestions(tenantId, examId, examCode);

      if (response['status'] == true) {
        final data = Map<String, dynamic>.from(response['data'] as Map);

        // `sections` is metadata only (id/name/order); the actual questions
        // are a flat list under `questions`, each carrying its own sectionId.
        final sectionMeta = ((data['sections'] as List?) ?? [])
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList()
          ..sort((a, b) => ((a['sortOrder'] as num?) ?? 0)
              .compareTo((b['sortOrder'] as num?) ?? 0));

        final processedQuestions = <Map<String, dynamic>>[];
        for (final q in ((data['questions'] as List?) ?? [])) {
          final question = Map<String, dynamic>.from(q as Map);
          await _processQuestionImages(question);
          processedQuestions.add(question);
        }

        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final q in processedQuestions) {
          final sid = (q['sectionId'] ?? '').toString();
          grouped.putIfAbsent(sid, () => []).add(q);
        }

        final processed = <Map<String, dynamic>>[];
        for (final meta in sectionMeta) {
          final sid = (meta['sectionId'] ?? '').toString();
          processed.add({
            'sectionId': sid,
            'sectionName': (meta['sectionName'] ?? sid).toString(),
            'questions': grouped.remove(sid) ?? const <Map<String, dynamic>>[],
          });
        }
        // Any question whose sectionId wasn't in the section-metadata list
        // still gets shown rather than silently dropped.
        grouped.forEach((sid, qs) {
          processed.add({'sectionId': sid, 'sectionName': sid, 'questions': qs});
        });

        sections.value = processed;
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to load question paper';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load question paper: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void retry() => _loadQuestions();

  void selectSection(int index) {
    if (index >= 0 && index < sections.length) {
      selectedSectionIndex.value = index;
    }
  }

  String get examName => (examInfo.value?['examName'] ?? 'Exam').toString();
  String get examCode => (examInfo.value?['examCode'] ?? '').toString();

  List<String> get sectionNames =>
      sections.map((s) => (s['sectionName'] ?? '').toString()).toList();

  List<Map<String, dynamic>> get filteredQuestions {
    if (sections.isEmpty) return [];
    final idx = selectedSectionIndex.value < sections.length
        ? selectedSectionIndex.value
        : 0;
    return List<Map<String, dynamic>>.from(
        sections[idx]['questions'] as List? ?? []);
  }

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
    final ext =
        url.split('?').first.split('#').first.split('.').last.toLowerCase();
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
          final returnedUrl =
              (signed['url'] ?? signed['data']?['url'])?.toString();
          if (ok && returnedUrl != null && returnedUrl.isNotEmpty) {
            signedUrl = returnedUrl;
          }
        } catch (e) {
          print('Absent-questions signed-url failed for $url: $e');
        }
        final fetchUrl = signedUrl ?? url;
        final bytes = await _apiService.downloadImageBytes(fetchUrl);
        if (bytes.isEmpty) continue;
        final base64Tag =
            'data:${_mimeFromUrl(url)};base64,${base64Encode(bytes)}';
        html = html.replaceAll(url, base64Tag);
      } catch (e) {
        print('Absent-questions image convert failed for $url: $e');
      }
    }
    return html;
  }

  /// Converts <span class="latex">$...$</span> to \(...\) for TeXView rendering
  static String _stripLatexSpans(String html) {
    var result = html.replaceAllMapped(
      RegExp(r'<span\s+class="latex">\s*(.*?)\s*</span>', dotAll: true),
      (match) => match.group(1) ?? '',
    );
    result = result.replaceAllMapped(
      RegExp(r'\$(.+?)\$', dotAll: true),
      (match) => '\\(${match.group(1)}\\)',
    );
    return result;
  }

  Future<void> _processQuestionImages(Map<String, dynamic> question) async {
    if (question['questionHtml'] is String &&
        (question['questionHtml'] as String).isNotEmpty) {
      question['questionHtml'] = await _replaceImagesWithBase64(
          _stripLatexSpans(question['questionHtml'] as String));
    }
    for (final key in const ['solutionHtml', 'solutionText', 'solution']) {
      if (question[key] is String && (question[key] as String).isNotEmpty) {
        question[key] = await _replaceImagesWithBase64(
            _stripLatexSpans(question[key] as String));
      }
    }
    final passage = question['passageData'];
    if (passage is Map &&
        passage['passageHtml'] is String &&
        (passage['passageHtml'] as String).isNotEmpty) {
      passage['passageHtml'] = await _replaceImagesWithBase64(
          _stripLatexSpans(passage['passageHtml'] as String));
    }
    if (question['questionOptions'] is List) {
      final opts = <Map<String, dynamic>>[];
      for (final opt in (question['questionOptions'] as List)) {
        final option = Map<String, dynamic>.from(opt as Map);
        if (option['textHtml'] is String &&
            (option['textHtml'] as String).isNotEmpty) {
          option['textHtml'] = await _replaceImagesWithBase64(
              _stripLatexSpans(option['textHtml'] as String));
        }
        opts.add(option);
      }
      question['questionOptions'] = opts;
    }
    for (final colKey in const ['leftColumn', 'rightColumn']) {
      if (question[colKey] is! List) continue;
      final cells = <Map<String, dynamic>>[];
      for (final c in (question[colKey] as List)) {
        final cell = Map<String, dynamic>.from(c as Map);
        for (final key in const ['text', 'textHtml']) {
          if (cell[key] is String && (cell[key] as String).isNotEmpty) {
            cell[key] = await _replaceImagesWithBase64(
                _stripLatexSpans(cell[key] as String));
          }
        }
        cells.add(cell);
      }
      question[colKey] = cells;
    }
  }
}
