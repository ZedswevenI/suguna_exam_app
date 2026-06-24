import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:managed_configurations/managed_configurations.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/routes/route_config.dart';
import 'package:suguna_exam_app/core/services/assigment_api_services.dart';
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
  await GetStorage.init();
  ServiceLocator.setupServices();

  await _tryMdmSilentLogin();

  runApp(const MyApp());
}

/// Reads MDM config, silently logs in if enrollmentNumber is set and user is
/// not already authenticated. Saves the session to storage so that
/// LoginController.checkLogin() navigates straight to discussion on startup.
Future<void> _tryMdmSilentLogin() async {
  try {
    final config = await ManagedConfigurations().getManagedConfigurations;
    final enrollmentNumber = config?['enrollmentNumber']?.toString();
    if (enrollmentNumber == null || enrollmentNumber.isEmpty) return;

    final storage = Get.find<StorageService>();
    if (storage.isLoggedIn) return;

    final apiService = ServiceLocator.get<AssignmentApiServices>();
    final response = await apiService.login(enrollmentNumber);
    if (response['status'] == true || response['status'] == 'true') {
      Session.instance.currentUser = response;
      storage.saveUser(response);
    }
  } catch (e) {
    debugPrint('MDM silent login failed: $e');
  }
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
