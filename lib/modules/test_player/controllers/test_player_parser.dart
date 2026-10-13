
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/test_player/controllers/test_player_controller.dart';

import '../../../core/services/assigment_api_services.dart';
import '../../../core/services/service_locator.dart';
import '../../topic_assignments/controllers/topic_assignments_controller.dart';

// ============================================================
// API PARSER - Standalone Class
// ============================================================

class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  @override
  bool operator ==(Object other) => other is Subject && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum QuestionType {
  mcqSingle,
  mcqMultiple,
  matchTheFollowing,
  numerical,
  integer,
  subjective,
  trueFalse,
  singleDropdown,
  multiDropdown,
  textType,
}

class MatchPair {
  final String left;
  final String leftText;
  final List<String> rightOptions;
  final List<String> rightTexts;

  MatchPair({
    required this.left,
    this.leftText = '',
    required this.rightOptions,
    this.rightTexts = const [],
  });
}

class QuestionCategory {
  final String id;
  final String name;
  final int questionCount;
  final Subject? subject;
  final List<Question> questions;

  QuestionCategory({
    required this.id,
    required this.name,
    this.subject,
    required this.questionCount,
    required this.questions,
  });
}
class Question {
  final int number;
  final double positiveMarks;
  final double negativeMarks;
  final String text;
  final String questionId;
  final Subject? subject;
  final QuestionType type;
  final List<String> options;
  final List<MatchPair>? matchPairs;
  final double? minRange;
  final double? maxRange;
  final String? questionHtml;
  final String? passageHtml;
  final String? sectionId;
  /// Section `sortOrder` from the exam API; used to order subject tabs.
  final int? sectionSortOrder;
  bool isInteger;

  // ✅ Correct Answer Storage
  final String? correctAnswer;
  final List<String>? correctAnswers;
  final Map<String, String>? correctMatchAnswers;
  final double? correctNumericalAnswer;

  // ✅ User Answers
  String? selectedAnswer;
  List<String>? selectedAnswers;
  Map<String, List<String>>? matchAnswers;
  double? numericalAnswer;
  String? textAnswer;

  QuestionStatus status;

  Question({
    required this.number,
    required this.text,
    required this.type,
    required this.questionId,
    this.options = const [],
    this.matchPairs,
    this.minRange,
    this.maxRange,
    this.questionHtml,
    this.passageHtml,
    this.sectionId,
    this.sectionSortOrder,
    this.isInteger = false,
    this.subject,
    this.correctAnswer,
    this.correctAnswers,
    this.correctMatchAnswers,
    this.correctNumericalAnswer,
    this.positiveMarks = 3,
    this.negativeMarks = 1,
    this.selectedAnswer,
    this.selectedAnswers,
    this.matchAnswers,
    this.numericalAnswer,
    this.textAnswer,
    this.status = QuestionStatus.notVisited,
  });
}
enum QuestionStatus {
  answered,
  notAnswered,
  markedForReview,
  answeredAndMarked,
  notVisited,
}



class TestApiParser {

  static String fixBrokenJson(String raw) {
    return raw
        .replaceAll('\t', '\\t')
        .replaceAll('\n\n', '\n')   // newline
        .replaceAll('\r', '\\r')   // carriage return
    // Fix HTML attributes
        .replaceAllMapped(
      RegExp(r'style="([^"]*)"'),
          (m) => 'style=\\"${m[1]}\\"',
    )
        .replaceAllMapped(
      RegExp(r'align="([^"]*)"'),
          (m) => 'align=\\"${m[1]}\\"',
    )

    // ✅ Fix ONLY single-backslash LaTeX (ignore already-escaped \\)
        .replaceAllMapped(
      RegExp(r'(?<!\\)\\([a-zA-Z()])'),
          (m) => '\\\\${m[1]}',
    );
  }

  static bool _isDoubleEncoded(String s) {
    return s.trim().startsWith('"') && s.contains('\\n');
  }

  static Future<Map<String, dynamic>> loadQuestionsJson() async {
    // final _apiService = ServiceLocator.get<AssignmentApiServices>();
    final rawString = await rootBundle.loadString('assets/test.json');

    final fixedString = fixBrokenJson(rawString);

    // Handle double-encoded JSON
    if (_isDoubleEncoded(fixedString)) {
      final inner = json.decode(fixedString);
      return json.decode(inner) as Map<String, dynamic>;
    }

    return json.decode(fixedString) as Map<String, dynamic>;
  }


  // Parse from JSON string
  static Future<List<QuestionCategory>> parseFromJsonString(Map<String, dynamic> jsonString) async {
    try {
      final Map<String, dynamic> jsons =   await loadQuestionsJson();
      return parseApiResponse(jsonString);
    } catch (e) {
      print('Error parsing JSON string: $e');
      return [];
    }
  }

  // static List<QuestionCategory> parseApiResponse(
  //     Map<String, dynamic> jsonData,
  //     ) {
  //   try {
  //     final Map<String, dynamic> correctAnswersMap = {};
  //     final testData = jsonData['data'] as Map<String, dynamic>;
  //     final List<dynamic> questionsJson = testData['questions'] as List<dynamic>;
  //
  //     // Group by subject instead of question type
  //     final Map<String, List<Question>> questionsBySubject = {};
  //     final Map<String, Subject> subjectLookup = {};
  //
  //     for (int i = 0; i < questionsJson.length; i++) {
  //       final qJson = questionsJson[i] as Map<String, dynamic>;
  //       final correctAnswer = qJson['correctAnswer'];
  //
  //       // Parse subject
  //       final subjectJson = qJson['subject'] as Map<String, dynamic>?;
  //       final subject = subjectJson != null
  //           ? Subject(
  //         id: subjectJson['id']?.toString() ?? 'unknown',
  //         name: subjectJson['subjectName']?.toString() ?? 'General',
  //       )
  //           : Subject(id: 'unknown', name: 'General');
  //
  //       subjectLookup[subject.id] = subject;
  //
  //       final questionTypeFromApi = qJson['questionType'] as String? ?? 'mcq_single';
  //       final parsedType = _parseQuestionType(questionTypeFromApi);
  //
  //       final question = Question(
  //         questionId: qJson['questionId'] as String? ?? '',
  //         number: i + 1,
  //         positiveMarks: _parseToDouble(qJson['positiveMarks'], defaultValue: 3),
  //         negativeMarks: _parseToDouble(qJson['negativeMarks'], defaultValue: 1),
  //         text: qJson['questionText'] as String? ?? '',
  //         questionHtml: qJson['questionHtml'] as String?,
  //         type: parsedType,
  //         subject: subject,                          // ← PASS SUBJECT
  //         options: _parseOptions(
  //           qJson['questionOptions'] as List<dynamic>? ?? [],
  //         ),
  //         status: QuestionStatus.notVisited,
  //       );
  //
  //       if (correctAnswer != null) {
  //         correctAnswersMap['question_${i + 1}'] = correctAnswer;
  //       }
  //
  //       questionsBySubject.putIfAbsent(subject.id, () => []).add(question);
  //     }
  //
  //     // Build categories from subjects
  //     final List<QuestionCategory> categories = [];
  //     int categoryIndex = 0;
  //
  //     questionsBySubject.forEach((subjectId, questions) {
  //       final subject = subjectLookup[subjectId]!;
  //       categories.add(
  //         QuestionCategory(
  //           id: 'category_$categoryIndex',
  //           name: subject.name,           // ← Subject name as tab label
  //           subject: subject,             // ← pass subject (see below)
  //           questionCount: questions.length,
  //           questions: questions,
  //         ),
  //       );
  //       categoryIndex++;
  //     });
  //
  //     try {
  //       final controller = Get.find<TestPlayerController>();
  //       controller.correctAnswersMap = correctAnswersMap;
  //     } catch (e) {
  //       print('Controller not found: $e');
  //     }
  //
  //     return categories;
  //   } catch (e) {
  //     print('Error parsing API response: $e');
  //     return [];
  //   }
  // }


  // Main parser for API response
  static List<QuestionCategory> parseApiResponse(
      Map<String, dynamic> jsonData,
      ) {
    try {
      final Map<String, dynamic> correctAnswersMap = {};
      final testData = jsonData['data'] as Map<String, dynamic>;

      final List<dynamic> questionsJson =
      testData['questions'] as List<dynamic>;
      final Map<QuestionType, List<Question>> questionsByType = {};

      for (int i = 0; i < questionsJson.length; i++) {
        final qJson = questionsJson[i] as Map<String, dynamic>;
        final subjectJson = qJson['subject'] as Map<String, dynamic>?;
        final subject = subjectJson != null
            ? Subject(
          id: subjectJson['id']?.toString() ?? 'unknown',
          name: subjectJson['subjectName']?.toString() ?? 'General',
        )
            : null;
        final correctAnswer = qJson['correctAnswer'];
        final questionTypeFromApi =
            qJson['questionType'] as String? ?? 'mcq_single';
        final parsedType = _parseQuestionType(questionTypeFromApi);
        final rawOptions = qJson['questionOptions'] as List<dynamic>? ?? [];
        final passageData = qJson['passageData'] as Map<String, dynamic>?;
        final question = Question(
          questionId: qJson['questionId'] as String? ?? '',
          number: i + 1,
          subject: subject,
          positiveMarks: _parseToDouble(qJson['positiveMarks'], defaultValue: 3),
          negativeMarks: _parseToDouble(qJson['negativeMarks'], defaultValue: 1),
          text: qJson['questionText'] as String? ?? '',
          questionHtml: withAttachedImages(
              qJson, qJson['questionHtml'] as String? ?? ''),
          passageHtml: passageData?['passageHtml'] != null
              ? _stripLatexSpans(passageData!['passageHtml'] as String)
              : null,
          type: parsedType,
          isInteger: questionTypeFromApi.toLowerCase() == 'integer',
          options: _parseOptions(rawOptions),
          matchPairs: parsedType == QuestionType.matchTheFollowing
              ? _parseMatchPairsFromColumns(qJson)
              : null,
          status: QuestionStatus.notVisited,
        );
        if (correctAnswer != null) {
          correctAnswersMap['question_${i + 1}'] = correctAnswer;
        }
        questionsByType.putIfAbsent(parsedType, () => []).add(question);
      }

      final List<QuestionCategory> categories = [];
      int categoryIndex = 0;

      questionsByType.forEach((type, questions) {
        categories.add(
          QuestionCategory(
            id: 'category_$categoryIndex',
            name: _getCategoryNameFromType(type),
            questionCount: questions.length,
            questions: questions,
          ),
        );
        categoryIndex++;
      });

      try {
        final controller = Get.find<TestPlayerController>();
        controller.correctAnswersMap = correctAnswersMap;
      } catch (e) {
        print('Controller not found: $e');
      }

      return categories;
    } catch (e) {
      print('Error parsing API response: $e');
      return [];
    }
  }

  /// Parser for exam questions (flat questions array with subjectId object)
  static List<QuestionCategory> parseExamResponse(
      Map<String, dynamic> examData,
      ) {
    try {
      final Map<String, dynamic> correctAnswersMap = {};
      final List<dynamic> questionsJson =
          examData['questions'] as List<dynamic>? ?? [];

      // Group by SUBJECT first, then by question-type category. Each tab
      // therefore belongs to exactly one subject, so the subject filter,
      // the tab counts and next/previous navigation all stay inside the
      // selected subject.
      final Map<String, Map<_ExamCategory, List<Question>>> bySubject = {};
      // Subject display order: section sortOrder when present, else the
      // order the subjects first appear in the paper.
      final Map<String, int> subjectOrder = {};
      final Map<String, Subject?> subjectLookup = {};
      var appearance = 0;

      for (int i = 0; i < questionsJson.length; i++) {
        final qJson = Map<String, dynamic>.from(questionsJson[i] as Map);

        // Parse subject from subjectId object (exam format)
        Subject? subject;
        final rawSubjectData = qJson['subjectId'];
        final subjectData = rawSubjectData is Map ? Map<String, dynamic>.from(rawSubjectData) : rawSubjectData;
        if (subjectData is Map<String, dynamic>) {
          subject = Subject(
            id: subjectData['_id']?.toString() ?? 'unknown',
            name: subjectData['subjectName']?.toString() ?? 'General',
          );
        } else if (subjectData is String) {
          subject = Subject(id: subjectData, name: 'General');
        }

        final correctAnswer = qJson['correctAnswer'];
        final questionTypeFromApi =
            qJson['questionType'] as String? ?? 'mcq_single';
        final parsedType = _parseQuestionType(questionTypeFromApi);

        final sectionId = qJson['sectionId']?.toString();
        final sectionSortOrder = (qJson['sectionSortOrder'] as num?)?.toInt();

        final rawOptions = qJson['questionOptions'] as List<dynamic>? ?? [];
        final passageData = qJson['passageData'] as Map<String, dynamic>?;
        final question = Question(
          questionId: qJson['questionId'] as String? ?? '',
          number: i + 1,
          subject: subject,
          sectionId: sectionId,
          sectionSortOrder: sectionSortOrder,
          positiveMarks: _parseToDouble(qJson['positiveMarks'], defaultValue: 4),
          negativeMarks: _parseToDouble(qJson['negativeMarks'], defaultValue: 1),
          text: qJson['questionText'] as String? ?? '',
          questionHtml: withAttachedImages(qJson,
              _stripLatexSpans(qJson['questionHtml'] as String? ?? '')),
          passageHtml: passageData?['passageHtml'] != null
              ? _stripLatexSpans(passageData!['passageHtml'] as String)
              : null,
          type: parsedType,
          isInteger: questionTypeFromApi.toLowerCase() == 'integer',
          options: _parseOptions(rawOptions),
          matchPairs: parsedType == QuestionType.matchTheFollowing
              ? _parseMatchPairsFromColumns(qJson)
              : null,
          minRange: _parseToNullableDouble(qJson['numericMin']),
          maxRange: _parseToNullableDouble(qJson['numericMax']),
          status: QuestionStatus.notVisited,
        );

        if (correctAnswer != null) {
          correctAnswersMap['question_${i + 1}'] = correctAnswer;
        }

        final category = _examCategoryFor(
          type: parsedType,
          hasPassage: (question.passageHtml ?? '').trim().isNotEmpty,
        );

        final subjectKey = subject?.name ?? 'General';
        subjectLookup.putIfAbsent(subjectKey, () => subject);
        final order = sectionSortOrder ?? ((1 << 20) + appearance);
        subjectOrder.update(subjectKey, (v) => v < order ? v : order,
            ifAbsent: () {
          appearance++;
          return order;
        });
        bySubject
            .putIfAbsent(subjectKey, () => {})
            .putIfAbsent(category, () => [])
            .add(question);
      }

      final List<QuestionCategory> categories = [];
      int categoryIndex = 0;

      final subjectKeys = bySubject.keys.toList()
        ..sort((a, b) => subjectOrder[a]!.compareTo(subjectOrder[b]!));

      // Emit tabs subject by subject, each subject's types in enum
      // (display) order, skipping empty ones.
      for (final subjectKey in subjectKeys) {
        final byCategory = bySubject[subjectKey]!;
        for (final kind in _ExamCategory.values) {
          final questions = byCategory[kind];
          if (questions == null || questions.isEmpty) continue;
          categories.add(
            QuestionCategory(
              id: 'category_$categoryIndex',
              name: kind.label,
              subject: subjectLookup[subjectKey],
              questionCount: questions.length,
              questions: questions,
            ),
          );
          categoryIndex++;
        }
      }

      try {
        final controller = Get.find<TestPlayerController>();
        controller.correctAnswersMap = correctAnswersMap;
      } catch (e) {
        print('Controller not found: $e');
      }

      return categories;
    } catch (e) {
      print('Error parsing exam response: $e');
      return [];
    }
  }

  /// Maps a parsed exam question to its tab category. Comprehension = any
  /// question that carries passage HTML; everything else is by type.
  static _ExamCategory _examCategoryFor({
    required QuestionType type,
    required bool hasPassage,
  }) {
    if (hasPassage) return _ExamCategory.comprehension;
    switch (type) {
      case QuestionType.mcqSingle:
        return _ExamCategory.singleCorrect;
      case QuestionType.mcqMultiple:
        return _ExamCategory.multiCorrect;
      case QuestionType.integer:
        return _ExamCategory.integer;
      case QuestionType.numerical:
        return _ExamCategory.numerical;
      case QuestionType.matchTheFollowing:
        return _ExamCategory.matchTheFollowing;
      case QuestionType.trueFalse:
        return _ExamCategory.trueFalse;
      case QuestionType.singleDropdown:
        return _ExamCategory.singleDropdown;
      case QuestionType.multiDropdown:
        return _ExamCategory.multiDropdown;
      case QuestionType.textType:
        return _ExamCategory.shortAnswer;
      case QuestionType.subjective:
        return _ExamCategory.subjective;
    }
  }

  static double? _parseToNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double _parseToDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;

    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }

    return defaultValue;
  }

  static String _getCategoryNameFromType(QuestionType type) {
    switch (type) {
      case QuestionType.mcqSingle:
        return 'SCO ';

      case QuestionType.mcqMultiple:
        return 'MCQ (Multiple Correct)';

      case QuestionType.matchTheFollowing:
        return 'Match the Following';

      case QuestionType.numerical:
        return 'Numerical';

      case QuestionType.integer:
        return 'Integer';

      case QuestionType.textType:
        return 'Short Answer';

      case QuestionType.subjective:
        return 'Subjective';

      case QuestionType.trueFalse:
        return 'True / False';

      case QuestionType.singleDropdown:
        return 'Dropdown (Single Select)';

      case QuestionType.multiDropdown:
        return 'Dropdown (Multiple Select)';

      default:
        return 'Other Questions';
    }
  }

  // Parse question type from API string to enum
  static QuestionType _parseQuestionType(String apiType) {
    switch (apiType.toLowerCase()) {
      case 'mcq_single':
        return QuestionType.mcqSingle;
      case 'mcq_multi':
      case 'mcq_multiple':
        return QuestionType.mcqMultiple;
      case 'match_the_following':
      case 'maq':
      case 'matrix':
      case 'matrix_match':
        return QuestionType.matchTheFollowing;
      case 'integer':
        return QuestionType.integer;
      case 'numerical':
      case 'numeric':
        return QuestionType.numerical;
      case 'short_answer':
        return QuestionType.textType;
      case 'subjective':
        return QuestionType.subjective;
      case 'true_false':
      case 'boolean':
        return QuestionType.trueFalse;
      case 'single_dropdown':
      case 'dropdown':
        return QuestionType.singleDropdown;
      case 'multi_dropdown':
        return QuestionType.multiDropdown;
      default:
        return QuestionType.mcqSingle; // Default fallback
    }
  }

  // Parse options from API
  static List<String> _parseOptions(List<dynamic> optionsJson) {
    return optionsJson
        .map((opt) {
      final optMap = opt is Map ? Map<String, dynamic>.from(opt) : <String, dynamic>{};
      final raw = optMap['textHtml'] as String? ??
          optMap['text'] as String? ??
          '';
      return _stripLatexSpans(raw);
    })
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Parse match pairs from leftColumn / rightColumn for matrix type questions.
  /// Each left item gets all right column values as rightOptions.
  static List<MatchPair>? _parseMatchPairsFromColumns(Map<String, dynamic> qJson) {
    final leftCol = qJson['leftColumn'] as List<dynamic>? ?? [];
    final rightCol = qJson['rightColumn'] as List<dynamic>? ?? [];

    if (leftCol.isEmpty && rightCol.isEmpty) return null;

    // Collect right column labels and texts
    final List<String> rightLabels = [];
    final List<String> rightTexts = [];
    for (int i = 0; i < rightCol.length; i++) {
      final rMap = rightCol[i] is Map
          ? Map<String, dynamic>.from(rightCol[i] as Map)
          : <String, dynamic>{};
      final key = rMap['key'] as String? ?? '';
      rightLabels.add(key.isNotEmpty ? key : String.fromCharCode(80 + i)); // P, Q, R, S, T
      rightTexts.add(_stripLatexSpans(rMap['text'] as String? ?? ''));
    }

    // Build a MatchPair for each left column item
    final List<MatchPair> pairs = [];
    for (int i = 0; i < leftCol.length; i++) {
      final lMap = leftCol[i] is Map
          ? Map<String, dynamic>.from(leftCol[i] as Map)
          : <String, dynamic>{};
      final key = lMap['key'] as String? ?? '';
      final label = key.isNotEmpty ? key : String.fromCharCode(65 + i); // A, B, C, D
      pairs.add(MatchPair(
        left: label,
        leftText: _stripLatexSpans(lMap['text'] as String? ?? ''),
        rightOptions: List<String>.from(rightLabels),
        rightTexts: List<String>.from(rightTexts),
      ));
    }

    return pairs.isNotEmpty ? pairs : null;
  }

  /// Converts <span class="latex">$...$</span> to \(...\) for TeXView rendering
  static String _stripLatexSpans(String html) {
    // Step 1: Unwrap <span class="latex">...</span> tags
    var result = html.replaceAllMapped(
      RegExp(r'<span\s+class="latex">\s*(.*?)\s*</span>', dotAll: true),
          (match) => match.group(1) ?? '',
    );
    // Step 2: Convert $...$ delimiters to \(...\) which TeXView supports
    result = result.replaceAllMapped(
      RegExp(r'\$(.+?)\$', dotAll: true),
          (match) => '\\(${match.group(1)}\\)',
    );
    return result;
  }


  /// Questions may carry pictures as attachments in `images[]`
  /// (`{url, dataUrl?, label, order}`) with no `<img>` in the HTML at all.
  /// Append them under the question text so every renderer shows them.
  /// Prefers the embedded `dataUrl` (works offline); skips an attachment
  /// whose URL is already referenced inline to avoid showing it twice.
  static String withAttachedImages(Map<String, dynamic> qJson, String html) {
    final images = qJson['images'];
    if (images is! List || images.isEmpty) return html;
    final entries = <Map>[];
    for (final im in images) {
      if (im is Map) entries.add(im);
    }
    entries.sort((a, b) =>
        ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
    final buf = StringBuffer(html);
    for (final im in entries) {
      final url = (im['url'] ?? '').toString();
      final src = (im['dataUrl'] ?? url).toString();
      if (src.isEmpty) continue;
      if (url.isNotEmpty && html.contains(url)) continue;
      buf.write(
        '<div style="margin:12px 0;"><img src="$src" '
        'style="max-width:100%;height:auto;display:block;"></div>',
      );
    }
    return buf.toString();
  }

  String normalizeQuestionHtml(String input) {
    return input
    // Fix escaped LaTeX brackets
        .replaceAll(r'\\(', r'\(')
        .replaceAll(r'\\)', r'\)')

    // Fix escaped square brackets
        .replaceAll(r'\\[', r'\[')
        .replaceAll(r'\\]', r'\]')

    // Replace smart minus with normal minus
        .replaceAll('−', '-')

    // Replace pi symbol
        .replaceAll('π', r'\pi')

    // Replace union symbol
        .replaceAll('∪', r'\cup')

    // Fix common inverse trig issues
        .replaceAll('sin−1', r'\sin^{-1}')
        .replaceAll('cos−1', r'\cos^{-1}')
        .replaceAll('tan−1', r'\tan^{-1}')
        .replaceAll('cot−1', r'\cot^{-1}')
        .replaceAll('sec−1', r'\sec^{-1}')
        .replaceAll('cosec−1', r'\cosec^{-1}');
  }

}

/// Tab categories for the exam player, in display order. Labels match the
/// existing type names from [TestApiParser._getCategoryNameFromType].
enum _ExamCategory {
  singleCorrect('SCO '),
  multiCorrect('MCQ (Multiple Correct)'),
  integer('Integer'),
  numerical('Numerical'),
  comprehension('Comprehension Type'),
  matchTheFollowing('Match the Following'),
  trueFalse('True / False'),
  singleDropdown('Dropdown (Single Select)'),
  multiDropdown('Dropdown (Multiple Select)'),
  shortAnswer('Short Answer'),
  subjective('Subjective');

  const _ExamCategory(this.label);
  final String label;
}
