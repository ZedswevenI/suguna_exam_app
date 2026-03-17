import 'package:get/get.dart';
import '../../test_player/controllers/test_player_controller.dart';

class TestAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TestPlayerController>(
          () => TestPlayerController(),
      fenix: true,
    );
  }
}

