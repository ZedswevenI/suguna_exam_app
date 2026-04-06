import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

class ExamResultController extends GetxController {
  final resultData = Rxn<Map<String, dynamic>>();
  final examInfo = Rxn<Map<String, dynamic>>();
  final reviewIndex = 0.obs;
  final selectedSectionIndex = 0.obs;
  final expandedSolutions = <int>{}.obs;

  // Static demo result generated from exam questions JSON
  static const Map<String, dynamic> _staticResult = {
    "status": true,
    "message": "Result with answers loaded",
    "data": {
      "examId": "07469883-8c63-4187-91ef-2e8419278511",
      "admissionNo": "90202590032",
      "obtainedMarks": 23,
      "totalMarks": 56,
      "rank": 3,
      "percentile": 72.5,
      "timeTaken": 4320000,
      "isLate": false,
      "sectionResults": [
        {
          "sectionId": "sec_biology",
          "sectionName": "BIOLOGY",
          "subjectId": "698aa4dcc755cd5c9d0f8b74",
          "totalQuestions": 12,
          "answeredCount": 10,
          "correctCount": 6,
          "wrongCount": 4,
          "skippedCount": 2,
          "totalMarks": 48,
          "obtainedMarks": 20,
          "timeTaken": 3480000
        },
        {
          "sectionId": "sec_botany",
          "sectionName": "BOTANY",
          "subjectId": "6996c84b44270d1d1d172e06",
          "totalQuestions": 2,
          "answeredCount": 2,
          "correctCount": 1,
          "wrongCount": 1,
          "skippedCount": 0,
          "totalMarks": 8,
          "obtainedMarks": 3,
          "timeTaken": 840000
        }
      ],
      "graceLogs": [],
      "answers": [
        {
          "questionId": "232d7f48-e474-42ff-9ff0-c040364bcc2d",
          "sectionId": "sec_biology",
          "answerRaw": "A",
          "correctAnswer": "A",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 133000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "integer",
          "difficulty": "easy",
          "questionHtml": "Let <span class=\"latex\">\$Z\$</span> be set of integers. If <span class=\"latex\">\$A = \\{x\\, \\in \\, Z : |x – 3|^{(x^2 – 3x + 6)} = 1\\} \\,\\, and \\,\\, B = \\{x\\,\\in\\,Z : 10 < 3x + 1 < 22\\},\$</span> then the number of subsets of the set <span class=\"latex\">\$A \\times B\$</span> is",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$2^9\$</span>", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$2^8\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$2^6\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$2^{15}\$</span>", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "Since <span class=\"latex\">\$|x-3|^{(x^2-3x+6)}=1\$</span>, we need the base to be 1 or -1, or the exponent to be 0. Solving gives A = {2, 3, 4} and B has 3 elements. So |A × B| = 9, and subsets = <span class=\"latex\">\$2^9\$</span>.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 1,
          "passage": null
        },
        {
          "questionId": "3ce142eb-2cdc-4767-834a-2351c13e2b3b",
          "sectionId": "sec_biology",
          "answerRaw": "C",
          "correctAnswer": "B",
          "isCorrect": false,
          "isSkipped": false,
          "marksAwarded": -1,
          "timeTaken": 172000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "medium",
          "questionHtml": "Sugar moiety in DNA and RNA molecules respectively are",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$\\beta – D – 2 \$</span> deoxyribose, <span class=\"latex\">\$\\beta – D - \$</span> deoxyribose", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$\\beta – D – 2 - \$</span> deoxyribose, <span class=\"latex\">\$\\beta – D - \$</span> ribose", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$\\beta – D - \$</span>ribose, <span class=\"latex\">\$\\beta – D – 2- \$</span> deoxyribose", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$\\beta – D - \$</span> deoxyribose, <span class=\"latex\">\$\\beta – D – 2 - \$</span> deoxyribose", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "DNA contains β-D-2-deoxyribose sugar and RNA contains β-D-ribose sugar. The correct answer is B.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 2,
          "passage": null
        },
        {
          "questionId": "3df683e3-cd0a-4b61-8915-a814736dfde5",
          "sectionId": "sec_biology",
          "answerRaw": "B",
          "correctAnswer": "B",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 245000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "easy",
          "questionHtml": "A composite bar has two segments of equal length L each. Both segments are made of same material but cross sectional area of segment OB is twice that of OA. The bar is kept on a smooth table with the joint at the origin of the co-ordinate system attached to the table. Temperature of the composite bar is uniformly raised by <span class=\"latex\">\$\\Delta \\theta\$</span>. Calculate the x co-ordinate of the joint if coefficient of linear thermal expansion for the material is <span class=\"latex\">\$\\alpha°C^{-1}\$</span>.",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$L(\\alpha)(\\delta \\theta)/6\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$–L(\\alpha)(\\delta \\theta)/6\$</span>", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$L(\\alpha)(\\delta \\theta)/4\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "\$–L(\\alpha)(\\delta \\theta)/4", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "Using thermal expansion and center of mass shift, the x-coordinate = <span class=\"latex\">\$-L\\alpha\\Delta\\theta/6\$</span>.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 3,
          "passage": null
        },
        {
          "questionId": "6ca0c7cf-bb0b-4ff5-8751-df7260ffdc1e",
          "sectionId": "sec_biology",
          "answerRaw": null,
          "correctAnswer": "A",
          "isCorrect": false,
          "isSkipped": true,
          "marksAwarded": 0,
          "timeTaken": 15000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "easy",
          "questionHtml": "",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$3\$</span>", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$4\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$5\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$None \\, of\\, these \$</span>", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": null,
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 4,
          "passage": null
        },
        {
          "questionId": "6de9b3e5-3129-45b8-bef3-ec60a7de9de0",
          "sectionId": "sec_biology",
          "answerRaw": "A",
          "correctAnswer": "A",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 198000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "medium",
          "questionHtml": "The correct order of oxidising power is",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$VO_2^+ < Cr_2O_7^{2-} < MnO_4^-\$</span>", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$Cr_2O_7^{2-} < MnO_4^- < VO_2^+\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$MnO_4^- < VO_2^+ < Cr_2O_7^{2-}\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$VO_2^+ < MnO_4^- < Cr_2O_7^{2-}\$</span>", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "The correct order of oxidising power based on standard reduction potentials is <span class=\"latex\">\$VO_2^+ < Cr_2O_7^{2-} < MnO_4^-\$</span>.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 5,
          "passage": null
        },
        {
          "questionId": "000cb18c-4a8f-4a65-bd45-fcb6fe7c5863",
          "sectionId": "sec_biology",
          "answerRaw": "C",
          "correctAnswer": "A",
          "isCorrect": false,
          "isSkipped": false,
          "marksAwarded": -1,
          "timeTaken": 310000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "integer",
          "difficulty": "easy",
          "questionHtml": "Let <span class=\"latex\">\$Z\$</span> be set of integers. If <span class=\"latex\">\$A = \\{x\\, \\in \\, Z : |x – 3|^{(x^2 – 3x + 6)} = 1\\} \\,\\, and \\,\\, B = \\{x\\,\\in\\,Z : 10 < 3x + 1 < 22\\},\$</span> then the number of subsets of the set <span class=\"latex\">\$A \\times B\$</span> is",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$2^9\$</span>", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$2^8\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$2^6\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$2^{15}\$</span>", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "The answer is <span class=\"latex\">\$2^9\$</span> = 512 subsets.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 6,
          "passage": null
        },
        {
          "questionId": "93ead6a7-48c1-4f4b-89a4-b3e5a3a8df1c",
          "sectionId": "sec_biology",
          "answerRaw": "C",
          "correctAnswer": "C",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 285000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "easy",
          "questionHtml": "Given below are two statements: One is labelled as Assertion (A) and the other is labelled as Reason (R). <br /> Assertion (A): In acidic medium, iodide ion is converted to iodine in presence of <span class=\"latex\">\$K_2Cr_2O_7\$</span>. <br /> Reason (R): <span class=\"latex\">\$K_2Cr_2O_7\$</span> acts as oxidising agent in acidic medium.",
          "questionOptions": [
            {"key": "A", "textHtml": "(A) is true but (R) is false.", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "B", "textHtml": "Both (A) and (R) are true but (R) is not the correct explanation of (A)", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "Both (A) and (R) are true and (R) is the correct explanation of (A)", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "D", "textHtml": "(A) is false but (R) is true", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "Both assertion and reason are true, and the reason correctly explains why iodide is oxidized to iodine by K₂Cr₂O₇ in acidic medium.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 7,
          "passage": null
        },
        {
          "questionId": "95e61b77-6005-4383-9dbd-808fc84b4ce1",
          "sectionId": "sec_biology",
          "answerRaw": "D",
          "correctAnswer": "B",
          "isCorrect": false,
          "isSkipped": false,
          "marksAwarded": -1,
          "timeTaken": 156000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "hard",
          "questionHtml": "Consider the following reaction of lanthanoids. 'X' and 'Y' respectively are",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$LnS \\,\\,and\\,\\, LnN\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$Ln_2S_3\\,\\, and \\,\\, LnN\$</span>", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$LnS_2\\,\\, and \\,\\, Ln_3N_2\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$Ln_2S_3\\,\\, and \\,\\, Ln_3N_2\$</span>", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "Lanthanoids form Ln₂S₃ with sulphur and LnN with nitrogen in +3 oxidation state.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 8,
          "passage": null
        },
        {
          "questionId": "9ddde480-2d91-4089-a0b0-583304faeba7",
          "sectionId": "sec_biology",
          "answerRaw": "D",
          "correctAnswer": "D",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 220000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "easy",
          "questionHtml": "The domain of function <span class=\"latex\">\$f(x) = log_{\\left[x + \\dfrac{1}{2}\\right]}(2x^2 + x – 1)\$</span>, where [.] denotes the greatest integer function is:",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$\\left(\\dfrac{3}{2}, \\infty \\right)\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$(2, \\infty)\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$\\left(-\\dfrac{1}{2}, \\infty\\right) - \\left\\{\\dfrac{1}{2}\\right\\}\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$\\left(\\dfrac{1}{2}, 1\\right) \\cup (1, \\infty)\$</span>", "images": [], "isCorrect": true, "partialMark": 0}
          ],
          "solutionHtml": "For the log to be defined, base > 0, base ≠ 1, and argument > 0. Solving these constraints gives the domain <span class=\"latex\">\$(1/2, 1) \\cup (1, \\infty)\$</span>.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 9,
          "passage": null
        },
        {
          "questionId": "ad07e84f-a2f2-4728-8d76-4a3d754763fa",
          "sectionId": "sec_biology",
          "answerRaw": "A",
          "correctAnswer": "A",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 420000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "short_answer",
          "difficulty": "medium",
          "questionHtml": "<span class=\"latex\">\$\\dfrac{3}{25}\$</span> moles of an ideal monatomic gas undergoes a process as shown in figure. Choose the correct matching.",
          "questionOptions": [
            {"key": "A", "textHtml": "A – P, R, S, B – P, Q, S, C – Q, D – Q", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "A – S, P, S, B – P, R, S, C – S, D – P", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "A – P, Q, S, B – P, S, S, C – R, D – S", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "A – P, R, S, B – P, Q, S, C – Q, D – Q", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "Analyzing each process in the PV diagram with thermodynamic relations for monatomic ideal gas gives the correct matching A – P, R, S.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 10,
          "passage": null
        },
        {
          "questionId": "e2528b8a-df80-4bb8-9749-8bb811644ce2",
          "sectionId": "sec_biology",
          "answerRaw": "A",
          "correctAnswer": "A",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 188000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "easy",
          "questionHtml": "The electronic configuration of Eu (Z = 63) and Gd (Z = 64) respectively are",
          "questionOptions": [
            {"key": "A", "textHtml": "<span class=\"latex\">\$[Xe] 4f^7\\,6s^2\\,\\, and \\,\\, [Xe] \\, 4f^7 5d^1 6s^2\$</span>", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "<span class=\"latex\">\$[Xe] 4f^6 5d^1 6s^2\\,\\, and \\,\\, [Xe] 4f^7 5d^2 6s^1\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "<span class=\"latex\">\$[Xe]4f^8 6s^1\\,\\, and \\,\\, [Xe] 4f^6 5d^2 6s^2\$</span>", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "<span class=\"latex\">\$[Xe] 4f^7 6s^2 \\,\\, and \\,\\, [Xe] 4f^6 5d^2 6s^2\$</span>", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": "Eu has half-filled 4f⁷ configuration for stability, and Gd has 4f⁷5d¹6s² due to the extra stability of the half-filled f orbital.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 11,
          "passage": null
        },
        {
          "questionId": "e3a7f869-16a8-4f0b-86c1-5edd0088c1b5",
          "sectionId": "sec_biology",
          "answerRaw": null,
          "correctAnswer": "2",
          "isCorrect": false,
          "isSkipped": true,
          "marksAwarded": 0,
          "timeTaken": 8000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "integer",
          "difficulty": "easy",
          "questionHtml": "<span class=\"latex\">\$\\alpha \\,\\, and \\beta\$</span> are the positive acute angles satisfying simultaneously the equations <span class=\"latex\">\$5\\, sin\\, 2\\beta = 3 \\, sin\\, 2\\alpha \\,\\, and \\,\\, tan\\, \\beta = 3 tan\\, \\alpha,\$</span> Find the value of <span class=\"latex\">\$tan\\,\\alpha + tan\\, \\beta\$</span>.",
          "questionOptions": [],
          "solutionHtml": "From the given equations, solving simultaneously gives tan α + tan β = 2.",
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 12,
          "passage": null
        },
        {
          "questionId": "acfea640-8d50-484f-9fdd-954d01dfb469",
          "sectionId": "sec_botany",
          "answerRaw": "A",
          "correctAnswer": "A",
          "isCorrect": true,
          "isSkipped": false,
          "marksAwarded": 4,
          "timeTaken": 45000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "medium",
          "questionHtml": "Mojan",
          "questionOptions": [
            {"key": "A", "textHtml": "gfg", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "fg", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "gfg", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "gfg", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": null,
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 13,
          "passage": null
        },
        {
          "questionId": "que1",
          "sectionId": "sec_botany",
          "answerRaw": "C",
          "correctAnswer": "A",
          "isCorrect": false,
          "isSkipped": false,
          "marksAwarded": -1,
          "timeTaken": 62000,
          "positiveMarks": 4,
          "negativeMarks": 1,
          "hasPartialMarking": false,
          "questionType": "mcq_single",
          "difficulty": "medium",
          "questionHtml": "fgfg",
          "questionOptions": [
            {"key": "A", "textHtml": "1", "images": [], "isCorrect": true, "partialMark": 0},
            {"key": "B", "textHtml": "23", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "C", "textHtml": "3", "images": [], "isCorrect": false, "partialMark": 0},
            {"key": "D", "textHtml": "4", "images": [], "isCorrect": false, "partialMark": 0}
          ],
          "solutionHtml": null,
          "numericMin": null,
          "numericMax": null,
          "sortOrder": 14,
          "passage": null
        }
      ]
    }
  };

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      examInfo.value = args;
    }
    _loadResult();
  }

  void _loadResult() {
    // Using static data for now; will be replaced with API call later
    final raw = Map<String, dynamic>.from(_staticResult['data'] as Map);
    // Process LaTeX in all answer HTML fields
    final answers = (raw['answers'] as List?)?.map((a) {
      final answer = Map<String, dynamic>.from(a as Map);
      if (answer['questionHtml'] != null) {
        answer['questionHtml'] = _stripLatexSpans(answer['questionHtml'] as String);
      }
      if (answer['solutionHtml'] != null) {
        answer['solutionHtml'] = _stripLatexSpans(answer['solutionHtml'] as String);
      }
      if (answer['questionOptions'] != null) {
        answer['questionOptions'] = (answer['questionOptions'] as List).map((opt) {
          final option = Map<String, dynamic>.from(opt as Map);
          if (option['textHtml'] != null) {
            option['textHtml'] = _stripLatexSpans(option['textHtml'] as String);
          }
          return option;
        }).toList();
      }
      return answer;
    }).toList();
    if (answers != null) raw['answers'] = answers;
    resultData.value = raw;
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

  // ── Computed getters ──────────────────────────────────────────────────────

  Map<String, dynamic> get data => resultData.value ?? {};

  int get obtainedMarks => data['obtainedMarks'] ?? 0;
  int get totalMarks => data['totalMarks'] ?? 0;
  int get rank => data['rank'] ?? 0;
  num get percentile => data['percentile'] ?? 0;
  int get timeTakenMs => data['timeTaken'] ?? 0;

  List<Map<String, dynamic>> get sectionResults {
    final list = data['sectionResults'];
    if (list == null) return [];
    return List<Map<String, dynamic>>.from(list);
  }

  List<Map<String, dynamic>> get answers {
    final list = data['answers'];
    if (list == null) return [];
    return List<Map<String, dynamic>>.from(list);
  }

  // ── Statistics ─────────────────────────────────────────────────────────────

  Map<String, dynamic> getOverallStats() {
    int total = 0, correct = 0, wrong = 0, skipped = 0;
    for (var section in sectionResults) {
      total += (section['totalQuestions'] as int?) ?? 0;
      correct += (section['correctCount'] as int?) ?? 0;
      wrong += (section['wrongCount'] as int?) ?? 0;
      skipped += (section['skippedCount'] as int?) ?? 0;
    }
    final percentage = total > 0 ? (correct / total * 100) : 0.0;
    return {
      'total': total,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'percentage': percentage,
    };
  }

  // Section-wise report for performance table
  List<Map<String, dynamic>> getSectionReport() {
    return sectionResults.map((section) {
      final totalQ = (section['totalQuestions'] as int?) ?? 0;
      final correct = (section['correctCount'] as int?) ?? 0;
      final wrong = (section['wrongCount'] as int?) ?? 0;
      final skipped = (section['skippedCount'] as int?) ?? 0;
      final obtained = (section['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
      final sectionTotal = (section['totalMarks'] as num?)?.toDouble() ?? 0.0;
      final timeTaken = (section['timeTaken'] as int?) ?? 0;
      final answered = (section['answeredCount'] as int?) ?? 0;
      final percentage = totalQ > 0 ? (correct / totalQ * 100) : 0.0;
      final accuracy = answered > 0 ? (correct / answered * 100) : 0.0;
      final avgTime = totalQ > 0 ? (timeTaken / totalQ) : 0.0;

      return {
        'sectionId': section['sectionId'],
        'sectionName': section['sectionName'] ?? section['sectionId'],
        'totalQuestions': totalQ,
        'correct': correct,
        'wrong': wrong,
        'skipped': skipped,
        'obtainedMarks': obtained,
        'totalMarks': sectionTotal,
        'timeTakenMs': timeTaken,
        'percentage': percentage,
        'accuracy': accuracy,
        'avgTimeMs': avgTime,
      };
    }).toList();
  }

  // Performance Report 1 — section-wise with +ve/-ve marks (computed from answers)
  Map<String, dynamic> getPerformanceReport() {
    // Group answers by sectionId
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var a in answers) {
      final sid = a['sectionId'] ?? '';
      grouped.putIfAbsent(sid, () => []);
      grouped[sid]!.add(a);
    }

    double grandPositive = 0, grandNegative = 0, grandTotal = 0, grandObtained = 0;
    int grandCorrect = 0, grandWrong = 0;

    final subjects = sectionResults.map((section) {
      final sId = section['sectionId'] ?? '';
      final name = section['sectionName'] ?? sId;
      final sectionAnswers = grouped[sId] ?? [];

      double positiveMarks = 0, negativeMarks = 0, totalMarks = 0;
      int correct = 0, wrong = 0;

      for (var a in sectionAnswers) {
        final posM = (a['positiveMarks'] as num?)?.toDouble() ?? 4.0;
        final negM = (a['negativeMarks'] as num?)?.toDouble() ?? 1.0;
        totalMarks += posM;

        if (a['isSkipped'] == true) continue;
        if (a['isCorrect'] == true) {
          correct++;
          positiveMarks += posM;
        } else {
          wrong++;
          negativeMarks += negM;
        }
      }

      // If no answers in section, calculate totalMarks from section metadata
      if (sectionAnswers.isEmpty) {
        totalMarks = (section['totalMarks'] as num?)?.toDouble() ?? 0.0;
      }

      final totalScore = positiveMarks - negativeMarks;

      grandPositive += positiveMarks;
      grandNegative += negativeMarks;
      grandTotal += totalMarks;
      grandObtained += totalScore;
      grandCorrect += correct;
      grandWrong += wrong;

      return {
        'subjectName': name,
        'correct': correct,
        'wrong': wrong,
        'skipped': (section['skippedCount'] as int?) ?? 0,
        'totalMarks': totalMarks,
        'positiveMarks': positiveMarks,
        'negativeMarks': negativeMarks,
        'totalScore': totalScore,
      };
    }).toList();

    return {
      'subjects': subjects,
      'totalQuestions': answers.length,
      'totalMarks': grandTotal,
      'correct': grandCorrect,
      'wrong': grandWrong,
      'positiveMarks': grandPositive,
      'negativeMarks': grandNegative,
      'totalScore': grandObtained,
    };
  }

  // ── Section tab helpers ─────────────────────────────────────────────────────

  List<String> get sectionNames {
    return sectionResults
        .map((s) => (s['sectionName'] ?? s['sectionId'] ?? '') as String)
        .toList();
  }

  String? get selectedSectionId {
    if (selectedSectionIndex.value < sectionResults.length) {
      return sectionResults[selectedSectionIndex.value]['sectionId'] as String?;
    }
    return null;
  }

  List<Map<String, dynamic>> get filteredAnswers {
    final sId = selectedSectionId;
    if (sId == null) return answers;
    return answers.where((a) => a['sectionId'] == sId).toList();
  }

  void selectSection(int index) {
    selectedSectionIndex.value = index;
    expandedSolutions.clear();
  }

  void toggleSolution(int index) {
    if (expandedSolutions.contains(index)) {
      expandedSolutions.remove(index);
    } else {
      expandedSolutions.add(index);
    }
  }

  bool isSolutionExpanded(int index) => expandedSolutions.contains(index);

  // ── Question helpers ───────────────────────────────────────────────────────

  Map<String, dynamic> getAnswer(int index) {
    if (index < 0 || index >= answers.length) return {};
    return answers[index];
  }

  Map<String, dynamic> get currentReviewAnswer => getAnswer(reviewIndex.value);

  void goToReviewQuestion(int index) {
    if (index >= 0 && index < answers.length) {
      reviewIndex.value = index;
    }
  }

  String getQuestionTypeName(String type) {
    switch (type) {
      case 'mcq_single':
        return 'MCQ Single';
      case 'mcq_multiple':
        return 'MCQ Multiple';
      case 'numeric':
      case 'integer':
      case 'numerical':
        return 'Numerical';
      case 'text':
        return 'Short Answer';
      case 'subjective':
        return 'Subjective';
      case 'true_false':
        return 'True/False';
      case 'match':
        return 'Match';
      default:
        return type.replaceAll('_', ' ').capitalizeFirst ?? type;
    }
  }

  String getUserAnswerDisplay(Map<String, dynamic> answer) {
    if (answer['isSkipped'] == true) return 'Skipped';
    final raw = answer['answerRaw'];
    if (raw == null) return 'Not Answered';
    return raw.toString();
  }

  String formatDuration(int ms) {
    if (ms <= 0) return '0s';
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String getSectionName(String sectionId) {
    for (var section in sectionResults) {
      if (section['sectionId'] == sectionId) {
        return section['sectionName'] ?? sectionId;
      }
    }
    return sectionId;
  }
}
