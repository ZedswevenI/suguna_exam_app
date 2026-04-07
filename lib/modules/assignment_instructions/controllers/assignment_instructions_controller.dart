import 'package:get/get.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';

class AssignmentInstructionsController extends GetxController {
  final instructionTitle = ''.obs;
  final instructionContentHtml = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadInstructions();
  }

  void loadInstructions() {
    final args = Get.arguments;
    if (args != null) {
      final examData = args['selectedQuestion'] as Map<String, dynamic>?;
      if (examData != null) {
        final instr = examData['instructions'];
        if (instr is Map) {
          instructionTitle.value = (instr['title'] ?? '').toString();
          instructionContentHtml.value = (instr['contentHtml'] ?? '').toString();
        }
      }
    }
  }

  void onAccept() {
    Get.toNamed(AppRoutes.testPlayer, arguments: Get.arguments);
  }

  void onDecline() {
    Get.back();
  }
}
