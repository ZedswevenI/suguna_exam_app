import 'package:get/get.dart';
import '../controllers/exam_analysis_controller.dart';

class ExamAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExamAnalysisController>(() => ExamAnalysisController());
  }
}
