import 'package:get/get.dart';
import '../controllers/absent_exam_questions_controller.dart';

class AbsentExamQuestionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AbsentExamQuestionsController>(
      () => AbsentExamQuestionsController(),
      fenix: true,
    );
  }
}
