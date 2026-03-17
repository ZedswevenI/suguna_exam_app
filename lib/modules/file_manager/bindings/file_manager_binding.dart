import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/file_manager/controllers/file_manager_controller.dart';

class FileManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FileManagerController());
  }
}
