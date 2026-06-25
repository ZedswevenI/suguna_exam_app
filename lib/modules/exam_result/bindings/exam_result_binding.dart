import 'package:get/get.dart';
import '../controllers/exam_result_controller.dart';

class ExamResultBinding extends Bindings {
  @override
  void dependencies() {
    // fenix:true → if the controller was disposed after a previous visit, a
    // fresh instance is created on the next Get.find / route entry instead
    // of throwing or reusing a dead one.
    Get.lazyPut<ExamResultController>(
      () => ExamResultController(),
      fenix: true,
    );
  }
}
