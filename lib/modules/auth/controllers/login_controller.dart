import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/data/services/sessions.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/store_service.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController(
    text: kDebugMode ? '9020642480004' : "",
  );
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var loginSuccess = false.obs;

  final _apiService = ServiceLocator.get<AssignmentApiServices>();
  final StorageService _storage = StorageService();

  @override
  void onReady() {
    checkLogin();
    super.onReady();
  }


  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void gotoLogin(BuildContext? context) async {
    isLoading.value = true;
    try {
      final response = await _apiService.login(usernameController.text);
      if (response['status']) {
        Session.instance.currentUser = response;
        _storage.saveUser(response);
        Get.offAllNamed(AppRoutes.discussion, arguments: response);
      } else {
        Get.snackbar('Error', response['message']);
      }
    } catch (e) {
      Get.snackbar('Error', "$e");
    } finally {
      isLoading.value = false;
    }
  }

  void checkLogin() {
    if (_storage.isLoggedIn) {
      Session.instance.currentUser = _storage.getUser();
      Get.offAllNamed(AppRoutes.discussion);
    }
  }
}
