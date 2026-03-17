import 'package:get/get.dart';
import 'package:suguna_exam_app/data/models/question_model.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';

class TestAnalysisController extends GetxController {
  final questions = <QuestionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load questions from test player
    final questionsArg = Get.arguments;
    if (questionsArg != null && questionsArg is List) {
      questions.value = questionsArg.cast();
    }
  }

  void viewQuestion(int questionNumber) {
    Get.toNamed(AppRoutes.questionReview, arguments: questionNumber);
  }
}
