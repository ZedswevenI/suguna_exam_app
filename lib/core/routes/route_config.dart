import 'package:get/get.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/modules/auth/bindings/login_binding.dart';
import 'package:suguna_exam_app/modules/auth/views/login_view.dart';
import 'package:suguna_exam_app/modules/home_assignments/bindings/home_assignments_binding.dart';
import 'package:suguna_exam_app/modules/home_assignments/views/home_assignments_view.dart';
import 'package:suguna_exam_app/modules/test_player/views/test_review_view.dart';
import 'package:suguna_exam_app/modules/topic_assignments/bindings/topic_assignments_binding.dart';
import 'package:suguna_exam_app/modules/topic_assignments/views/topic_assignments_view.dart';
import 'package:suguna_exam_app/modules/assignment_instructions/bindings/assignment_instructions_binding.dart';
import 'package:suguna_exam_app/modules/assignment_instructions/views/assignment_instructions_view.dart';
import 'package:suguna_exam_app/modules/test_player/bindings/test_player_binding.dart';
import 'package:suguna_exam_app/modules/test_player/views/test_player_view.dart';
import 'package:suguna_exam_app/modules/test_analysis/bindings/test_analysis_binding.dart';
import 'package:suguna_exam_app/modules/test_analysis/views/test_analysis_view.dart';
import 'package:suguna_exam_app/modules/question_review/bindings/question_review_binding.dart';
import 'package:suguna_exam_app/modules/question_review/views/question_review_view.dart';
import 'package:suguna_exam_app/modules/usage/bindings/usage_binding.dart';
import 'package:suguna_exam_app/modules/usage/views/usage_view.dart';
import 'package:suguna_exam_app/modules/file_manager/bindings/file_manager_binding.dart';
import 'package:suguna_exam_app/modules/file_manager/views/file_manager_view.dart';
import 'package:suguna_exam_app/modules/discussion_list/bindings/discussion_list_binding.dart';
import 'package:suguna_exam_app/modules/reset/bindings/reset_binding.dart';
import 'package:suguna_exam_app/modules/reset/views/reset_view.dart';
import 'package:suguna_exam_app/modules/exam_result/bindings/exam_result_binding.dart';
import 'package:suguna_exam_app/modules/exam_result/views/exam_result_view.dart';
import 'package:suguna_exam_app/modules/exam_result/views/exam_question_review_view.dart';

import '../../modules/discussion_list/views/download_test.dart';

class RouteConfig {
  static List<GetPage> getPages() {
    return [
      GetPage(
        name: AppRoutes.home,
        page: () => const HomeAssignmentsView(),
        binding: HomeAssignmentsBinding(),
      ),
      GetPage(
        name: AppRoutes.login,
        page: () => const LoginView(),
        binding: LoginBinding(),
      ),
      GetPage(
        name: AppRoutes.topicAssignments,
        page: () => const TopicAssignmentsView(),
        binding: TopicAssignmentsBinding(),
      ),
      GetPage(
        name: AppRoutes.assignmentInstructions,
        page: () => const AssignmentInstructionsView(),
        binding: AssignmentInstructionsBinding(),
      ),
      GetPage(
        name: AppRoutes.testPlayer,
        page: () => TestPlayerView(),
        binding: TestPlayerBinding(),
      ),
      GetPage(
        name: AppRoutes.testAnalysis,
        page: () => const TestAnalysisView(),
        binding: TestAnalysisBinding(),
      ),
      GetPage(
        name: AppRoutes.testReview,
        page: () => const TestResultView(),
      ),
      GetPage(
        name: AppRoutes.questionReview,
        page: () => const QuestionReviewView(),
        binding: QuestionReviewBinding(),
      ),
      GetPage(
        name: AppRoutes.usage,
        page: () => const UsageView(),
        binding: UsageBinding(),
      ),
      GetPage(
        name: AppRoutes.fileManager,
        page: () =>  FileManagerView(),
        binding: FileManagerBinding(),
      ),
      GetPage(
        name: AppRoutes.discussion,
        page: () => const DownloadTest(),
        binding: DiscussionListBinding(),
      ),
      GetPage(
        name: AppRoutes.reset,
        page: () => const ResetView(),
        binding: ResetBinding(),
      ),
      GetPage(
        name: AppRoutes.examResult,
        page: () => const ExamResultView(),
        binding: ExamResultBinding(),
      ),
      GetPage(
        name: AppRoutes.examQuestionReview,
        page: () => const ExamQuestionReviewView(),
      ),
    ];
  }
}
