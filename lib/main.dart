import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/routes/route_config.dart';
import 'package:suguna_exam_app/core/services/service_locator.dart';
import 'package:suguna_exam_app/core/theme/app_theme.dart';
import 'data/services/sessions.dart';
import 'data/services/store_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await TeXRenderingServer.start();
  } catch (e) {
    debugPrint('TeXRenderingServer failed to start: $e');
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  Get.put(StorageService(), permanent: true);
  Get.put(Session());
  // Initialize GetStorage
  await GetStorage.init();
  // Initialize services
  ServiceLocator.setupServices();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Exam App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      getPages: RouteConfig.getPages(),
    );
  }
}
