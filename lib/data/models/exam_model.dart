class ExamSection {
  final String sectionId;
  final String sectionCode;
  final String sectionName;
  final String subjectId;
  final int numberOfQuestions;
  final int sortOrder;
  final String status;

  ExamSection({
    required this.sectionId,
    required this.sectionCode,
    required this.sectionName,
    required this.subjectId,
    required this.numberOfQuestions,
    required this.sortOrder,
    required this.status,
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    return ExamSection(
      sectionId: json['sectionId'] ?? '',
      sectionCode: json['sectionCode'] ?? '',
      sectionName: json['sectionName'] ?? '',
      subjectId: json['subjectId'] ?? '',
      numberOfQuestions: json['numberOfQuestions'] ?? 0,
      sortOrder: json['sortOrder'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}

class ExamModel {
  final String id;
  final String tenantId;
  final String examId;
  final String examCode;
  final String examName;
  final String description;
  final String testType;
  final String medium;
  final String instructionId;
  final String calculatorType;
  final List<ExamSection> sections;
  final int totalQuestions;
  final int totalMarks;
  final int duration;
  final int startTime;
  final int endTime;
  final String status;
  final bool isLive;
  final bool isAttempted;
  final bool canAttempt;
  final bool isResultVisible;

  ExamModel({
    required this.id,
    required this.tenantId,
    required this.examId,
    required this.examCode,
    required this.examName,
    required this.description,
    required this.testType,
    required this.medium,
    required this.instructionId,
    required this.calculatorType,
    required this.sections,
    required this.totalQuestions,
    required this.totalMarks,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isLive,
    required this.isAttempted,
    required this.canAttempt,
    required this.isResultVisible,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['_id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      examId: json['examId'] ?? '',
      examCode: json['examCode'] ?? '',
      examName: json['examName'] ?? '',
      description: json['description'] ?? '',
      testType: json['testType'] ?? '',
      medium: json['medium'] ?? '',
      instructionId: json['instructionId'] ?? '',
      calculatorType: json['calculatorType'] ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => ExamSection.fromJson(s))
              .toList() ??
          [],
      totalQuestions: json['totalQuestions'] ?? 0,
      totalMarks: json['totalMarks'] ?? 0,
      duration: json['duration'] ?? 0,
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
      status: json['status'] ?? '',
      isLive: json['isLive'] ?? false,
      isAttempted: json['isAttempted'] ?? false,
      canAttempt: json['canAttempt'] ?? false,
      isResultVisible: json['isResultVisible'] ?? false,
    );
  }

  DateTime get startDateTime =>
      DateTime.fromMillisecondsSinceEpoch(startTime);

  DateTime get endDateTime =>
      DateTime.fromMillisecondsSinceEpoch(endTime);

  String get displayStatus {
    if (isResultVisible) return 'Result Published';
    if (isLive && canAttempt) return 'Live';
    if (status == 'published' && canAttempt) return 'Open';
    if (isAttempted) return 'Attempted';
    return status.replaceAll('_', ' ').capitalizeFirst;
  }
}

extension _StringExt on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
