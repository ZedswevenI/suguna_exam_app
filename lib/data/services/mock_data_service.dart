import 'package:suguna_exam_app/data/models/subject_model.dart';
import 'package:suguna_exam_app/data/models/topic_model.dart';
import 'package:suguna_exam_app/data/models/question_model.dart';

class MockDataService {
  // Mock Subjects
  static List<SubjectModel> getSubjects() {
    return [
      SubjectModel(id: '1', name: 'Mathematics', classInfo: 'Class 11'),
      SubjectModel(id: '2', name: 'Physics', classInfo: 'Class 11'),
      SubjectModel(id: '3', name: 'Chemistry', classInfo: 'Class 11'),
    ];
  }

  // Mock Topics for a subject
  static List<TopicModel> getTopics(String subjectId) {
    return [
      /* TopicModel(
        id: '1',
        name: 'Algebra',
        subtopics: [
          SubtopicModel(
            id: '1',
            name: 'Linear Equations',
            scores: {
              'Board': AssignmentScore(score: 7.5),
              'JEE Main': AssignmentScore(score: 6.0),
              'JEE Advanced': AssignmentScore(score: 4.5),
            },
          ),
          SubtopicModel(
            id: '2',
            name: 'Quadratic Equations',
            scores: {
              'Board': AssignmentScore(score: 8.5),
              'JEE Main': AssignmentScore(score: 9.0),
              'JEE Advanced': AssignmentScore(score: 7.0),
            },
          ),
          SubtopicModel(
            id: '3',
            name: 'Polynomials',
            scores: {
              'Board': AssignmentScore(score: 5.0),
              'JEE Main': AssignmentScore(score: 3.5),
              'JEE Advanced': AssignmentScore(score: 2.0),
            },
          ),
        ],
      ),
      TopicModel(
        id: '2',
        name: 'Calculus',
        subtopics: [
          SubtopicModel(
            id: '4',
            name: 'Limits',
            scores: {
              'Board': AssignmentScore(score: 6.5),
              'JEE Main': AssignmentScore(score: 5.5),
              'JEE Advanced': AssignmentScore(score: 4.0),
            },
          ),
          SubtopicModel(
            id: '5',
            name: 'Derivatives',
            scores: {
              'Board': AssignmentScore(score: 9.0),
              'JEE Main': AssignmentScore(score: 8.5),
              'JEE Advanced': AssignmentScore(score: 7.5),
            },
          ),
        ],
      ),*/
    ];
  }

  // Mock Questions for test
  static List<QuestionModel> getQuestions() {
    return List.generate(30, (index) {
      return QuestionModel(
        id: 'q${index + 1}',
        questionNumber: index + 1,
        question: 'Question ${index + 1}: What is the answer?',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswerIndex: index % 4,
        type: 'MCQ',
        marks: 4.0,
        isVisited: index < 5,
        isAnswered: index < 3,
        isMarked: index == 1,
      );
    });
  }

  // Mock Assignment Instructions
  static String getAssignmentInstructions() {
    return '''
eCM – ASSIGNMENT

Instructions:
1. Read all questions carefully before answering.
2. Each question carries 4 marks.
3. There is negative marking of -1 for each wrong answer.
4. Use only blue or black pen.
5. Calculators are not allowed.
6. Time duration: 90 minutes.
7. Submit your answer sheet before leaving the examination hall.
''';
  }
}
