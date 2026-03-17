import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/home_assignments/controllers/home_assignments_controller.dart';

class HomeAssignmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeAssignmentsController());
  }
}
