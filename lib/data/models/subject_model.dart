class SubjectModel {
  final String id;
  final String name;
  final String classInfo;

  SubjectModel({
    required this.id,
    required this.name,
    required this.classInfo,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: (json['subjectId'] ?? json['_id'] ?? '').toString(),
      name: (json['subjectName'] ?? json['name'] ?? '').toString(),
      classInfo: json['classNo'] != null
          ? 'Class ${json['classNo']}'
          : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': id,
      'subjectName': name,
      'classNo': classInfo.replaceAll('Class ', ''),
    };
  }
}