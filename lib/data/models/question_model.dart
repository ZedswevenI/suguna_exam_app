class QuestionModel {
  final String id;
  final int questionNumber;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final int? userAnswerIndex;
  final bool isMarked;
  final bool isVisited;
  final bool isAnswered;
  final String? type; // "MCQ", "Integer", etc.
  final double? marks;
  final double? userMarks;

  QuestionModel({
    required this.id,
    required this.questionNumber,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.userAnswerIndex,
    this.isMarked = false,
    this.isVisited = false,
    this.isAnswered = false,
    this.type,
    this.marks,
    this.userMarks,
  });
}
