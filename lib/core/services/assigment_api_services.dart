import '../../data/models/subject_model.dart';
import '../../data/services/sessions.dart';
import 'api_service.dart';

/// API Service for Circulars Module
class AssignmentApiServices extends ApiService {
  /// Get all circulars
  Future<dynamic> getAssignments(String endId,String regNo) async {
    try {
      final response = await post(
        '/student/get/assnsubjects',
        body: {
          "entiId":endId,
          "regNo": regNo
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getAssignmentTopics(String subjectName,int classNo,String regNo,String entId) async {
    try {
      final response = await post(
        '/student/get/assignments',
        body: {
          "entiId":entId,
          "regNo":regNo,
          "subjectId" : subjectName,
          "classNo" : classNo
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> loadQuestions(String subjectName,int classNo,String testId,String regNo,String entId) async {
    try {
      final response = await post(
        '/student/download/assignments',
        body: {
          "entiId":entId,
          "regNo": regNo,
          "testId": testId,
          "subjectId": subjectName,
          "classNo":classNo
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getAnswers(String batchId,String testId,String regNo,String entId) async {
    try {
      final response = await post(
        '/assignment/result/list/student?testId=$testId',
        body: {
          "entiId":entId,
          "admissionNo": regNo,
          "batchId": batchId,
          'testId': testId
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }


  /// Mark circular as read
  Future<Map<String, dynamic>> login(String endId) async {
    try {
      final response = await post('/student/login',body: {
        "regNo":endId
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get circular read status
  Future<dynamic> submitResult(dynamic body) async {
    try {
      final response = await post(
        '/assignment/result/submit',
        body: body,
      );
      return response;
    } catch (e) {
      return e;
    }
  }

  Future<dynamic> downloadQuestionImage(String url) async {
    return await post(
      '/assignment/question/image/download',
      body: {
        "url": url,
      },
    );
  }


  Future<dynamic> bookMarkQuestion(Map<String,dynamic> body) async {
    return await post(
      '/assignment/question/bookmark/create',
      body: body,
    );
  }

  Future<dynamic> removeBookmark(Map<String,dynamic> body) async {
    return await post(
      '/assignment/question/bookmark/remove',
      body: body,
    );
  }

  Future<dynamic> loadBookmarks() async {
    return await post(
      '/assignment/question/bookmark/list/?studentId=${Session.instance.currentUser!['data']['studentId']}',
      body: {
        "entiId": Session.instance.currentUser!['data']['tenantId']
      },
    );
  }


  Future<dynamic> reportQuestion(Map<String,dynamic> body) async {
    return await post(
      '/assignment/question/report/create',
      body: body,
    );
  }
  // assignment/question/bookmark/create

  Future<dynamic> getExamQuestions(String tenantId, String examId, String examCode, String password) async {
    try {
      final response = await post(
        '/exam/questions/get-questions',
        body: {
          "tenantId": tenantId,
          "examId": examId,
          "examCode": examCode,
          "password": password,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> submitExamResult(Map<String, dynamic> body) async {
    try {
      final response = await post(
        '/exam/result/submit',
        body: body,
      );
      return response;
    } catch (e) {
      return e;
    }
  }

  Future<dynamic> downloadExamQuestionImage(String url) async {
    return await post(
      '/exam/questions/image/download',
      body: {
        "url": url,
      },
    );
  }

  Future<dynamic> getExamList(String entiId, String batchId, String admissionNo) async {
    try {
      final response = await post(
        '/exam/student-list',
        body: {
          "entiId": entiId,
          "batchId": batchId,
          "admissionNo": admissionNo,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
