

import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/test_player/controllers/test_player_controller.dart';
import 'package:suguna_exam_app/modules/test_player/controllers/test_player_parser.dart';

import '../../../data/services/sessions.dart';
import '../../../data/services/store_service.dart';

class AssignmentQuestionsController extends GetxController {


  final reviewIndex = TestPlayerController.to.reviewIndex.value.obs;
  final isTestCompleted = false.obs;
  Map<String, dynamic> correctAnswersMap = {};
  List<QuestionCategory> categories = [];
  final storage = Get.find<StorageService>();
  Map<String,dynamic>? storedData;

  @override
  void onInit() {
    reviewIndex.value = Get.arguments['index'];
    getQuestions();
    super.onInit();
  }

  List<Question> getAllQuestions() {
    return categories.expand((cat) => cat.questions).toList();
  }


  void goToReviewQuestion(int index) {
    reviewIndex.value = index;
    update();
  }

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

  dynamic _readFromStorage(String key) {
    try {
      final data = storage.read(key);
      return data;
    } catch (e) {
      print('❌ Error reading from storage [$key]: $e');
      return null;
    }
  }

  void getQuestions() async {
    final testDataKey = Session.instance.currentTestId;
    final storedLocal = _readFromStorage(testDataKey);
    final isCompleted =
        storedLocal['completed'] == true ||
            storedLocal['data']?['completed'] == true;
    if (isCompleted) {
      storedData = {
        "testId": testDataKey,
        "storedData": storedLocal,
      };

      final stored = storedData?['storedData'];
      // totalReAttempts = data['storedData']['numberOfReattempts'] ?? 1;
      categories = await TestApiParser.parseFromJsonString(
        stored['testJson'],
      );
      print("Lcoa s ${categories.length}");

      // selectedQuestions = stored['testJson'];
      final List answers = stored['result']['answers'] ?? [];
      for (var item in answers) {
        final questionNumber = item['questionNumber'];
        final correctAnswer = item['correctAnswer'];
        if (questionNumber != null && correctAnswer != null) {
          correctAnswersMap['question_$questionNumber'] = correctAnswer;
        }
      }
      _restoreUserAnswers(stored['result']['answers']);
      update();
    }
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
              map[parts[0]] = parts[1].split('').toList();
            }
          }
          question.matchAnswers = map;
          break;
      }
    }
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
        // 'timeSpent': takenTime,
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
    // String timeSpend = takenTime;
    // if (Session.instance.storedData != null && !Session.instance.isRetest) {
    //   final minutes =
    //       Session
    //           .instance
    //           .storedData!['storedData']['result']['timeSpentSeconds'] ~/
    //           60;
    //   final seconds =
    //       Session
    //           .instance
    //           .storedData!['storedData']['result']['timeSpentSeconds'] %
    //           60;
    //   timeSpend =
    //   '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    // }
    final percentage = (correct / allQuestions.length) * 100;

    return {
      'total': allQuestions.length,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'percentage': percentage,
    };
  }
  Map<String, dynamic> getPerformanceReport() {
    final allQuestions = getAllQuestions();

    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    double totalMarks = 0;
    double positiveMarks = 0;
    double negativeMarks = 0;

    for (var question in allQuestions) {
      totalMarks += question.positiveMarks;
      if (isQuestionSkipped(question)) {
        skipped++;
      } else if (isQuestionCorrect(question)) {
        correct++;
        positiveMarks += question.positiveMarks;
      } else {
        wrong++;
        negativeMarks += question.negativeMarks;
      }
    }

    final double totalScore = positiveMarks - negativeMarks;
    return {
      "totalQuestions": allQuestions.length,
      "correct": correct,
      "wrong": wrong,
      "skipped": skipped,
      "totalMarks" : totalMarks,
      "positiveMarks": positiveMarks,
      "negativeMarks": negativeMarks,
      "totalScore": totalScore,
    };
  }
}