import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/usage/controllers/usage_controller.dart';

class UsageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UsageController());
  }
}
