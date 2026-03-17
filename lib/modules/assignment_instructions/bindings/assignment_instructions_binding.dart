import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/assignment_instructions/controllers/assignment_instructions_controller.dart';

class AssignmentInstructionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AssignmentInstructionsController());
  }
}
