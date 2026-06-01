import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/data/models/subject_model.dart';
import 'package:suguna_exam_app/data/models/topic_model.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/widgets/score_circle.dart';
import 'package:suguna_exam_app/data/services/network_service.dart';
import 'package:suguna_exam_app/data/services/sessions.dart';
import 'package:suguna_exam_app/modules/test_player/controllers/test_player_controller.dart';
import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/store_service.dart';
import '../../test_player/controllers/test_player_parser.dart';
import '../../test_player/views/test_review_view.dart';
import '../views/topic_assignments_view.dart';

class TopicAssignmentsController extends GetxController {
  late final SubjectModel subject;
  final topics = <TopicModel>[].obs;
  final selectedTopicId = ''.obs;
  final isLoading = false.obs;
  final isTestCompleted = false.obs;
  final downloadingSubtopicIds = <String>{}.obs;
  final downloadedSubtopicIds = <String>{}.obs;
  final selectedSubtopicId = Rxn<String>();
  final selectedColumnKey = Rxn<String>();
  final _apiService = ServiceLocator.get<AssignmentApiServices>();
  Map<String, dynamic>? selectedQuestions;

  final selectedTestId = Rxn<String>();

  static TopicAssignmentsController get to => Get.find();
  late final Map<String, dynamic> loginResponse;
  final StorageService _storage = StorageService();
  final storage = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    loginResponse = (_storage.getUser() ?? {})['data'] ?? {};
    if(Get.arguments != null) {
      subject = Get.arguments as SubjectModel;
    }
    // loadTopics();
  }

  Future<void> loadTopics() async {
    isLoading.value = true;

    try {
      final connectivityResult = await NetworkService.hasInternet();
      final String academicYear =
          loginResponse['admissionNo']?.toString() ?? '';
      final String entId = loginResponse['tenantId']?.toString() ?? '';
      final int classNo = loginResponse['classNo'] ?? '';

      // 🔑 Unique key per subject
      final String storageKey = "topics_${subject.id}_$classNo";

      if (connectivityResult) {
        // ================= ONLINE =================
        final response = await _apiService.getAssignmentTopics(
          subject.name,
          classNo,
          academicYear,
          entId,
        );
        // Save API response locally
        storage.saveTopics({storageKey: response});

        topics.value = mapTopicsFromApi(response);

        if (topics.isNotEmpty) {
          selectedTopicId.value = topics.first.id;
        }
      } else {
        final localData = storage.getGetTopics();
        if (localData != null) {
          if (localData.containsKey(storageKey)) {
            final cachedResponse = localData[storageKey];
            topics.value = mapTopicsFromApi(cachedResponse);
            if (topics.isNotEmpty) {
              selectedTopicId.value = topics.first.id;
            }
          } else {
            Get.snackbar(
              "Offline Mode",
              "Topics not cached for this subject yet",
            );
          }
        }
      }

      // ✅ After loading topics, scan storage for cached assignments
      _scanAndPopulateCachedAssignments();
    } catch (e, s) {
      Get.snackbar('Error', 'Failed to load topics: $e');
      print("Came to error ${e}");
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // SCAN STORAGE FOR ALL CACHED ASSIGNMENTS
  // ============================================================

  void _scanAndPopulateCachedAssignments() {
    try {
      // Iterate through all topics and subtopics
      for (final topic in topics) {
        for (final subtopic in topic.subtopics) {
          subtopic.scores.forEach((category, subCategoryMap) {
            subCategoryMap.forEach((subCategory, assignments) {
              for (final assignment in assignments) {
                final key = '${subtopic.id}-$category-${assignment.testId}';
                final questionsStorageKey = "questions_$key";
                if (_storageKeyExists(questionsStorageKey)) {
                  downloadedSubtopicIds.add(key);
                }
              }
            });
          });
        }
      }
      // Trigger UI rebuild to show correct circle colors
      downloadedSubtopicIds.refresh();
    } catch (e) {
      print('❌ Error scanning storage: $e');
    }
  }

  // ============================================================
  // CHECK IF STORAGE KEY EXISTS
  // ============================================================

  bool _storageKeyExists(String key) {
    try {
      final data = storage.read(key);
      final exists = data != null;
      return exists;
    } catch (e) {
      return false;
    }
  }

  List<TopicModel> mapTopicsFromApi(Map<String, dynamic> response) {
    final Map<String, dynamic> subtopicsByTopics =
        response['data']['subtopicsByTopics'];

    final List<TopicModel> topics = [];

    subtopicsByTopics.forEach((categoryName, subtopicsList) {
      final List<SubtopicModel> subtopics = [];

      for (final subtopic in subtopicsList) {
        /// 🔥 Step 1: Collect ALL assignments flat
        final List<TempAssignment> allTests = [];

        for (final test in subtopic['test']) {
          allTests.add(
            TempAssignment(
              category: test['examCategory'] ?? '',
              subCategory: test['examSubCategory'] ?? '',
              assignment: AssignmentScore(
                cgpa: test['cgpa'] == null
                    ? null
                    : double.parse(test['cgpa'].toString()),
                isEnabled: test['isEnabled'],
                status: test['status'],
                testId: test['testId'] ?? '',
                sortOrder: test['sortOrder'] ?? 0,
              ),
            ),
          );
        }

        /// 🔥 Step 2: Sort all tests by sortOrder
        allTests.sort(
          (a, b) => a.assignment.sortOrder.compareTo(b.assignment.sortOrder),
        );

        /// 🔥 Step 3: Extract flat ordered list
        final orderedList = allTests.map((e) => e.assignment).toList();

        /// 🔥 Step 4: Rebuild nested structure with sorted subcategories
        final Map<String, Map<String, List<AssignmentScore>>> scores = {};

        for (final item in allTests) {
          scores
              .putIfAbsent(item.category, () => {})
              .putIfAbsent(item.subCategory, () => [])
              .add(item.assignment);
        }

        /// 🔥 Step 5: Sort assignments within each subcategory
        scores.forEach((category, subcategories) {
          subcategories.forEach((subCategory, assignments) {
            assignments.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          });
        });

        /// 🔥 Step 6: Sort subcategories by their minimum sortOrder
        final sortedScores = Map.fromEntries(
          scores.entries.map((categoryEntry) {
            final sortedSubcategories = Map.fromEntries(
              categoryEntry.value.entries.toList()..sort((a, b) {
                final minOrderA = a.value.isEmpty
                    ? 0
                    : a.value
                          .map((e) => e.sortOrder)
                          .reduce((min, order) => min < order ? min : order);
                final minOrderB = b.value.isEmpty
                    ? 0
                    : b.value
                          .map((e) => e.sortOrder)
                          .reduce((min, order) => min < order ? min : order);
                return minOrderA.compareTo(minOrderB);
              }),
            );
            return MapEntry(categoryEntry.key, sortedSubcategories);
          }),
        );

        subtopics.add(
          SubtopicModel(
            id: subtopic['subtopicId'],
            name: subtopic['subtopicName'],
            phase: subtopic['phases'],
            scores: sortedScores,
            orderedAssignments: orderedList,
          ),
        );
      }

      topics.add(
        TopicModel(id: categoryName, name: categoryName, subtopics: subtopics),
      );
    });

    return topics;
  }

  String normalizeExamCategory(String apiValue) {
    if (apiValue == 'JEE Mains') return 'JEE Main';
    return apiValue;
  }

  void selectTopic(String topicId,TopicModel topic) {
    Session.instance.selectedTopic = topic;
    selectedTopicId.value = topicId;
    selectedSubtopicId.value = null;
    selectedColumnKey.value = null;
  }

  TopicModel? get selectedTopic {
    if (selectedTopicId.value.isEmpty) return null;
    try {
      Session.instance.selectedTopic = topics.firstWhere((t) => t.id == selectedTopicId.value);
      return topics.firstWhere((t) => t.id == selectedTopicId.value);
    } catch (e) {
      return null;
    }
  }

  bool validatePreviousAssignment(
    SubtopicModel subtopic,
    String currentTestId
      ) {
    final List<AssignmentScore> allAssignments = [];

    // 🔥 Flatten ALL categories and subcategories
    subtopic.scores.forEach((category, subMap) {
      for (final list in subMap.values) {
        allAssignments.addAll(list);
      }
    });

    // allAssignments.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (var a in allAssignments) {
      print("${a.testId} | sort: ${a.sortOrder}");
    }

    final currentIndex = allAssignments.indexWhere(
      (a) => a.testId == currentTestId,
    );

    if (currentIndex <= 0) {
      return true; // First assignment allowed
    }

    final previous = allAssignments[currentIndex - 1];
    print("TEst datas ${previous.testId}");
    print("TEst data ${currentTestId}");

    final stored = _readFromStorage("test_${previous.testId}");

    // print("Is compledt ${ stored['completed']}");
    final bool isCompletedFromStorage =
        stored != null && stored['completed'] == true;

    final bool isCompletedFromCgpa = previous.cgpa != null;

    final bool isCompleted = isCompletedFromStorage || isCompletedFromCgpa;

    return isCompleted;
  }

  List<Question> getAllQuestions(List<QuestionCategory> categories) {
    return categories.expand((cat) => cat.questions).toList();
  }

  Map<String, dynamic> buildSubmissionFromApiAndStorage({
    required Map<String, dynamic> questionsApi,
    required Map<String, dynamic> storedResult,
  }) {
    final List<dynamic> questionList =
        questionsApi['data']?['questions'] ?? [];

    final List<dynamic> storedAnswers =
        storedResult['data'][0]['answers'] ?? [];

    // Convert stored answers to map for quick lookup
    final Map<String, dynamic> answerMap = {
      for (var a in storedAnswers)
        a['questionId']: a
    };

    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    final List<Map<String, dynamic>> answers = [];

    for (int i = 0; i < questionList.length; i++) {
      final serverQuestionId = questionList[i]['questionId'];
      final questionNumber = i + 1;

      final stored = answerMap[serverQuestionId];

      final isCorrectVal = stored?['isCorrect'] == true;
      final isSkippedVal = stored?['isSkipped'] == true;

      if (isSkippedVal) {
        skipped++;
      } else if (isCorrectVal) {
        correct++;
      } else {
        wrong++;
      }

      // print("User ansr ${stored['answerRaw']}");

      answers.add({
        'questionNumber': questionNumber,
        'questionId': 'question_$questionNumber',
        'serverQuestionId': serverQuestionId,
        'questionType': questionList[i]['questionType'],
        'userAnswer': stored?['answerRaw'],
        'correctAnswer': questionList[i]['correctAnswer'],
        'isCorrect': isCorrectVal,
        'isSkipped': isSkippedVal,
      });
    }

    final total = questionList.length;
    final percentage = total == 0 ? 0.0 : (correct / total) * 100;

    return {
      'testId': storedResult['testId'],
      'userId':loginResponse['tenantId'],
      'studentId': loginResponse['admissionNo'],
      'score': correct,
      'totalQuestions': total,
      'percentage': percentage,
      'correctAnswers': correct,
      'wrongAnswers': wrong,
      'skippedQuestions': skipped,
      'timeSpent': storedResult['timeSpent'],
      'subjectId': storedResult['subjectId'],
      'subject': storedResult['subject'],
      'subTopic': storedResult['subTopic'],
      'topicName': storedResult['topicName'],
      'subtopic': storedResult['subtopic'],
      'category': storedResult['category'],
      'testNo': questionsApi['data']?['testNo'],
      'numberOfReattempts': storedResult['numberOfReattempts'] ?? 1,
      'timeSpentSeconds': storedResult['timeSpentSeconds'] ?? 0,
      'answers': answers,
      'startedAt': storedResult['startedAt'],
      'completedAt': storedResult['completedAt'],
    };
  }

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
          final signedResponse = await _apiService.downloadQuestionImage(url);
          final ok = signedResponse['status'] == true ||
              signedResponse['status']?.toString() == 'true' ||
              signedResponse['success'] == true;
          final returnedUrl = (signedResponse['url'] ?? signedResponse['data']?['url'])?.toString();
          if (ok && returnedUrl != null && returnedUrl.isNotEmpty) {
            signedUrl = returnedUrl;
          }
        } catch (e) {
          print('Assignment signed-url API failed for $url: $e');
        }

        // 2. Fall back to the original URL if no signed URL was returned
        final fetchUrl = signedUrl ?? url;
        final bytes = await _apiService.downloadImageBytes(fetchUrl);
        if (bytes.isEmpty) {
          print('Assignment image empty bytes for $fetchUrl');
          continue;
        }
        final base64Str = base64Encode(bytes);
        final base64Tag = 'data:${_mimeFromUrl(url)};base64,$base64Str';

        html = html.replaceAll(url, base64Tag);
      } catch (e) {
        print("Image convert failed for $url: $e");
      }
    }

    return html;
  }

  Future<Map<String, dynamic>> _processQuestionImages(
      Map<String, dynamic> response,
      ) async {

    final questions = response['data']?['questions'] ?? [];

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

    return response;
  }

  // ============================================================
  // IMPROVED CIRCLE TAP WITH BETTER STORAGE HANDLING
  // ============================================================

  void onCircleTap(
    String subtopicId,
    String columnKey,
    String testId,
    bool canDownload,
    SubtopicModel subtopic,
    String subCate,
     String category,
  ) async {
    if (!canDownload) {
      final int classNo = loginResponse['classNo'];
      final String academicYear = loginResponse['admissionNo'];
      final String entId = loginResponse['tenantId'];
      List<QuestionCategory> categories = [];
      final response = await _apiService.loadQuestions(
        subject.name,
        classNo,
        testId,
        academicYear,
        entId,
      );
      final data = await _apiService.getAnswers(
        loginResponse['batchId'],
        testId,
        academicYear,
        entId,
      );
      Session.instance.isNewTest = false;
      Session.instance.isRetest = false;
      Session.instance.storedData =   {
        'testId' : '',
        'storedData' : {
          "testJson": response,
          "result":  buildSubmissionFromApiAndStorage(questionsApi: response,storedResult: data),
          "completed": true,
          "numberOfReattempts" : 0,
          "timestamp": DateTime.now().toIso8601String(),
        },
      };
      Session.instance.isCompletedAssignment = true;
      Get.toNamed(AppRoutes.testAnalysis);
      return;
    }
    if (!validatePreviousAssignment(subtopic, testId)) {
      Get.defaultDialog(
        title: "Assignment Locked",
        middleText:
            "Kindly complete the previous assignment before starting a new one.",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        radius: 12,
        barrierDismissible: false,
        // user must press OK
        onConfirm: () {
          Get.back();
        },
      );
      return;
    }

    Session.instance.selectedSub = subCate;
    Session.instance.selectedSubtopic = subtopic;
    Session.instance.selectedCategory = columnKey;


    // 🔑 Create unique key for this assignment
    final key = '$subtopicId-$columnKey-$testId';
    final questionsStorageKey = "questions_$key";

    // ======= UI Selection =======
    selectedSubtopicId.value = subtopicId;
    selectedColumnKey.value = columnKey;
    selectedTestId.value = testId;

    try {
      final cachedQuestions = _readFromStorage(questionsStorageKey);
      final testDataKey = "test_${selectedTestId.value}";
      final stored = _readFromStorage(testDataKey);
      if (stored != null && stored is Map) {
        isTestCompleted.value =
            stored['completed'] == true || stored['data']?['completed'] == true;
      } else {
        isTestCompleted.value = false;
      }

      // Try to read stored test data
      if (cachedQuestions != null) {
        selectedQuestions = cachedQuestions;

        // ✅ Add to downloaded set if not already there
        if (!downloadedSubtopicIds.contains(key)) {
          downloadedSubtopicIds.add(key);
        }

        return;
      }

      // =========================
      // 2️⃣ PREVENT DOUBLE DOWNLOADS
      // =========================
      if (downloadingSubtopicIds.contains(key)) {
        return;
      }

      final connectivityResult = await NetworkService.hasInternet();
      if (!connectivityResult) {
        Get.snackbar(
          'Error',
          'Check your internet connection and try again',
          backgroundColor: Colors.red,
        );
        return;
      }

      downloadingSubtopicIds.add(key);

      // =========================
      // 3️⃣ FETCH FROM API
      // =========================
      final int classNo = loginResponse['classNo'];
      final String academicYear = loginResponse['admissionNo'];
      final String entId = loginResponse['tenantId'];

      final rawResponse = await _apiService.loadQuestions(
        subject.name,
        classNo,
        testId,
        academicYear,
        entId,
      );

      if (rawResponse == null) {
        throw Exception('API returned null response');
      }
      final response = await _processQuestionImages(rawResponse);

      // =========================
      // 4️⃣ SAVE TO LOCAL STORAGE
      // =========================
      _saveToStorage(questionsStorageKey, response);

      selectedQuestions = response;
      downloadedSubtopicIds.add(key);
      downloadedSubtopicIds.refresh();
    } catch (e) {
      // =========================
      // 5️⃣ TRY FALLBACK CACHE
      // =========================
      final fallback = _readFromStorage(questionsStorageKey);
      isTestCompleted.value = false;
      if (fallback != null) {
        selectedQuestions = fallback;

        // ✅ Add to downloaded set
        if (!downloadedSubtopicIds.contains(key)) {
          downloadedSubtopicIds.add(key);
          downloadedSubtopicIds.refresh();
        }

        // Get.snackbar('Offline Mode', 'Using cached questions');
      } else {
        Get.snackbar('Error', 'Failed to load questions: $e');
        selectedSubtopicId.value = null;
        selectedColumnKey.value = null;
        selectedTestId.value = null;
      }
    } finally {
      downloadingSubtopicIds.remove(key);
      downloadingSubtopicIds.refresh();
    }
  }

  // ============================================================
  // IMPROVED START ASSIGNMENT WITH PROPER STORAGE
  // ============================================================

  void startAssignment() {
    if (selectedSubtopicId.value == null ||
        selectedColumnKey.value == null ||
        selectedTestId.value == null) {
      Get.snackbar('Error', 'Please select an assignment first');
      return;
    }
    Session.instance.isCompletedAssignment = false;
    Session.instance.currentTestId = 'test_${selectedTestId.value ?? ''}';
    try {
      final testDataKey = "test_${selectedTestId.value}";
      // Try to read stored test data
      final stored = _readFromStorage(testDataKey);
      if (stored != null && stored is Map) {
        // Verify it has completion flag
        final isCompleted =
            stored['completed'] == true || stored['data']?['completed'] == true;

        if (isCompleted) {
          Session.instance.isNewTest = false;
          Session.instance.isRetest = false;
          Session.instance.storedData = {
            "testId": testDataKey,
            "storedData": stored,
          };

          // Navigate to test analysis
          Get.toNamed(AppRoutes.testAnalysis);
          return;
        }
      }
      try {
        TestPlayerController.to.initData();
        Session.instance.isNewTest = true;
        Session.instance.storedData = null;
        Get.toNamed(
          AppRoutes.assignmentInstructions,
          arguments: {
            'subtopicId': selectedSubtopicId.value,
            'columnKey': selectedColumnKey.value,
            'testId': selectedTestId.value,
            'selectedQuestion': selectedQuestions,
          },
        );

        // Clear selection
        selectedSubtopicId.value = null;
        selectedColumnKey.value = null;
        selectedTestId.value = null;
      } catch (e) {
        Session.instance.isNewTest = true;
        Session.instance.storedData = null;

        Get.toNamed(
          AppRoutes.assignmentInstructions,
          arguments: {
            'subtopicId': selectedSubtopicId.value,
            'columnKey': selectedColumnKey.value,
            'testId': selectedTestId.value,
            'selectedQuestion': selectedQuestions,
          },
        );
        // Clear selection
        selectedSubtopicId.value = null;
        selectedColumnKey.value = null;
        selectedTestId.value = null;
      }
      // No completed test found - start new assignment
    } catch (e) {
      // Default to new assignment if anything goes wrong
      Session.instance.isNewTest = true;
      Session.instance.storedData = null;

      try {
        TestPlayerController.to.initData();
        Get.toNamed(
          AppRoutes.assignmentInstructions,
          arguments: {
            'subtopicId': selectedSubtopicId.value,
            'columnKey': selectedColumnKey.value,
            'testId': selectedTestId.value,
            'selectedQuestion': selectedQuestions,
          },
        );
        selectedSubtopicId.value = null;
        selectedColumnKey.value = null;
        selectedTestId.value = null;
      } catch (e) {
        Get.toNamed(
          AppRoutes.assignmentInstructions,
          arguments: {
            'subtopicId': selectedSubtopicId.value,
            'columnKey': selectedColumnKey.value,
            'testId': selectedTestId.value,
            'selectedQuestion': selectedQuestions,
          },
        );
        selectedSubtopicId.value = null;
        selectedColumnKey.value = null;
        selectedTestId.value = null;
      }
    }
  }

  // ============================================================
  // HELPER METHODS FOR STORAGE
  // ============================================================

  /// Read data from storage with error handling
  dynamic _readFromStorage(String key) {
    try {
      final data = storage.read(key);
      return data;
    } catch (e) {
      print('❌ Error reading from storage [$key]: $e');
      return null;
    }
  }

  /// Save data to storage with error handling
  void _saveToStorage(String key, dynamic value) {
    try {
      storage.save(key, value);
    } catch (e) {
      Get.snackbar('Storage Error', 'Failed to cache data: $e');
    }
  }

  /// Save test results after test completion
  void saveTestResults(String testId, Map<String, dynamic> testData) {
    try {
      final testDataKey = "test_$testId";

      // Ensure completion flag is set
      testData['completed'] = true;
      testData['completedAt'] = DateTime.now().toIso8601String();

      _saveToStorage(testDataKey, testData);
    } catch (e) {
      print('❌ Error saving test results: $e');
    }
  }

  // ============================================================
  // CIRCLE STATE AND STATUS METHODS
  // ============================================================

  bool isSubtopicSelected(String subtopicId, String columnKey, String testId) {
    return selectedSubtopicId.value == subtopicId &&
        selectedColumnKey.value == columnKey &&
        selectedTestId.value == testId;
  }

  /// Get circle state - shows if downloading, downloaded, or default
  CircleState getCircleState(
    String subtopicId,
    String columnKey,
    String testId,
  ) {
    final key = '$subtopicId-$columnKey-$testId';
    if (downloadingSubtopicIds.contains(key)) {
      return CircleState.downloading;
    }

    if (downloadedSubtopicIds.contains(key)) {
      return CircleState.downloaded;
    }

    return CircleState.defaultState;
  }

  AssignmentStatus getAssignmentStatus(
    String subtopicId,
    String columnKey,
    String testId,
    String status,
  ) {
    final key = '$subtopicId-$columnKey-$testId';

    if (status != "ASSIGNED") {
      return AssignmentStatus.locked;
    }

    if (downloadedSubtopicIds.contains(key)) {
      return AssignmentStatus.attempted;
    }

    if (downloadingSubtopicIds.contains(key)) {
      return AssignmentStatus.available;
    }

    return AssignmentStatus.notOpened;
  }

  ScoreLevel? getScoreLevel(double? score, String status) {
    if (status != "COMPLETED" || score == null) {
      return null;
    }

    // TODO: Implement score level calculation from test results
    if (score <= 2.0) {
      return ScoreLevel.extremelyPoor;
    } else if (score <= 4.0) {
      return ScoreLevel.poor;
    } else if (score <= 6.0) {
      return ScoreLevel.notGood;
    } else if (score <= 8.0) {
      return ScoreLevel.moderate;
    } else {
      return ScoreLevel.satisfactory;
    }
  }

  // ============================================================
  // UTILITY: CLEAR STORAGE (for debugging/testing)
  // ============================================================

  void clearAllCache() {
    try {
      downloadedSubtopicIds.clear();
      downloadingSubtopicIds.clear();
      selectedQuestions = null;
      selectedSubtopicId.value = null;
      selectedColumnKey.value = null;
      selectedTestId.value = null;

      downloadedSubtopicIds.refresh();
      downloadingSubtopicIds.refresh();

      Get.snackbar('Cache', 'All cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  String buildQuestionKey(String subtopicId, String columnKey, String testId) {
    return '$subtopicId-$columnKey-$testId';
  }
}
