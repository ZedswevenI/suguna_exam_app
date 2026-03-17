import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/test_player/controllers/test_player_controller.dart';

class TestPlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TestPlayerController(),fenix: true);
    // Get.put(TestPlayerController(),permanent: true);
  }
}
