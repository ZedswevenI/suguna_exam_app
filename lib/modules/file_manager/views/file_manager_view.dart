import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/utils/responsive_helper.dart';
import 'package:suguna_exam_app/core/widgets/app_layout.dart';
import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/network_service.dart';
import '../../../data/services/sessions.dart';
import '../../../data/services/store_service.dart';

class FileManagerView extends StatelessWidget {
  FileManagerView({super.key});

  final storage = Get.find<StorageService>();
  final _apiService = ServiceLocator.get<AssignmentApiServices>();

  @override
  Widget build(BuildContext context) {
    final completedTests = _getCompletedTests();
    return AppLayout(
      selectedRoute: AppRoutes.fileManager,
      showSidebar: true,
      subjectName: "File manager",
      child: completedTests.isEmpty
          ? const Center(child: Text("No completed assignments found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedTests.length,
        itemBuilder: (context, index) {
          final data = completedTests[index];
          return _buildTestCard(data);
        },
      ),
    );
  }

  // ===============================
  // READ COMPLETED TESTS FROM STORAGE
  // ===============================
  List<Map<dynamic, dynamic>> _getCompletedTests() {
    final List<Map<dynamic, dynamic>> results = [];

    final keys = storage.getAllKeys(); // ✅ FIX
    for (final key in keys) {
      if (key.startsWith("test_")) {
        final stored = storage.read(key);
        if (stored != null &&
            stored is Map &&
            stored['completed'] == true) {
          results.add(stored);
        }
      }
    }

    return results;
  }


  // ===============================
  // TEST CARD UI
  // ===============================
  Widget _buildTestCard(Map<dynamic, dynamic> data) {
    final result = data['result'] ?? {};
    // print("Data came ${}")
    final classNo = result['classNo']?.toString() ?? 'N/A';
    final subject = result['subject'] ?? 'Unknown Subject';
    final topic = result['topicName'] ?? '';
    final subtopic = result['subtopic'] ?? '';
    final category = result['category'] ?? '';
    final testNo = result['testNo']?.toString() ?? '';
    final timestamp = data['timestamp'] ?? '';
    final timestampString = data['timestamp'];
    DateTime? completedAt;

    if (timestampString != null) {
      completedAt = DateTime.tryParse(timestampString);
    }

    String formattedDate = 'N/A';

    if (completedAt != null) {
      formattedDate =
          DateFormat('dd MMM yyyy • hh:mm a').format(completedAt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ================= HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "COMPLETED",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ================= TOPIC LINE =================
          Text(
            "$topic → $subtopic",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "$category • Test $testNo",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 12),

          // ================= FOOTER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Completed at  $formattedDate",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {

                  submitTestResults(data);
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text(
                  "Upload",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> buildSubmissionFromStorage(
      Map<dynamic, dynamic> storedData
      ) {
    final result = storedData['result'] ?? {};

    final rawAnswers = result['answers'];

    final List<Map<String, dynamic>> formattedAnswers = [];

    if (rawAnswers is List) {
      for (final item in rawAnswers) {
        if (item is Map) {
          final rawId = item['serverQuestionId'];
          final userAnswer = item['userAnswer'];

          if (rawId == null || userAnswer == null) continue;

          // Extract numeric part if stored as "question_1"
          final extractedId = rawId;

          formattedAnswers.add({
            'questionId': extractedId,
            'answerRaw': userAnswer,
          });
        }
      }
    }

    return {
      'testId': result['testId'].toString().replaceAll("test_", ''),
      'subjectId': result['subjectId'],
      'classNo': Session.instance.currentUser!['data']['classNo'],
      'admissionNo': Session.instance.currentUser!['data']['admissionNo'],
      'entiId': Session.instance.currentUser!['data']['tenantId'],
      'batchId': Session.instance.currentUser!['data']['batchId'],
      'startedAt': result['startedAt'],
      'numberOfReattempts':storedData['numberOfReattempts'] ?? 1,
      'answers': formattedAnswers,
      'completedAt': result['completedAt'],
    };
  }

  Future<void> submitTestResults(Map<dynamic, dynamic> data) async {
    _showFinalizeConfirmation(() async {
      // Get.dialog(
      //   const Center(
      //     child: CircularProgressIndicator(),
      //   ),
      //   barrierDismissible: false,
      // );
      try {
        final results = buildSubmissionFromStorage(data);
        final connectivityResult = await NetworkService.hasInternet();
        if (!connectivityResult) {
          Get.snackbar(
            'Error',
            'Check your internet connection',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          Get.back();
          return;
        }
        final response = await _apiService.submitResult(results);
        if(response is Exception) {
          Get.snackbar(
            'Error',
            response.toString(),
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'Success',
            'Test results submitted successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          storage.removeByKey('test_${data['testJson']['data']['testId']}');   // example: test_64917a34...
          Get.offAndToNamed(AppRoutes.fileManager);
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to submit results. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
      }
    });

  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showFinalizeConfirmation(VoidCallback yes) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.refresh_rounded, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('Finalize ?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to finalize this test ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              yes();
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }
}