import 'package:get/get.dart';
import '../controllers/exam_result_controller.dart';

class ExamResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExamResultController>(() => ExamResultController());
  }
}
