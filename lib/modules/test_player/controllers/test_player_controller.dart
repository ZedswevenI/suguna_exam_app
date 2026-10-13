import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/data/services/sessions.dart';
import 'package:suguna_exam_app/modules/test_analysis/views/test_analysis_view.dart';
import 'package:suguna_exam_app/modules/test_player/controllers/test_player_parser.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/bookmarks.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/services/network_service.dart';
import '../../../data/services/store_service.dart';
import '../../topic_assignments/controllers/topic_assignments_controller.dart';
import '../views/test_review_view.dart';

import 'package:flutter/services.dart';

enum CalculatorType { none, basic, scientific }

class TestPlayerController extends GetxController {
  final TextEditingController numericalController = TextEditingController();
  final Rx<SubjectModel?> selectedSubject = Rx<SubjectModel?>(null);
  static const _lockChannel = MethodChannel('exam_lock');


  final selectedSubjectFilter = 'All'.obs;
  List<Subject> availableSubjects = [];

  bool showCalculator = false;
  CalculatorType calculatorType = CalculatorType.basic;

  void toggleCalculator() {
    showCalculator = !showCalculator;
    updateView();
  }

  void setCalculatorType(CalculatorType type) {
    calculatorType = type;
    updateView();
  }

  void _parseCalculatorType(Map<String, dynamic> json) {
    final type = (json['calculatorType'] ?? json['calculator_type'] ?? '')
        .toString()
        .toLowerCase();
    if (type == 'scientific') {
      calculatorType = CalculatorType.scientific;
    } else if (type == 'normal' || type == 'basic') {
      calculatorType = CalculatorType.basic;
    } else {
      calculatorType = CalculatorType.none;
    }
  }

  void updateView() => update(['palette']);

  void updateNewView() => update(['new']);

  final textSize = 1.obs;
  List<QuestionCategory> categories = [];
  bool isLoading = true;

  final storage = Get.find<StorageService>();
  late String currentTestId;
  final bookmarkedQuestions = <String>{}.obs;

  Map<String, dynamic> selectedQuestions = {};

  static TestPlayerController get to => Get.find();
  final _apiService = ServiceLocator.get<AssignmentApiServices>();

  DateTime startedAt = DateTime.now();
  int totalReAttempts = 1;

  final bookmarks = <Bookmark>[].obs;

  DateTime? _questionStartTime;
  final Map<int, int> questionTimeSpent = {}; // questionNumber → seconds


  @override
  void onInit() {
    super.onInit();
    // Native reports Home / Recents presses mid-exam (onUserLeaveHint).
    // Treat it exactly like Back: open the submit confirmation.
    _lockChannel.setMethodCallHandler((call) async {
      if (call.method == 'homePressed') {
        print('exam_lock: homePressed received');
        openSubmitConfirmation();
      }
      return null;
    });
  }

  /// When the exam lock was engaged. Native can report spurious "left the
  /// app" signals while lock-task / screen pinning is being set up right
  /// after start, so prompts within this grace period are ignored.
  DateTime? _lockStartedAt;
  static const _startupGrace = Duration(seconds: 4);

  /// Set while a deferred prompt is waiting to open, so the same event
  /// arriving twice (onUserLeaveHint + focus loss, or Home + resume) can't
  /// stack two dialogs.
  bool _submitPromptPending = false;

  /// Opens the "type SUBMIT" confirmation if it isn't already showing and
  /// the exam is still in progress. Shared by Back, Home and app-resume.
  /// Slightly deferred so it never runs inside a platform/lifecycle callback.
  void openSubmitConfirmation() {
    if (_submitPromptPending) return;
    final startedAt = _lockStartedAt;
    if (startedAt != null &&
        DateTime.now().difference(startedAt) < _startupGrace) {
      print('exam_lock: ignoring submit prompt during start-up grace');
      return;
    }
    _submitPromptPending = true;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _submitPromptPending = false;
      if (isClosed) return;
      if (Get.isDialogOpen ?? false) return;
      if (isTestCompleted.value || isSubmitting.value) return;
      if (Get.context == null) return;
      try {
        completeTest();
      } catch (e) {
        print('openSubmitConfirmation failed: $e');
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Load actual API data after the view is built
    initData();
  }

  Future<void> initData() async {
    try {
      currentQuestionIndex.value = 0;
      if (Session.instance.storedData != null) {
        if (!Session.instance.isRetest) {
          currentTestId = Session.instance.currentTestId;
          final stored = Session.instance.storedData!['storedData'];
          totalReAttempts = Session.instance.storedData!['storedData']['numberOfReattempts'] ?? 1;
          categories = await TestApiParser.parseFromJsonString(
            stored['testJson'],
          );
          selectedQuestions = stored['testJson'];
          _parseCalculatorType(stored['testJson']);
          final List answers = stored['result']['answers'] ?? [];
          for (var item in answers) {
            final questionNumber = item['questionNumber'];
            final correctAnswer = item['correctAnswer'];
            if (questionNumber != null && correctAnswer != null) {
              correctAnswersMap['question_$questionNumber'] = correctAnswer;
            }
          }
          _restoreUserAnswers(stored['result']['answers']);
          _extractSubjects();
          _loadBookmarks();
          update();
        } else {
          takeRetest();
          startedAt = DateTime.now();
        }
      } else {
        startTestAgain();
      }
    } catch (e, s) {
      print('initData error: $e');
      print('Stack: $s');
      isLoading = false;
    }
  }

  Future<void> lockScreen() async {
    _unlocked = false;
    _lockStartedAt = DateTime.now();
    try {
      await _lockChannel.invokeMethod('startLock');
    } catch (e) {
      print('Lock error: $e');
    }
  }

  bool _unlocked = false;
  Future<void> unlockScreen() async {
    // Idempotent — calling stopLockTask twice under MDM has been observed to
    // crash the activity. Only the first invocation actually hits native.
    if (_unlocked) return;
    _unlocked = true;
    try {
      await _lockChannel.invokeMethod('stopLock');
    } catch (e) {
      print('Unlock error: $e');
    }
  }

  /// Unlocks once the player route has been torn down. Must NOT run during
  /// the route transition itself (crashes under MDM lock-task), and must not
  /// `await` Get.offAllNamed — that future only completes when the *new*
  /// route is popped, so anything after it would never run.
  void _unlockAfterNavigation() {
    Future<void>.delayed(const Duration(milliseconds: 600), unlockScreen);
  }


  void _restoreUserAnswers(List<dynamic> savedAnswers) {
    final allQuestions = getAllQuestions();
    for (var saved in savedAnswers) {
      final number = saved['questionNumber'];
      final question = allQuestions.firstWhere((q) => q.number == number);
      final userAnswer = saved['userAnswer'];
      switch (question.type) {
        case QuestionType.mcqSingle:
        case QuestionType.trueFalse:
        case QuestionType.singleDropdown:
          question.selectedAnswer = userAnswer != null && userAnswer.isNotEmpty ? userAnswer : null;
          break;

        case QuestionType.mcqMultiple:
        case QuestionType.multiDropdown:
          question.selectedAnswers =  userAnswer != null && userAnswer.isNotEmpty
              ? userAnswer.split(';')
              : [];
          break;

        case QuestionType.integer:
        case QuestionType.numerical:
          question.numericalAnswer =  userAnswer != null ? double.tryParse(userAnswer) : null;
          break;

        case QuestionType.textType:
        case QuestionType.subjective:
          question.textAnswer = userAnswer ?? '';
          break;

        case QuestionType.matchTheFollowing:
          final map = <String, List<String>>{};
          for (var pair in userAnswer.split(';')) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              map[parts[0]] = parts[1].contains(',')
                  ? parts[1].split(',').where((s) => s.isNotEmpty).toList()
                  : parts[1].split('').toList();
            }
          }
          question.matchAnswers = map;
          break;
      }
    }
  }

  bool get isExamMode => Session.instance.currentTestId.startsWith('exam_');

  String get examCode {
    if (isExamMode) {
      return selectedQuestions['examCode']?.toString() ??
          selectedQuestions['examName']?.toString() ??
          "Exam";
    } else {
      return selectedQuestions['data']?['testNo']?.toString() ??
          selectedQuestions['testNo']?.toString() ??
          "Test";
    }
  }

  void startTestAgain() {
    startedAt = DateTime.now();
    currentTestId = Session.instance.currentTestId;
    final rawStored = storage.read(currentTestId);
    final stored = rawStored is Map ? Map<String, dynamic>.from(rawStored) : null;
    totalReAttempts = stored == null || stored['numberOfReattempts'] == null ? 1 :  stored['numberOfReattempts'] + 1;

    if (isExamMode) {
      _startExam();
      return;
    }

    try {
      selectedQuestions = TopicAssignmentsController.to.selectedQuestions ?? {};
      loadTestData(_getApiResponse());
      _startTimer();
    } catch (e) {
      // Fallback: try to load from Get.arguments
      final args = Get.arguments;
      if (args != null && args['selectedQuestion'] != null) {
        selectedQuestions = args['selectedQuestion'];
      }
      loadTestData(_getApiResponse());
      _startTimer();
    }
  }

  void _startExam() {
    try {
      isLoading = true;
      categories.clear();
      currentTestId = Session.instance.currentTestId;

      // Get exam data from arguments or storage
      final args = Get.arguments;
      Map<String, dynamic> examData;
      if (args != null && args['selectedQuestion'] != null) {
        examData = _deepConvertMap(args['selectedQuestion']);
      } else {
        final stored = storage.read(currentTestId);
        examData = stored != null ? _deepConvertMap(stored) : {};
      }

      if (examData.isEmpty || examData['questions'] == null) {
        print('ERROR: No exam data found for $currentTestId');
        isLoading = false;
        update();
        return;
      }

      selectedQuestions = examData;

      // Set exam duration (API gives minutes, convert to seconds)
      final durationMinutes = examData['duration'] ?? 30;
      totalDurationSeconds = durationMinutes * 60;
      remainingSeconds.value = totalDurationSeconds;

      final parsed = TestApiParser.parseExamResponse(examData);
      if (parsed.isEmpty) {
        print('ERROR: parseExamResponse returned empty categories');
        isLoading = false;
        update();
        return;
      }
      categories.addAll(parsed);
      _parseCalculatorType(examData);
      _extractSubjects();
      isLoading = false;
      _startTimer();
      update();
    } catch (e, s) {
      print('_startExam error: $e');
      print('Stack: $s');
      isLoading = false;
      update();
    }
  }

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

  void takeRetest() async {
    isLoading = true;
    updateView();
    categories.clear();
    currentTestId = Session.instance.currentTestId;
    selectedQuestions = Session.instance.storedData!['storedData']['testJson'];
    final stored = storage.read(currentTestId);
    totalReAttempts = stored == null || stored['numberOfReattempts'] == null ? 1 :  stored['numberOfReattempts'] + 1;
    final Map<String, dynamic> jsonData = selectedQuestions;
    categories.addAll(await TestApiParser.parseFromJsonString(jsonData));
    _parseCalculatorType(jsonData);
    _extractSubjects();
    isLoading = false;
    _startTimer();
    updateView();
  }

  // Method to load test data from API
  void loadTestData(String jsonString) async {
    isLoading = true;
    updateView();
    categories.clear();
    if (isExamMode) {
      categories.addAll(TestApiParser.parseExamResponse(selectedQuestions));
      _parseCalculatorType(selectedQuestions);
    } else {
      final Map<String, dynamic> jsonData =
          TopicAssignmentsController.to.selectedQuestions ?? {};
      categories.addAll(await TestApiParser.parseFromJsonString(jsonData));
      _parseCalculatorType(jsonData);
    }
    _extractSubjects();
    isLoading = false;
    updateView();
  }

  // Actual API response from your server
  String _getApiResponse() {
    return '''
    
    ''';
  }

  void selectAnswer(String answer) {
    if (isTimerCompleted) return;
    final question = currentQuestion;

    switch (question.type) {
      case QuestionType.mcqSingle:
      case QuestionType.trueFalse:
      case QuestionType.singleDropdown:
        question.selectedAnswer = answer;
        break;
      case QuestionType.mcqMultiple:
      case QuestionType.multiDropdown:
        question.selectedAnswers ??= [];
        if (question.selectedAnswers!.contains(answer)) {
          question.selectedAnswers!.remove(answer);
        } else {
          question.selectedAnswers!.add(answer);
        }
        break;
      default:
        break;
    }

    if (question.status == QuestionStatus.notVisited) {
      question.status = QuestionStatus.answered;
    }
    updateView();
  }

  void setTextAnswer(String text) {
    if (isTimerCompleted) return;
    currentQuestion.textAnswer = text;
    if (currentQuestion.status == QuestionStatus.notVisited) {
      currentQuestion.status = QuestionStatus.answered;
    }
    updateView();
  }


  void selectMatch(String left, String right) {
    if (isTimerCompleted) return;
    currentQuestion.matchAnswers ??= {};
    final list = currentQuestion.matchAnswers![left] ?? [];
    if (list.contains(right)) {
      list.remove(right);
    } else {
      list.add(right);
    }
    currentQuestion.matchAnswers![left] = list;
    if (currentQuestion.status == QuestionStatus.notVisited) {
      currentQuestion.status = QuestionStatus.answered;
    }
    updateView();
  }

  void setNumericalAnswer(double value) {
    if (isTimerCompleted) return;
    currentQuestion.numericalAnswer = value;
    if (currentQuestion.status == QuestionStatus.notVisited) {
      currentQuestion.status = QuestionStatus.answered;
    }
    updateView();
  }

  final currentCategoryIndex = 0.obs;
  final currentQuestionIndex = 0.obs;

  void setTextSize(int size) {
    textSize.value = size;
    updateView();
  }

  double getQuestionFontSize() {
    switch (textSize.value) {
      case 0:
        return 14.0; // Small - A
      case 1:
        return 16.0; // Medium - A+
      case 2:
        return 18.0; // Large - A++
      default:
        return 16.0;
    }
  }

  double getOptionFontSize() {
    switch (textSize.value) {
      case 0:
        return 13.0; // Small
      case 1:
        return 15.0; // Medium
      case 2:
        return 17.0; // Large
      default:
        return 17.0;
    }
  }

  QuestionCategory get currentCategory =>
      categories[currentCategoryIndex.value];

  Question get currentQuestion =>
      currentCategory.questions[currentQuestionIndex.value];

  void selectCategory(int index) {
    _recordTimeForCurrentQuestion();
    currentCategoryIndex.value = index;
    currentQuestionIndex.value = 0;
    _syncNumericalField();
    _syncSubjectFilter();
    _startQuestionTimer();
    updateView();
  }

  void selectQuestion(int categoryIndex, int questionIndex) {
    _recordTimeForCurrentQuestion();
    currentCategoryIndex.value = categoryIndex;
    currentQuestionIndex.value = questionIndex;
    _syncNumericalField();
    _syncSubjectFilter();
    _startQuestionTimer();
    updateView();
  }

  // void selectAnswer(String answer) {
  //   currentQuestion.selectedAnswer = answer;
  //   if (currentQuestion.status == QuestionStatus.notVisited) {
  //     currentQuestion.status = QuestionStatus.answered;
  //   }
  //   updateView();
  // }

  void saveAndNext() {
    _recordTimeForCurrentQuestion();
    final question = currentQuestion;

    bool isAnswered = false;

    switch (question.type) {
      case QuestionType.mcqSingle:
      case QuestionType.trueFalse:
      case QuestionType.singleDropdown:
        isAnswered = question.selectedAnswer != null;
        break;

      case QuestionType.mcqMultiple:
      case QuestionType.multiDropdown:
        isAnswered =
            question.selectedAnswers != null &&
            question.selectedAnswers!.isNotEmpty;
        break;

      case QuestionType.matchTheFollowing:
        isAnswered =
            question.matchAnswers != null &&
            question.matchAnswers!.isNotEmpty;
        break;

      case QuestionType.integer:
      case QuestionType.numerical:
        isAnswered = question.numericalAnswer != null;
        break;

      case QuestionType.textType:
      case QuestionType.subjective:
        isAnswered =
            question.textAnswer != null &&
            question.textAnswer!.trim().isNotEmpty;
        break;
    }

    question.status = isAnswered
        ? QuestionStatus.answered
        : QuestionStatus.notAnswered;

    if (isAllAnswered) {
      _showAllAnsweredDialog();
      updateView();
      return;
    }

    _goToNextQuestion();
  }

  bool _isQuestionAttempted(Question q) {
    switch (q.type) {
      case QuestionType.mcqSingle:
      case QuestionType.trueFalse:
      case QuestionType.singleDropdown:
        return q.selectedAnswer != null;
      case QuestionType.mcqMultiple:
      case QuestionType.multiDropdown:
        return q.selectedAnswers != null && q.selectedAnswers!.isNotEmpty;
      case QuestionType.matchTheFollowing:
        return q.matchAnswers != null && q.matchAnswers!.isNotEmpty;
      case QuestionType.integer:
      case QuestionType.numerical:
        return q.numericalAnswer != null;
      case QuestionType.textType:
      case QuestionType.subjective:
        return q.textAnswer != null && q.textAnswer!.trim().isNotEmpty;
    }
  }

  bool get isAllAnswered {
    for (var cat in categories) {
      for (var q in cat.questions) {
        if (!_isQuestionAttempted(q)) return false;
      }
    }
    return categories.isNotEmpty;
  }

  void _showAllAnsweredDialog() {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 12),
            Text('All Done!'),
          ],
        ),
        content: const Text(
          'You have answered all the questions. Please submit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Review'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              completeTest();
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void clearResponse() {
    final question = currentQuestion;
    question.selectedAnswer = null;
    question.selectedAnswers = null;
    question.matchAnswers = null;
    question.numericalAnswer = null;
    question.textAnswer = null;
    numericalController.clear(); // 👈 clears UI instantly

    // Clearing resets the question completely — whatever its previous
    // status, it goes back to Not Visited in the palette.
    question.status = QuestionStatus.notVisited;
    updateView();
  }


  void saveAndMarkForReview() {
    _recordTimeForCurrentQuestion();
    currentQuestion.status = _isQuestionAttempted(currentQuestion)
        ? QuestionStatus.answeredAndMarked
        : QuestionStatus.markedForReview;
    _goToNextQuestion();
  }

  void markForReviewAndNext() {
    _recordTimeForCurrentQuestion();
    clearResponse();
    currentQuestion.status = QuestionStatus.markedForReview;
    // if (currentQuestion.selectedAnswer != null) {
    //   currentQuestion.status = QuestionStatus.answeredAndMarked;
    // } else {
    //   currentQuestion.status = QuestionStatus.markedForReview;
    // }
    _goToNextQuestion();
  }

  void previous() {
    _recordTimeForCurrentQuestion();
    numericalController.clear();

    final filtered = filteredCategories;

    if (filtered.isEmpty) {
      // No filter active — raw navigation
      if (currentQuestionIndex.value > 0) {
        currentQuestionIndex.value--;
      } else if (currentCategoryIndex.value > 0) {
        currentCategoryIndex.value--;
        currentQuestionIndex.value = currentCategory.questions.length - 1;
      }
    } else {
      // Find current question in filtered view
      final currentQ = currentQuestion;
      int filteredCatIdx = -1;
      int filteredQIdx = -1;

      for (int ci = 0; ci < filtered.length; ci++) {
        final qi = filtered[ci].questions.indexWhere((q) => q.number == currentQ.number);
        if (qi != -1) {
          filteredCatIdx = ci;
          filteredQIdx = qi;
          break;
        }
      }

      if (filteredCatIdx != -1) {
        if (filteredQIdx > 0) {
          // Previous question in same filtered category
          _jumpToQuestion(filtered[filteredCatIdx].questions[filteredQIdx - 1].number);
        } else if (filteredCatIdx > 0) {
          // Last question of previous filtered category (same subject)
          _jumpToQuestion(filtered[filteredCatIdx - 1].questions.last.number);
        } else {
          // First question of current subject — switch to previous subject
          final currentSubject = selectedSubjectFilter.value;
          final currentSubjectIdx = availableSubjects.indexWhere((s) => s.name == currentSubject);
          if (currentSubjectIdx > 0) {
            final prevSubject = availableSubjects[currentSubjectIdx - 1];
            setSubjectFilter(prevSubject.name);
            // Navigate to last question of the previous subject
            final prevFiltered = filteredCategories;
            if (prevFiltered.isNotEmpty) {
              _jumpToQuestion(prevFiltered.last.questions.last.number);
            }
          }
          // else: first subject, first question — do nothing
        }
      }
    }

    _syncNumericalField();
    _syncSubjectFilter();
    _startQuestionTimer();
    updateView();
  }

  void _goToNextQuestion() {
    numericalController.clear();

    final filtered = filteredCategories;

    if (filtered.isEmpty) {
      // No filter active — raw navigation
      if (currentQuestionIndex.value < currentCategory.questions.length - 1) {
        currentQuestionIndex.value++;
      } else if (currentCategoryIndex.value < categories.length - 1) {
        currentCategoryIndex.value++;
        currentQuestionIndex.value = 0;
      }
    } else {
      // Find current question in filtered view
      final currentQ = currentQuestion;
      int filteredCatIdx = -1;
      int filteredQIdx = -1;

      for (int ci = 0; ci < filtered.length; ci++) {
        final qi = filtered[ci].questions.indexWhere((q) => q.number == currentQ.number);
        if (qi != -1) {
          filteredCatIdx = ci;
          filteredQIdx = qi;
          break;
        }
      }

      if (filteredCatIdx == -1) {
        // Current question not in filtered view — jump to first filtered question
        _jumpToQuestion(filtered.first.questions.first.number);
      } else {
        if (filteredQIdx < filtered[filteredCatIdx].questions.length - 1) {
          // Next question in same filtered category
          _jumpToQuestion(filtered[filteredCatIdx].questions[filteredQIdx + 1].number);
        } else if (filteredCatIdx < filtered.length - 1) {
          // First question of next filtered category (same subject)
          _jumpToQuestion(filtered[filteredCatIdx + 1].questions.first.number);
        } else {
          // Last question of current subject — switch to next subject
          final currentSubject = selectedSubjectFilter.value;
          final currentSubjectIdx = availableSubjects.indexWhere((s) => s.name == currentSubject);
          if (currentSubjectIdx != -1 && currentSubjectIdx < availableSubjects.length - 1) {
            final nextSubject = availableSubjects[currentSubjectIdx + 1];
            setSubjectFilter(nextSubject.name);
          }
          // else: last subject, last question — do nothing
        }
      }
    }

    _startQuestionTimer();
    _syncNumericalField();
    _syncSubjectFilter();
    updateView();
  }

  /// Resolves a question by its number and sets the raw category + question indices.
  void _jumpToQuestion(int questionNumber) {
    for (int ci = 0; ci < categories.length; ci++) {
      final qi = categories[ci].questions.indexWhere((q) => q.number == questionNumber);
      if (qi != -1) {
        currentCategoryIndex.value = ci;
        currentQuestionIndex.value = qi;
        return;
      }
    }
  }

  void _syncNumericalField() {
    final question = currentQuestion;
    if (question.type == QuestionType.numerical ||
        question.type == QuestionType.integer) {
      final n = question.numericalAnswer;
      if (n == null) {
        numericalController.text = '';
      } else if (question.type == QuestionType.integer ||
          n.truncateToDouble() == n) {
        numericalController.text = n.toInt().toString();
      } else {
        numericalController.text = n.toString();
      }
    } else if (question.type == QuestionType.textType ||
               question.type == QuestionType.subjective) {
      numericalController.text = question.textAnswer ?? '';
    } else {
      numericalController.clear();
    }
  }

  void _syncSubjectFilter() {
    final newSubject = currentQuestion.subject?.name;
    if (newSubject != null &&
        selectedSubjectFilter.value != 'All' &&
        selectedSubjectFilter.value != newSubject) {
      selectedSubjectFilter.value = newSubject;
    }
  }

  Map<QuestionStatus, int> getCategoryStats(int categoryIndex) {
    final category = categories[categoryIndex];
    final stats = <QuestionStatus, int>{};
    for (var status in QuestionStatus.values) {
      stats[status] = category.questions
          .where((q) => q.status == status)
          .length;
    }
    return stats;
  }

  bool isLatex(String text) {
    final latexPatterns = [
      r'\$.*?\$', // $...$
      r'\\\(', // \(
      r'\\\)', // \)
      r'\\frac', // \frac
      r'\\sqrt', // \sqrt
      r'\\alpha|\\beta|\\gamma|\\delta|\\Delta',
      r'\^', // superscript
      r'_', // subscript
      r'\\begin\{.*?\}', // environments
      r'\\end\{.*?\}',
    ];

    return latexPatterns.any((pattern) => RegExp(pattern).hasMatch(text));
  }

  //Timers
  int totalDurationSeconds = 30 * 60;
  static const int warningThresholdSeconds = 5 * 60;
  static const int blinkThresholdSeconds = 60;

  final enableBlinkingTimer = true;
  final blinkOn = true.obs;
  Timer? _blinkTimer;

  final remainingSeconds = (30 * 60).obs;
  final showFiveMinWarning = false.obs;

  Timer? _timer;

  @override
  void onClose() {
    // Do NOT unlock here — under MDM kiosk, calling stopLockTask() during
    // route disposal races with Get.offAllNamed and crashes the activity.
    // The new route (e.g. ExamAnalysisController) unlocks once it's mounted.
    _timer?.cancel();
    _stopBlinking();
    _lockChannel.setMethodCallHandler(null);
    super.onClose();
  }

  // ================= TIMER LOGIC =================
  void _startTimer() {
    lockScreen();          // ← ADD
    _startQuestionTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value <= 0) {
        timer.cancel();
        _onTimeUp();
        _stopBlinking();
        return;
      }

      remainingSeconds.value--;

      // 🔔 Show 5-minute warning once
      if (remainingSeconds.value == warningThresholdSeconds) {
        showFiveMinWarning.value = true;
        _showFiveMinuteWarning();
      }

      if (enableBlinkingTimer &&
          remainingSeconds.value == blinkThresholdSeconds) {
        _startBlinking();
      }
    });
  }

  void _startBlinking() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      blinkOn.toggle();
    });
  }

  void _stopBlinking() {
    _blinkTimer?.cancel();
    blinkOn.value = true;
  }

  void _onTimeUp() {
    _recordTimeForCurrentQuestion();
    _questionStartTime = null;
    Get.snackbar(
      'Time Up',
      'Your test time has ended',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );

    // TODO: auto submit test
    // submitTest();
  }

  void submitTest() {
    unlockScreen();
    _timer?.cancel();
    Get.snackbar(
      "Success",
      "Your has been submitted successfully",
      backgroundColor: Colors.green,
    );
    // API submit call here
  }

  // ================= UI HELPERS =================
  String get formattedTime {
    final minutes = (remainingSeconds.value) ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ================= UI HELPERS =================
  String get takenTime {
    final minutes = (totalDurationSeconds - remainingSeconds.value) ~/ 60;
    final seconds = (totalDurationSeconds - remainingSeconds.value) % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isLastFiveMinutes =>
      remainingSeconds.value <= warningThresholdSeconds;

  bool get isLastOneMinute => remainingSeconds.value <= 60;

  bool get isTimerCompleted => remainingSeconds.value <= 0;

  void _showFiveMinuteWarning() {
    Get.snackbar(
      'Hurry Up ⏰',
      'You have only 5 minutes left to complete the test',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFF97316),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
    );
  }

  // ============================================================
  // ADD THESE METHODS TO YOUR TestPlayerController CLASS
  // ============================================================

  // Add these variables at the top with your other state variables:
  final reviewIndex = 0.obs;
  final isTestCompleted = false.obs;
  Map<String, dynamic> correctAnswersMap = {};

  // ============================================================
  // RESULT & REVIEW METHODS
  // ============================================================

  /// Get all questions across all categories
  List<Question> getAllQuestions() {
    return categories.expand((cat) => cat.questions).toList();
  }

  List<Question> getFilteredQuestions() {
    return filteredCategories.expand((cat) => cat.questions).toList();
  }

  /// Get current question in review mode
  Question get currentReviewQuestion {
    final allQuestions = getAllQuestions();
    if (allQuestions.isEmpty || reviewIndex.value >= allQuestions.length) {
      return Question(
        questionId: '',
        number: 0,
        text: 'No question',
        type: QuestionType.mcqSingle,
      );
    }
    return allQuestions[reviewIndex.value];
  }

  /// Navigate to specific question in review mode
  void goToReviewQuestion(int index) {
    reviewIndex.value = index;
    updateView();
  }

  /// Get total number of questions
  int get totalQuestions => getAllQuestions().length;

  /// Check if a question was skipped (not attempted)
  bool isQuestionSkipped(Question question) {
    return question.selectedAnswer == null &&
        (question.selectedAnswers?.isEmpty ?? true) &&
        (question.matchAnswers?.isEmpty ?? true) &&
        question.numericalAnswer == null &&
        (question.textAnswer?.isEmpty ?? true);
  }

  /// Check if a question is correct
  bool isQuestionCorrect(Question question) {
    // Get correct answer from storage
    final correctAnswer = correctAnswersMap['question_${question.number}'];
    if (correctAnswer == null) return false;

    switch (question.type) {
      case QuestionType.mcqSingle:
      case QuestionType.trueFalse:
      case QuestionType.singleDropdown:
        // For MCQ single, compare the selected answer's key (A, B, C, D)
        return question.selectedAnswer == correctAnswer;

      case QuestionType.mcqMultiple:
      case QuestionType.multiDropdown:
        // For multiple choice, split correct answers by semicolon
        final correctAnswers = correctAnswer.split(';').toSet();
        final userAnswers = question.selectedAnswers?.toSet() ?? {};
        return correctAnswers.toString() == userAnswers.toString();

      case QuestionType.integer:
      case QuestionType.numerical:
        // For numerical, parse and compare
        if (correctAnswer is bool) {
          final correctNum = double.tryParse('0');
          return question.numericalAnswer == correctNum;
        } else {
          final correctNum = double.tryParse(correctAnswer);
          return question.numericalAnswer == correctNum;
        }

      case QuestionType.textType:
      case QuestionType.subjective:
        // For text, do case-insensitive comparison
        return question.textAnswer?.toLowerCase().trim() ==
            correctAnswer.toLowerCase().trim();

      case QuestionType.matchTheFollowing:
        // For matching, compare all pairs (format: A:PS;B:QR)
        if (question.matchAnswers == null) return false;
        final expectedPairs = correctAnswer.split(';');
        for (var pair in expectedPairs) {
          final parts = pair.split(':');
          if (parts.length != 2) continue;
          final left = parts[0].trim();
          final expectedRight = parts[1].trim().split('')..sort();
          final userRight = question.matchAnswers![left] ?? [];
          final userSorted = List<String>.from(userRight)..sort();
          if (expectedRight.join() != userSorted.join()) return false;
        }
        return true;

      default:
        return false;
    }
  }

  /// Check if specific option is the correct answer
  bool isOptionCorrect(Question question, String option) {
    final correctAnswer = correctAnswersMap['question_${question.number}'];
    if (correctAnswer == null) return false;

    if (question.type == QuestionType.mcqMultiple) {
      final correctAnswers = correctAnswer.split(';');
      return correctAnswers.contains(option);
    }

    return option == correctAnswer;
  }

  /// Check if user selected this option
  bool isUserAnswer(Question question, String option) {
    if (question.type == QuestionType.mcqMultiple) {
      return question.selectedAnswers?.contains(option) ?? false;
    }
    return question.selectedAnswer == option;
  }

  /// Get correct answer text for display
  String getCorrectAnswer(Question question) {
    return correctAnswersMap['question_${question.number}'] is bool
        ? "0"
        : correctAnswersMap['question_${question.number}'] ?? 'N/A';
  }

  /// Get user's answer formatted for display
  String getUserAnswerDisplay(Question question) {
    switch (question.type) {
      case QuestionType.mcqSingle:
      case QuestionType.trueFalse:
      case QuestionType.singleDropdown:
        return question.selectedAnswer ?? 'Not Answered';

      case QuestionType.mcqMultiple:
      case QuestionType.multiDropdown:
        if (question.selectedAnswers == null ||
            question.selectedAnswers!.isEmpty) {
          return 'Not Answered';
        }
        return question.selectedAnswers!.join(', ');

      case QuestionType.integer:
      case QuestionType.numerical:
        return question.numericalAnswer?.toString() ?? 'Not Answered';

      case QuestionType.textType:
      case QuestionType.subjective:
        return question.textAnswer?.isNotEmpty == true
            ? question.textAnswer!
            : 'Not Answered';

      case QuestionType.matchTheFollowing:
        if (question.matchAnswers == null || question.matchAnswers!.isEmpty) {
          return 'Not Answered';
        }
        return question.matchAnswers!.entries
            .map((e) => '${e.key} → ${e.value.join('')}')
            .join(', ');
    }
  }

  /// Get correct answer formatted for display
  String getCorrectAnswerDisplay(Question question) {
    final answer = correctAnswersMap['question_${question.number}'];
    if (answer == null) return 'N/A';

    switch (question.type) {
      case QuestionType.mcqMultiple:
        return answer.split(';').join(', ');

      case QuestionType.matchTheFollowing:
        return answer
            .split(';')
            .map((pair) {
              final parts = pair.split(':');
              return '${parts[0]} → ${parts[1]}';
            })
            .join(', ');

      default:
        return answer;
    }
  }

  /// Get comprehensive test statistics
  Map<String, dynamic> getTestStatistics() {
    final allQuestions = getAllQuestions();
    if (allQuestions.isEmpty) {
      return {
        'total': 0,
        'correct': 0,
        'wrong': 0,
        'skipped': 0,
        'percentage': 0.0,
        'timeSpent': takenTime,
      };
    }

    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (var question in allQuestions) {
      if (isQuestionSkipped(question)) {
        skipped++;
      } else if (isQuestionCorrect(question)) {
        correct++;
      } else {
        wrong++;
      }
    }
    String timeSpend = takenTime;
    if (Session.instance.storedData != null && !Session.instance.isRetest) {
      final minutes =
          Session
              .instance
              .storedData!['storedData']['result']['timeSpentSeconds'] ~/
          60;
      final seconds =
          Session
              .instance
              .storedData!['storedData']['result']['timeSpentSeconds'] %
          60;
      timeSpend =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    final percentage = (correct / allQuestions.length) * 100;

    return {
      'total': allQuestions.length,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'percentage': percentage,
      'timeSpent': timeSpend,
    };
  }

  /// Alias for compatibility with result view
  bool isCorrect(Question question) {
    return isQuestionCorrect(question);
  }

  /// Text shown on the blocking overlay while [isSubmitting] is true.
  final submitStatus = 'Submitting your exam…'.obs;

  /// Shows "No internet" and returns false if the API host can't be reached.
  /// The probe can take a few seconds, so the overlay is shown meanwhile.
  Future<bool> _ensureOnlineForSubmit() async {
    final wasSubmitting = isSubmitting.value;
    submitStatus.value = 'Checking connection…';
    isSubmitting.value = true;
    final online = await NetworkService.canReachServer();
    submitStatus.value = 'Submitting your exam…';
    isSubmitting.value = wasSubmitting;
    if (!online) {
      Get.snackbar(
        'No Internet Connection',
        'Connect to Wi-Fi or mobile data, then submit again. '
        'Your answers are safe — the exam is still running.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
    return online;
  }

  void completeTest() async {
    if (isSubmitting.value) return;
    if (isExamMode && !await _ensureOnlineForSubmit()) return;
    if (Get.isDialogOpen ?? false) return;

    final TextEditingController confirmController = TextEditingController();
    final RxBool isValid = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type SUBMIT below to confirm test submission.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              onChanged: (value) {
                isValid.value = value.trim().toUpperCase() == "SUBMIT";
              },
              decoration: InputDecoration(
                hintText: 'Type SUBMIT',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(
            () => ElevatedButton(
              onPressed: isValid.value
                  ? () {
                      Get.back();
                      finalCompleteTest();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
              ),
              child: const Text('Submit Test'),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> clearData() async {
    _timer?.cancel();
    _stopBlinking();
    isTestCompleted.value = true;
    reviewIndex.value = 0;
    // NOTE: do NOT call unlockScreen() here. Under MDM kiosk, calling
    // stopLockTask() before the route transition completes can race with
    // Get.offAllNamed and force-close the activity. The controller's
    // onClose() (fired when the route disposes) handles the unlock once.
  }

  /// True while [finalCompleteTest] is awaiting the submit API. Bind to it
  /// from the view to show an inline overlay instead of using Get.dialog,
  /// which can crash the app under MDM kiosk lock-task mode.
  final isSubmitting = false.obs;

  /// Complete test and show results
  void finalCompleteTest() async {
    if (isExamMode) {
      await _submitExam();
      return;
    }

    await clearData();

    // Assignment flow (existing)
    final Map<String, dynamic> results = _prepareResultsForSubmission();
    storage.save(Session.instance.currentTestId, {
      "testJson": selectedQuestions,
      "result": results,
      "completed": true,
      "numberOfReattempts" : totalReAttempts,
      "timestamp": DateTime.now().toIso8601String(),
    });
    Get.snackbar(
      'Success',
      'Your exam has been submitted successfully, Your result will be published soon...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    Get.offAllNamed(AppRoutes.discussion);
  }

  /// Exam submission. The connection is verified first; the timer keeps
  /// running and the student stays on the exam screen unless the server
  /// confirms the submission, so a dropped connection never strands them on
  /// the list screen with an unsubmitted paper.
  Future<void> _submitExam() async {
    if (isSubmitting.value) return;
    // Re-check: the connection may have dropped while typing SUBMIT.
    if (!await _ensureOnlineForSubmit()) return;

    isSubmitting.value = true;
    _recordTimeForCurrentQuestion();
    final examPayload = _prepareExamSubmission();

    // Persist the payload FIRST, flagged pendingSync, so that if the app is
    // killed mid-request the next launch can retry it.
    storage.save(Session.instance.currentTestId, {
      "testJson": selectedQuestions,
      "examPayload": examPayload,
      "completed": true,
      "pendingSync": true,
      "timestamp": DateTime.now().toIso8601String(),
    });

    try {
      final response = await _apiService.submitExamResult(examPayload);
      final ok = response is! Exception && response['status'] == true;
      if (!ok) {
        final msg = response is Exception
            ? response.toString()
            : (response['message'] ?? 'Submission failed').toString();
        _submitFailed(msg);
        return;
      }

      // Confirmed by the server.
      await clearData();
      storage.save(Session.instance.currentTestId, {
        "testJson": selectedQuestions,
        "completed": true,
        "pendingSync": false,
        "timestamp": DateTime.now().toIso8601String(),
      });
      storage.removeByKey('active_exam_id');
      isSubmitting.value = false;

      final analysisArgs = <String, dynamic>{
        'examId': Session.instance.currentTestId.replaceAll('exam_', ''),
        'examCode': examCode,
        'examName': (selectedQuestions['examName'] ?? '').toString(),
      };
      // Yield a frame so the submitting overlay disappears before the route
      // is torn down (overlay/route teardown race under MDM).
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Not awaited: Get.offAllNamed's future completes only when the NEW
      // route is popped, which would delay everything below indefinitely.
      Get.offAllNamed(AppRoutes.examAnalysis, arguments: analysisArgs);
      _unlockAfterNavigation();
      Get.snackbar(
        'Success',
        'Your exam has been submitted successfully, Your result will be published soon...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _submitFailed("We couldn't reach the server. Please check your "
          'connection and tap Submit Test again.');
    }
  }

  /// Submission didn't reach / wasn't accepted by the server: drop the
  /// overlay and keep the student in the exam so they can retry. The
  /// pendingSync payload stays in storage as a safety net for app restarts.
  void _submitFailed(String message) {
    isSubmitting.value = false;
    Get.snackbar(
      'Submission Failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  /// Submit test results to server
  Future<void> submitTestResults() async {
    unlockScreen();
    _timer?.cancel();
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );
    try {
      final results = _prepareServerSubmission();
      final connectivityResult = await NetworkService.hasInternet();
      if (!connectivityResult) {
        Get.snackbar(
          'Error',
          'Check your internet connection',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
        return;
      }

      final response = await _apiService.submitResult(results);
      if(response is Exception) {
        Get.snackbar(
          'Error',
          response.toString(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        if (response['status']) {
          Get.snackbar(
            'Success',
            'Test results submitted successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          await Future.delayed(Duration(milliseconds: 500));
          Get.until((route) => route.settings.name == AppRoutes.home);
          storage.removeByKey(Session.instance.currentTestId);
        } else {
          Get.snackbar(
            'Error',
            response['message'],
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        Get.back();
      }


      // Navigate back or to results page
      // Get.back();
    } catch (e,s) {
      Get.snackbar(
        'Error',
        'Failed to submit results. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Get.back();
    }
  }

  /// Prepare exam results for /exam/result/submit
  Map<String, dynamic> _prepareExamSubmission() {
    final allQuestions = getAllQuestions();
    final userData = Session.instance.currentUser?['data'] ?? {};

    // Build answers with sectionId and timeTaken
    final answers = allQuestions.map((q) {
      return {
        'questionId': q.questionId,
        'sectionId': q.subject?.id ?? '',
        'answerRaw': _getUserAnswerForSubmission(q),
        'isSkipped': isQuestionSkipped(q),
        'timeTaken': (questionTimeSpent[q.number] ?? 0) * 1000, // seconds → ms
      };
    }).toList();

    // Build sectionTimings from questionTimeSpent
    final Map<String, int> sectionTimings = {};
    for (var q in allQuestions) {
      if (q.sectionId != null) {
        final timeMs = (questionTimeSpent[q.number] ?? 0) * 1000; // seconds → ms
        sectionTimings[q.sectionId!] =
            (sectionTimings[q.sectionId!] ?? 0) + timeMs;
      }
    }

    return {
      'entiId': userData['tenantId'] ?? '',
      'examId': Session.instance.currentTestId.replaceAll('exam_', ''),
      'admissionNo': userData['admissionNo'] ?? '',
      'studentId': userData['studentId'] ?? '',
      'batchId': userData['batchCode'] ?? '',
      'centerId': userData['centerId'] ?? '',
      'classNo': userData['classNo'] ?? 0,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'sectionTimings': sectionTimings,
      'answers': answers,
    };
  }

  /// Prepare results data for API submission
  Map<String, dynamic> _prepareServerSubmission() {
    final stats = getTestStatistics();
    final allQuestions = getAllQuestions();

    final answers = allQuestions.map((q) {
      return {
        'questionId': q.questionId,
        'answerRaw': _getUserAnswerForSubmission(q),
      };
    }).toList();

    DateTime parsed = DateTime.now();
    int milliseconds = parsed.millisecondsSinceEpoch;
    return {
      'testId': Session.instance.currentTestId.replaceAll("test_", ''),
      'subjectId': Session.instance.selectedSubject?.id,
      'classNo': Session.instance.currentUser!['data']['classNo'],
      'admissionNo': Session.instance.currentUser!['data']['admissionNo'],
      'entiId': Session.instance.currentUser!['data']['tenantId'],
      'batchId': Session.instance.currentUser!['data']['batchId'],
      "startedAt": startedAt.millisecondsSinceEpoch,
      "numberOfReattempts": totalReAttempts,
      'answers': answers,
      'completedAt': milliseconds,
    };
  }


  /// Prepare results data for API submission
  Map<String, dynamic> _prepareResultsForSubmission() {
    final stats = getTestStatistics();
    final allQuestions = getAllQuestions();

    final answers = allQuestions.map((q) {
      return {
        'questionNumber': q.number,
        'questionId': 'question_${q.number}',
        'serverQuestionId': q.questionId,
        'questionType': q.type.toString(),
        'userAnswer': _getUserAnswerForSubmission(q),
        'correctAnswer': correctAnswersMap['question_${q.number}'],
        'isCorrect': isQuestionCorrect(q),
        'isSkipped': isQuestionSkipped(q),
      };
    }).toList();
    DateTime parsed = DateTime.now();
    int milliseconds = parsed.millisecondsSinceEpoch;

    return {
      'testId': Session.instance.currentTestId, // Get from your test data
      'userId': 'USER_ID', // Get from auth
      'studentId': 'STUDENT_ID', // Get from auth
      'score': stats['correct'],
      'totalQuestions': stats['total'],
      'percentage': stats['percentage'],
      'correctAnswers': stats['correct'],
      'wrongAnswers': stats['wrong'],
      'skippedQuestions': stats['skipped'],
      'timeSpent': stats['timeSpent'],
      'subjectId': Session.instance.selectedSubject?.id,
      'subject' : Session.instance.selectedSubject?.name,
      'subTopic' : Session.instance.selectedSub,
      'topicName' : Session.instance.selectedTopic?.name,
      'subtopic' : Session.instance.selectedSubtopic?.name,
      'category' : Session.instance.selectedCategory,
      'testNo' : selectedQuestions['data']?['testNo'],
      "numberOfReattempts": totalReAttempts,
      'timeSpentSeconds': totalDurationSeconds - remainingSeconds.value,
      'answers': answers,
      "startedAt": startedAt.millisecondsSinceEpoch,
      'completedAt': milliseconds,
    };
  }

  /// Get user answer in format suitable for API submission
  String _getUserAnswerForSubmission(Question question) {
    switch (question.type) {
      case QuestionType.trueFalse:
        return (question.selectedAnswer ?? '').toLowerCase();
      case QuestionType.mcqSingle:
      case QuestionType.singleDropdown:
        return question.selectedAnswer ?? '';

      case QuestionType.mcqMultiple:
      case QuestionType.multiDropdown:
        return question.selectedAnswers?.join(';') ?? '';

      case QuestionType.integer:
        final n = question.numericalAnswer;
        if (n == null) return '';
        return n.truncateToDouble() == n
            ? n.toInt().toString()
            : n.toString();
      case QuestionType.numerical:
        return question.numericalAnswer?.toString() ?? '';

      case QuestionType.textType:
      case QuestionType.subjective:
        return question.textAnswer ?? '';

      case QuestionType.matchTheFollowing:
        return question.matchAnswers?.entries
                .map((e) => '${e.key}:${e.value.join(',')}')
                .join(';') ??
            '';
    }
  }

  Map<String, dynamic> getPerformanceReport() {
    final allQuestions = getAllQuestions();

    // Subject-wise breakdown
    final Map<String, Map<String, dynamic>> subjectMap = {};

    for (var question in allQuestions) {
      final subjectName = question.subject?.name ?? 'General';

      subjectMap.putIfAbsent(subjectName, () => {
        'subjectName': subjectName,
        'correct': 0,
        'wrong': 0,
        'skipped': 0,
        'totalMarks': 0.0,
        'positiveMarks': 0.0,
        'negativeMarks': 0.0,
        'totalScore': 0.0,
      });

      final entry = subjectMap[subjectName]!;
      entry['totalMarks'] = (entry['totalMarks'] as double) + question.positiveMarks;

      if (isQuestionSkipped(question)) {
        entry['skipped'] = (entry['skipped'] as int) + 1;
      } else if (isQuestionCorrect(question)) {
        entry['correct'] = (entry['correct'] as int) + 1;
        entry['positiveMarks'] = (entry['positiveMarks'] as double) + question.positiveMarks;
      } else {
        entry['wrong'] = (entry['wrong'] as int) + 1;
        entry['negativeMarks'] = (entry['negativeMarks'] as double) + question.negativeMarks;
      }

      entry['totalScore'] = (entry['positiveMarks'] as double) - (entry['negativeMarks'] as double);
    }

    // Compute totals
    double totalMarks = 0, positiveMarks = 0, negativeMarks = 0;
    int correct = 0, wrong = 0, skipped = 0;

    for (var entry in subjectMap.values) {
      totalMarks    += entry['totalMarks']    as double;
      positiveMarks += entry['positiveMarks'] as double;
      negativeMarks += entry['negativeMarks'] as double;
      correct       += entry['correct']       as int;
      wrong         += entry['wrong']         as int;
      skipped       += entry['skipped']       as int;
    }

    return {
      // Subject-wise list
      'subjects': subjectMap.values.toList(),

      // Grand totals (kept for backward compat)
      'totalQuestions': allQuestions.length,
      'totalMarks': totalMarks,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'positiveMarks': positiveMarks,
      'negativeMarks': negativeMarks,
      'totalScore': positiveMarks - negativeMarks,
    };
  }

  bool isBookmarked(String questionNumber) {
    return bookmarkedQuestions.contains(questionNumber);
  }

  void initBookmarks(List<dynamic> apiData) {
    loadLocalBookmarks();
    loadApiBookmarks(apiData);
  }

  void loadApiBookmarks(List<dynamic> apiData) {
    final apiBookmarks = apiData
        .map((e) => e['questionId']?.toString())
        .whereType<String>()
        .toList();


    // Merge without duplicates
    final combined = {
      ...bookmarkedQuestions,
      ...apiBookmarks,
    }.toList();

    bookmarkedQuestions.assignAll(combined);

    // Save merged to storage
    storage.save('bookmarks_$currentTestId', combined);
  }

  void loadLocalBookmarks() {
    final stored = storage.read('bookmarks_$currentTestId');

    if (stored != null && stored is List) {
      bookmarkedQuestions.assignAll(
        stored.map((e) => e.toString()).toList(),
      );
    }
  }

  void _loadBookmarks() async {
    final response = await _apiService.loadBookmarks();
    final List<dynamic> data = response['data'];

    final List<Bookmark> bookmark =
    data.map((e) => Bookmark.fromJson(e)).toList();
    bookmarks.value = bookmark;
    initBookmarks(response['data']);
  }

  void toggleBookmark(String questionNumber) async {
    if (bookmarkedQuestions.contains(questionNumber)) {
      bookmarkedQuestions.add(questionNumber);
    final bookmark = bookmarks.firstWhereOrNull(
          (b) => b.questionId == questionNumber,
    );
    final response = await _apiService.removeBookmark({
      "entiId": Session.instance.currentUser!['data']['tenantId'],
      "bookmarkId": bookmark?.bookmarkId ?? '',
    });
    if(response is Exception) {
      Get.snackbar(
        'Error',
        response.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Success',
        response['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
    bookmarkedQuestions.remove(questionNumber);
    } else {

    //  'testId': Session.instance.currentTestId.replaceAll("test_", ''),
    // 'subjectId': Session.instance.selectedSubject?.id,
    // 'classNo': Session.instance.currentUser!['data']['classNo'],
    // 'admissionNo': Session.instance.currentUser!['data']['admissionNo'],
    // 'entiId': Session.instance.currentUser!['data']['tenantId'],
    // 'batchId': Session.instance.currentUser!['data']['batchId'],
      bookmarkedQuestions.add(questionNumber);
      final response = await _apiService.bookMarkQuestion({
        "entiId": Session.instance.currentUser!['data']['tenantId'],
        "studentId": Session.instance.currentUser!['data']['studentId'],
        "questionId": questionNumber,
        "assignmentId":Session.instance.currentTestId.replaceAll("test_", ''),//testId
        "subjectId": Session.instance.selectedSubject?.id,
        "note": "Tricky concept, revise before finals"
      });
      if(response is Exception) {
        Get.snackbar(
          'Error',
          response.toString(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Success',
           response['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }
    storage.save('bookmarks_$currentTestId', bookmarkedQuestions.toList());
    updateNewView();
  }

  void  reportQuestion({required String questionId,required String issueType,required String comment,}) async {
    final response = await _apiService.reportQuestion({
      "entiId": Session.instance.currentUser!['data']['tenantId'],
      "studentId": Session.instance.currentUser!['data']['studentId'],
      "studentName": Session.instance.currentUser!['data']['name'],
      "questionId": questionId,
      "assignmentId":Session.instance.currentTestId.replaceAll("test_", ''),//testId
      "issueType": 'WRONG_ANSWER',
      "description": comment
    });
    if(response is Exception) {
      Get.snackbar(
        'Error',
        response.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Success',
        response['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _extractSubjects() {
    final seen = <String>{};
    availableSubjects = [];
    // Lowest section sortOrder seen for each subject; subjects without one
    // (older cached exams, assignments) keep their order of appearance.
    final sortKey = <String, int>{};
    var appearance = 0;
    for (var cat in categories) {
      for (var q in cat.questions) {
        final subject = q.subject;
        if (subject == null) continue;
        if (seen.add(subject.name)) {
          availableSubjects.add(subject);
          sortKey[subject.name] = q.sectionSortOrder ?? (1 << 20) + appearance++;
        } else if (q.sectionSortOrder != null) {
          sortKey[subject.name] =
              math.min(sortKey[subject.name]!, q.sectionSortOrder!);
        }
      }
    }
    availableSubjects.sort(
        (a, b) => sortKey[a.name]!.compareTo(sortKey[b.name]!));
    if (availableSubjects.isNotEmpty) {
      setSubjectFilter(availableSubjects.first.name);
    }
  }


  List<QuestionCategory> get filteredCategories {
    if (selectedSubjectFilter.value == 'All') return categories;

    return categories.map((cat) {

      final filtered = cat.questions
          .where((q) => q.subject?.name == selectedSubjectFilter.value)
          .toList();
      return QuestionCategory(
        id: cat.id,
        name: cat.name,
        subject: cat.subject,
        questionCount: filtered.length,
        questions: filtered,
      );
    }).where((cat) => cat.questions.isNotEmpty).toList();
  }

  // void setSubjectFilter(String subjectName) {
  //   selectedSubjectFilter.value = subjectName;
  //   currentCategoryIndex.value = 0;
  //   currentQuestionIndex.value = 0;
  //   updateView();
  // }
  void setSubjectFilter(String subjectName) {
    selectedSubjectFilter.value = subjectName;

    final firstFilteredCategory = filteredCategories.firstOrNull;

    if (firstFilteredCategory != null) {
      // Resolve raw category index
      final rawCategoryIndex = categories
          .indexWhere((c) => c.id == firstFilteredCategory.id);

      currentCategoryIndex.value = rawCategoryIndex != -1 ? rawCategoryIndex : 0;

      // ← Resolve raw question index of the FIRST question in the filtered category
      final firstFilteredQuestion = firstFilteredCategory.questions.firstOrNull;
      if (firstFilteredQuestion != null && rawCategoryIndex != -1) {
        final rawQuestionIndex = categories[rawCategoryIndex]
            .questions
            .indexWhere((q) => q.number == firstFilteredQuestion.number);
        currentQuestionIndex.value = rawQuestionIndex != -1 ? rawQuestionIndex : 0;
      } else {
        currentQuestionIndex.value = 0;
      }
    } else {
      currentCategoryIndex.value = 0;
      currentQuestionIndex.value = 0;
    }

    _syncNumericalField();
    updateView();
  }

  void _recordTimeForCurrentQuestion() {
    if (_questionStartTime == null) return;
    if (categories.isEmpty) return;
    final spent = DateTime.now().difference(_questionStartTime!).inSeconds;
    if (spent <= 0) {
      _questionStartTime = DateTime.now();
      return;
    }
    final number = currentQuestion.number;
    questionTimeSpent[number] = (questionTimeSpent[number] ?? 0) + spent;
    _questionStartTime = DateTime.now();
  }

  void _startQuestionTimer() {
    _questionStartTime = DateTime.now();
  }

  Map<String, dynamic> getPerformanceReport2() {
    final allQuestions = getAllQuestions();

    // Record time for current question before computing
    _recordTimeForCurrentQuestion();

    final Map<String, Map<String, dynamic>> subjectMap = {};

    for (var question in allQuestions) {
      final subjectName = question.subject?.name ?? 'General';

      subjectMap.putIfAbsent(subjectName, () => {
        'subjectName': subjectName,
        'total': 0,
        'correct': 0,
        'wrong': 0,
        'skipped': 0,
        'timeSeconds': 0,
      });

      final entry = subjectMap[subjectName]!;
      entry['total'] = (entry['total'] as int) + 1;
      entry['timeSeconds'] = (entry['timeSeconds'] as int)
          + (questionTimeSpent[question.number] ?? 0);

      if (isQuestionSkipped(question)) {
        entry['skipped'] = (entry['skipped'] as int) + 1;
      } else if (isQuestionCorrect(question)) {
        entry['correct'] = (entry['correct'] as int) + 1;
      } else {
        entry['wrong'] = (entry['wrong'] as int) + 1;
      }
    }

    // Compute derived metrics per subject
    final subjectList = subjectMap.values.map((entry) {
      final total   = entry['total']   as int;
      final correct = entry['correct'] as int;
      final wrong   = entry['wrong']   as int;
      final timeSec = entry['timeSeconds'] as int;

      final attempted   = correct + wrong;
      final percentage  = total > 0 ? (correct / total) * 100 : 0.0;
      final accuracy    = attempted > 0 ? (correct / attempted) * 100 : 0.0;
      final avgTimeSec  = total > 0 ? timeSec / total : 0.0;

      return {
        ...entry,
        'percentage': percentage,
        'accuracy': accuracy,
        'avgTimeSeconds': avgTimeSec,
      };
    }).toList();

    // Grand totals
    int totalQs = 0, totalCorrect = 0, totalWrong = 0, totalTime = 0;
    for (var s in subjectList) {
      totalQs      += s['total']       as int;
      totalCorrect += s['correct']     as int;
      totalWrong   += s['wrong']       as int;
      totalTime    += s['timeSeconds'] as int;
    }

    final totalAttempted  = totalCorrect + totalWrong;
    final totalPercentage = totalQs > 0 ? (totalCorrect / totalQs) * 100 : 0.0;
    final totalAccuracy   = totalAttempted > 0 ? (totalCorrect / totalAttempted) * 100 : 0.0;
    final totalAvgTime    = totalQs > 0 ? totalTime / totalQs : 0.0;

    return {
      'subjects': subjectList,
      'total': {
        'total': totalQs,
        'correct': totalCorrect,
        'wrong': totalWrong,
        'timeSeconds': totalTime,
        'percentage': totalPercentage,
        'accuracy': totalAccuracy,
        'avgTimeSeconds': totalAvgTime,
      },
    };
  }

// Helper to format seconds → "2m 30s"
  String formatSeconds(num seconds) {
    final s = seconds.toInt();
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final rem = s % 60;
    return rem > 0 ? '${m}m ${rem}s' : '${m}m';
  }

  // ============================================================
  // UPDATE YOUR submitTest() METHOD
  // ============================================================

  // Replace your existing submitTest() with:
  //   void submitTest() {
  //     _timer?.cancel();
  //     _stopBlinking();
  //
  //     // Show confirmation dialog
  //     Get.dialog(
  //       AlertDialog(
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //         title: const Text('Submit Test?'),
  //         content: const Text(
  //           'Are you sure you want to submit the test? You cannot change your answers after submission.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Get.back(),
  //             child: const Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Get.back();
  //               completeTest();
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color(0xFF4F46E5),
  //             ),
  //             child: const Text('Submit'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }


}
