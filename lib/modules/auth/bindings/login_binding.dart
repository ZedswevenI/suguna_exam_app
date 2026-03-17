import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_config.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Register LoginController
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
