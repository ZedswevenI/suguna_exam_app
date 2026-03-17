import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/topic_assignments/controllers/topic_assignments_controller.dart';

class TopicAssignmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TopicAssignmentsController());
  }
}
