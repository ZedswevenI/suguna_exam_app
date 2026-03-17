import 'package:get/get.dart';
import 'package:suguna_exam_app/data/models/question_model.dart';
import 'package:suguna_exam_app/data/services/mock_data_service.dart';

class QuestionReviewController extends GetxController {
  final questions = <QuestionModel>[].obs;
  final currentQuestionIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final questionNumber = Get.arguments as int? ?? 1;
    loadQuestions();
    goToQuestion(questionNumber);
  }

  void loadQuestions() {
    questions.value = MockDataService.getQuestions();
  }

  void goToQuestion(int questionNumber) {
    final index = questionNumber - 1;
    if (index >= 0 && index < questions.length) {
      currentQuestionIndex.value = index;
    }
  }

  QuestionModel? getCurrentQuestion() {
    if (currentQuestionIndex.value >= 0 &&
        currentQuestionIndex.value < questions.length) {
      return questions[currentQuestionIndex.value];
    }
    return null;
  }

  void goBack() {
    Get.back();
  }

  void exit() {
    Get.back();
  }
}
