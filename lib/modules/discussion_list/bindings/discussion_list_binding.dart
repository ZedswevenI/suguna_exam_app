import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/discussion_list/controllers/discussion_list_controller.dart';

class DiscussionListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DiscussionListController());
  }
}
