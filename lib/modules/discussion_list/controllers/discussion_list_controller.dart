import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/services/assigment_api_services.dart';
import 'package:suguna_exam_app/core/services/service_locator.dart';
import 'package:suguna_exam_app/data/models/exam_model.dart';
import 'package:suguna_exam_app/data/services/network_service.dart';
import 'package:suguna_exam_app/data/services/sessions.dart';
import 'package:suguna_exam_app/data/services/store_service.dart';

class DiscussionListController extends GetxController {
  final _apiService = ServiceLocator.get<AssignmentApiServices>();
  final _storage = Get.find<StorageService>();

  var exams = <ExamModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isDownloading = false.obs;
  var downloadingExamId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExams();
  }

  Future<void> fetchExams() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final userData = Session.instance.currentUser?['data'];
      if (userData == null) {
        errorMessage.value = 'User session not found';
        return;
      }

      final response = await _apiService.getExamList(
        userData['tenantId'] ?? '',
        userData['batchCode'] ?? '',
        userData['admissionNo'] ?? '',
      );

      if (response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        exams.value = data.map((e) => ExamModel.fromJson(e)).toList();
      } else {
        errorMessage.value = response['message'] ?? 'Failed to load exams';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load exams: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Check if any exam is currently active (downloaded but not completed) ──
  bool get hasActiveExam {
    final activeExamId = _storage.read('active_exam_id');
    if (activeExamId == null) return false;
    final examData = _storage.read('exam_$activeExamId');
    if (examData == null) return false;
    return examData['completed'] != true;
  }

  String? get activeExamId => _storage.read('active_exam_id');

  // ── Download exam questions ────────────────────────────────────────────────
  Future<void> downloadExam(ExamModel exam, String password) async {
    if (isDownloading.value) return;

    // Check if another exam is active
    final currentActiveId = activeExamId;
    if (currentActiveId != null && currentActiveId != exam.examId) {
      final activeData = _storage.read('exam_$currentActiveId');
      if (activeData != null && activeData['completed'] != true) {
        Get.snackbar(
          'Exam In Progress',
          'Please complete or close the current exam before starting a new one.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    // Check if already downloaded (cached)
    final storageKey = 'exam_${exam.examId}';
    final cached = _storage.read(storageKey);
    if (cached != null) {
      _navigateToExam(exam, cached);
      return;
    }

    // Check internet
    final hasInternet = await NetworkService.hasInternet();
    if (!hasInternet) {
      Get.snackbar(
        'Error',
        'Check your internet connection and try again',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    isDownloading.value = true;
    downloadingExamId.value = exam.examId;

    try {
      final userData = Session.instance.currentUser?['data'];
      final response = await _apiService.getExamQuestions(
        userData?['tenantId'] ?? '',
        exam.examId,
        exam.examCode,
        password,
      );

      if (response['status'] != true) {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to download exam',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
        );
        return;
      }

      final data = response['data'];

      // Flatten all questions from sections into a single list
      final List<dynamic> allQuestions = [];
      final sections = data['sections'] as List<dynamic>? ?? [];
      for (final section in sections) {
        final questions = section['questions'] as List<dynamic>? ?? [];
        for (final q in questions) {
          q['sectionId'] = section['sectionId'];
          q['sectionName'] = section['sectionName'];
          q['sectionCode'] = section['sectionCode'];
          allQuestions.add(q);
        }
      }

      // Download and convert images to base64
      final processedQuestions = await _processExamQuestionImages(allQuestions);

      // Build stored exam data (same structure as assignment storage)
      final examData = {
        'examId': data['examId'],
        'examCode': data['examCode'],
        'examName': data['examName'],
        'duration': data['duration'],
        'totalMarks': data['totalMarks'],
        'totalQuestions': data['totalQuestions'],
        'startTime': data['startTime'],
        'endTime': data['endTime'],
        'calculatorType': data['calculatorType'],
        'instructions': data['instructions'],
        'questions': processedQuestions,
        'sections': sections,
        'completed': false,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Save to local storage
      _storage.save(storageKey, examData);
      _storage.save('active_exam_id', exam.examId);

      _navigateToExam(exam, examData);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download exam: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
    } finally {
      isDownloading.value = false;
      downloadingExamId.value = '';
    }
  }

  // ── Navigate to exam (instructions → test player) ─────────────────────────
  void _navigateToExam(ExamModel exam, Map<dynamic, dynamic> examData) {
    Session.instance.isNewTest = true;
    Session.instance.isRetest = false;
    Session.instance.storedData = null;
    Session.instance.isCompletedAssignment = false;
    Session.instance.currentTestId = 'exam_${exam.examId}';

    // Store active exam id
    _storage.save('active_exam_id', exam.examId);

    // Deep convert to Map<String, dynamic> to avoid type cast issues from GetStorage
    final safeExamData = _deepConvertMap(examData);

    Get.toNamed(
      AppRoutes.assignmentInstructions,
      arguments: {
        'examId': exam.examId,
        'examCode': exam.examCode,
        'testId': exam.examId,
        'selectedQuestion': safeExamData,
      },
    );
  }

  /// Recursively converts Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic> _deepConvertMap(Map data) {
    return data.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepConvertMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _deepConvertList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  List<dynamic> _deepConvertList(List data) {
    return data.map((item) {
      if (item is Map) return _deepConvertMap(item);
      if (item is List) return _deepConvertList(item);
      return item;
    }).toList();
  }

  // ── Image processing helpers ──────────────────────────────────────────────
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
        // 1. Try to get a signed URL from the backend
        String? signedUrl;
        try {
          final signedResponse = await _apiService.downloadExamQuestionImage(url);
          final ok = signedResponse['status'] == true ||
              signedResponse['status']?.toString() == 'true' ||
              signedResponse['success'] == true;
          final returnedUrl = (signedResponse['url'] ?? signedResponse['data']?['url'])?.toString();
          if (ok && returnedUrl != null && returnedUrl.isNotEmpty) {
            signedUrl = returnedUrl;
          }
        } catch (e) {
          print('Exam signed-url API failed for $url: $e');
        }

        // 2. Fall back to the original URL if no signed URL was returned
        final fetchUrl = signedUrl ?? url;
        final bytes = await _apiService.downloadImageBytes(fetchUrl);
        if (bytes.isEmpty) {
          print('Exam image empty bytes for $fetchUrl');
          continue;
        }
        final base64Str = base64Encode(bytes);
        final base64Tag = 'data:${_mimeFromUrl(url)};base64,$base64Str';

        html = html.replaceAll(url, base64Tag);
      } catch (e) {
        print("Exam image convert failed for $url: $e");
      }
    }
    return html;
  }

  Future<List<dynamic>> _processExamQuestionImages(List<dynamic> questions) async {
    for (var question in questions) {
      // Process questionHtml
      if (question['questionHtml'] is String && (question['questionHtml'] as String).isNotEmpty) {
        question['questionHtml'] =
            await _replaceImagesWithBase64(question['questionHtml']);
      }

      // Process passage HTML
      final passage = question['passageData'];
      if (passage is Map && passage['passageHtml'] is String &&
          (passage['passageHtml'] as String).isNotEmpty) {
        passage['passageHtml'] =
            await _replaceImagesWithBase64(passage['passageHtml']);
      }

      // Process options
      if (question['questionOptions'] is List) {
        for (var option in (question['questionOptions'] as List)) {
          if (option is Map && option['textHtml'] is String &&
              (option['textHtml'] as String).isNotEmpty) {
            option['textHtml'] =
                await _replaceImagesWithBase64(option['textHtml']);
          }
        }
      }

      // Process match-the-following columns
      for (final colKey in const ['leftColumn', 'rightColumn']) {
        if (question[colKey] is List) {
          for (var cell in (question[colKey] as List)) {
            if (cell is Map && cell['text'] is String &&
                (cell['text'] as String).isNotEmpty) {
              cell['text'] = await _replaceImagesWithBase64(cell['text']);
            }
            if (cell is Map && cell['textHtml'] is String &&
                (cell['textHtml'] as String).isNotEmpty) {
              cell['textHtml'] = await _replaceImagesWithBase64(cell['textHtml']);
            }
          }
        }
      }

      // Process solutionHtml
      if (question['solutionHtml'] is String &&
          (question['solutionHtml'] as String).isNotEmpty) {
        question['solutionHtml'] =
            await _replaceImagesWithBase64(question['solutionHtml']);
      }
    }
    return questions;
  }

  // ── Tap on exam card ──────────────────────────────────────────────────────
  void onExamTap(ExamModel exam) {
    if (exam.status != "published" && !exam.isResultVisible) {
      Get.snackbar(
        'Not Available',
        'This exam is not available for attempt.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD97706),
        colorText: Colors.white,
      );
      return;
    }

    // If result is visible, go to analysis
    if (exam.isResultVisible) {
      Get.toNamed(AppRoutes.examResult, arguments: {
        'examId': exam.examId,
        'examName': exam.examName,
        'examCode': exam.examCode,
        'totalMarks': exam.totalMarks,
        'totalQuestions': exam.totalQuestions,
        'duration': exam.duration,
      });
      return;
    }

    // If already attempted, restrict download
    if (exam.isAttempted) {
      Get.snackbar(
        'Already Attempted',
        'You have already attempted this exam.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD97706),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Check if already cached
    final storageKey = 'exam_${exam.examId}';
    final cached = _storage.read(storageKey);
    if (cached != null) {
      if (cached['completed'] == true) {
        Get.snackbar(
          'Completed',
          'You have already completed this exam.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
        );
        return;
      }
      // Resume cached exam
      _navigateToExam(exam, cached);
      return;
    }

    // Check active exam restriction
    if (hasActiveExam && activeExamId != exam.examId) {
      Get.snackbar(
        'Exam In Progress',
        'Please complete the current exam before starting a new one.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Show password dialog
    _showPasswordDialog(exam);
  }

  void _showPasswordDialog(ExamModel exam) {
    final passwordCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(exam.examName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${exam.totalQuestions} Questions  •  ${exam.totalMarks} Marks  •  ${exam.duration} min',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter Passcode',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isDownloading.value
                ? null
                : () {
                    if (passwordCtrl.text.isEmpty) {
                      Get.snackbar('Error', 'Please enter passcode');
                      return;
                    }
                    Get.back();
                    downloadExam(exam, passwordCtrl.text);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: isDownloading.value
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Download & Start'),
          )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // ── Download from sidebar (by test ID + passcode) ─────────────────────────
  void downloadByTestId(String testId, String passcode) {
    if (testId.isEmpty) {
      Get.snackbar('Error', 'Please enter a Test ID');
      return;
    }
    if (passcode.isEmpty) {
      Get.snackbar('Error', 'Please enter a Passcode');
      return;
    }



    // Find exam by examCode matching testId
    final exam = exams.firstWhereOrNull(
      (e) => e.examCode == testId || e.examId == testId,
    );

    if (exam == null) {
      Get.snackbar(
        'Not Found',
        'No exam found with ID: $testId',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    // Check if already attempted
    if (exam.isAttempted) {
      Get.snackbar(
        'Already Attempted',
        'You have already attempted this exam.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD97706),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Check if already cached and completed
    final storageKey = 'exam_${exam.examId}';
    final cached = _storage.read(storageKey);
    if (cached != null && cached['completed'] == true) {
      Get.snackbar(
        'Completed',
        'You have already completed this exam.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
      );
      return;
    }

    downloadExam(exam, passcode);
  }
}
