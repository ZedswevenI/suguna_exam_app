import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/test_player/controllers/test_player_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/test_player_parser.dart';

class QuestionOptionsWidget extends StatelessWidget {
  const QuestionOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return GetBuilder<TestPlayerController>(builder: (controller){
      return Obx(() {
        final question = controller.currentQuestion;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question ${question.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildQuestionWidget(question,controller),
            ],
          ),
        );
      });
    });
  }


  Widget _buildQuestionWidget(Question question,TestPlayerController controller) {
    switch (question.type) {
      case QuestionType.mcqSingle:
        return _buildMCQSingle(question,controller);
      case QuestionType.mcqMultiple:
        return _buildMCQMultiple(question,controller);
      case QuestionType.matchTheFollowing:
        return _buildMAQ(question,controller);
      case QuestionType.integer:
      case QuestionType.numerical:
        return _buildNumerical(question,controller);
      case QuestionType.trueFalse:
        return _buildTrueFalse(question,controller);
      case QuestionType.singleDropdown:
        return _buildSingleDropdown(question);
      case QuestionType.multiDropdown:
        return _buildMultiDropdown(question);
      case QuestionType.textType:
        return _buildTextType(question);
      case QuestionType.subjective:
        return _buildSubjective(question,controller);
      }
  }

  // MCQ - Single Answer
  Widget _buildMCQSingle(Question question,TestPlayerController controller) {
    return TeXView(style: const TeXViewStyle(
      backgroundColor: Colors.transparent, padding: TeXViewPadding.all(0),),
      child: TeXViewColumn(children: [
        TeXViewDocument(_effectiveHtml(question, controller), style: TeXViewStyle.fromCSS(
          'font-size:${controller
              .getQuestionFontSize()}px; margin-bottom:16px;',),),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final label = String.fromCharCode(65 + index); // A, B, C, D
          final isSelected = question.selectedAnswer == label;
          return TeXViewInkWell(
            id: 'option_$index',
            onTap: (_) => controller.selectAnswer(label),
            child: TeXViewDocument(
              '''
      <div style="display:flex; align-items:flex-start; gap:12px;">
        
        <!-- LABEL CIRCLE -->
        <div style="
          width:24px;
          height:24px;
          border-radius:50%;
          font-size:10px;
          font-weight:700;
          text-align:center;
          line-height:24px;
          color:${isSelected ? '#ffffff' : '#374151'};
          background-color:${isSelected ? '#2563eb' : '#d1d5db'};
          flex-shrink:0;
        ">$label</div>

        <!-- OPTION TEXT -->
        <div style="
          flex:1;
          font-size:${controller.getOptionFontSize()}px;
          font-weight:${isSelected ? '600' : '500'};
        ">
          $option
        </div>

      </div>
      ''',
              style: TeXViewStyle.fromCSS(
                  '''
        padding:12px;
        margin-bottom:8px;
        border-radius:8px;
        cursor:pointer;
        border:${isSelected ? '2px solid #2563eb' : '1px solid #e5e7eb'};
        background-color:${isSelected ? '#eff6ff' : 'transparent'};
        transition: all 0.2s ease;
        '''
              ),
            ),
          );
        }),
      ],),);
    // :  Column(
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   children: question.options
    //       .map((option) => _buildOption(
    //     controller: controller,
    //     label: String.fromCharCode(65 + question.options.indexOf(option)),
    //     text: option,
    //     isSelected: question.selectedAnswer == option,
    //     onTap: () => controller.selectAnswer(option),
    //   )).toList(),
    // );
  }


  // MCQ - Multiple Answer
  Widget _buildMCQMultiple(Question question, TestPlayerController controller) {
    return TeXView(
      style: const TeXViewStyle(
        backgroundColor: Colors.transparent,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewColumn(
        children: [
          TeXViewDocument(
            _effectiveHtml(question, controller),
            style: TeXViewStyle.fromCSS(
              'font-size:${controller.getQuestionFontSize()}px; margin-bottom:16px;',
            ),
          ),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final label = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = question.selectedAnswers?.contains(label) ?? false;

            return TeXViewInkWell(
              id: 'multi_$index',
              onTap: (_) => controller.selectAnswer(label),
              child: TeXViewDocument(
                '''
<div style="display:flex; align-items:flex-start; gap:12px;">
  <div style="
    width:24px; height:24px; border-radius:6px;
    font-size:10px; font-weight:700; flex-shrink:0;
    text-align:center; line-height:24px;
    color:${isSelected ? '#ffffff' : '#374151'};
    background-color:${isSelected ? '#2563eb' : '#d1d5db'};
  ">$label</div>
  <div style="flex:1; font-size:${controller.getOptionFontSize()}px; font-weight:${isSelected ? '600' : '500'};">
    $option
  </div>
  <div style="font-size:18px;">${isSelected ? '☑' : '☐'}</div>
</div>
''',
                style: TeXViewStyle.fromCSS(
                  '''
padding:12px; margin-bottom:8px; border-radius:8px; cursor:pointer;
border:${isSelected ? '2px solid #2563eb' : '1px solid #e5e7eb'};
background-color:${isSelected ? '#eff6ff' : 'transparent'};
''',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMAQ(
      Question question,
      TestPlayerController controller,
      ) {
    final pairs = question.matchPairs;
    if (pairs == null || pairs.isEmpty) {
      return const Text('No match data available for this question.');
    }

    final rightOptions = pairs.first.rightOptions;
    final rightTexts = pairs.first.rightTexts;

    // Build all children for TeXViewColumn
    final List<TeXViewWidget> children = [];

    // 1. Question HTML (contains LaTeX) — includes passage if present
    children.add(TeXViewDocument(
      _effectiveHtml(question, controller),
      style: TeXViewStyle.fromCSS(
        'font-size:${controller.getQuestionFontSize()}px; margin-bottom:16px;',
      ),
    ));

    // 2. Instruction
    children.add(TeXViewDocument(
      '''
      <div style="
        padding:10px; margin-bottom:12px;
        background-color:rgba(79,70,229,0.1); border-radius:8px;
        font-size:13px; font-weight:600; color:#4F46E5;
      ">↔ Match each item on left to right</div>
      ''',
    ));

    // 3. For each left item: label row + right option chips
    for (final pair in pairs) {
      final selectedRights = question.matchAnswers?[pair.left];

      // Left label + text
      final leftTextHtml = pair.leftText.isNotEmpty
          ? '<span style="margin-left:10px; font-size:${controller.getOptionFontSize() - 1}px; font-weight:500; color:#1f2937;">${pair.leftText}</span>'
          : '';

      children.add(TeXViewDocument(
        '''
        <div style="
          padding:8px 12px; margin-top:8px;
          background-color:#f3f4f6; border-radius:8px 8px 0 0;
          border:1px solid #d1d5db; border-bottom:none;
          display:flex; align-items:center;
        ">
          <span style="
            display:inline-block; padding:4px 12px;
            background-color:rgba(79,70,229,0.15); border-radius:8px;
            font-size:${controller.getOptionFontSize()}px;
            font-weight:700; color:#4F46E5;
          ">${pair.left}</span>
          $leftTextHtml
        </div>
        ''',
      ));

      // Right option chips — each is its own TeXViewInkWell
      for (int idx = 0; idx < rightOptions.length; idx++) {
        final rightLabel = rightOptions[idx];
        final rightText = idx < rightTexts.length ? rightTexts[idx] : '';
        final isSelected = selectedRights?.contains(rightLabel) ?? false;
        final bgColor = isSelected ? '#4F46E5' : '#f9fafb';
        final textColor = isSelected ? '#ffffff' : '#1f2937';
        final borderColor = isSelected ? '#4F46E5' : '#d1d5db';
        final isLast = idx == rightOptions.length - 1;
        final displayText = rightText.isNotEmpty
            ? '$rightLabel : $rightText'
            : rightLabel;

        children.add(TeXViewInkWell(
          id: 'match_${pair.left}_$rightLabel',
          onTap: (id) {
            final parts = id.split('_');
            if (parts.length >= 3) {
              controller.selectMatch(parts[1], parts[2]);
            }
          },
          child: TeXViewDocument(
            '''
            <div style="
              padding:10px 14px;
              background-color:$bgColor;
              border-left:1px solid #d1d5db;
              border-right:1px solid #d1d5db;
              border-bottom:1px solid $borderColor;
              ${isLast ? 'border-radius:0 0 8px 8px; margin-bottom:4px;' : ''}
              cursor:pointer;
              display:flex; align-items:center; gap:10px;
            ">
              <span style="
                display:inline-flex; align-items:center; justify-content:center;
                width:26px; height:26px; border-radius:50%;
                background-color:${isSelected ? '#ffffff33' : '#e5e7eb'};
                color:$textColor; font-size:12px; font-weight:700;
                flex-shrink:0;
              ">$rightLabel</span>
              ${rightText.isNotEmpty ? '<span style="font-size:${controller.getOptionFontSize() - 1}px; font-weight:${isSelected ? '600' : '500'}; color:$textColor;">$rightText</span>' : ''}
            </div>
            ''',
          ),
        ));
      }
    }

    return TeXView(
      style: const TeXViewStyle(
        backgroundColor: Colors.transparent,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewColumn(children: children),
    );
  }


  // Numerical Answer
  Widget _buildNumerical(Question question,TestPlayerController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeXView(child:  TeXViewColumn(
            children: [
              TeXViewDocument(_effectiveHtml(question, controller), style: TeXViewStyle.fromCSS(
                'font-size:${controller
                    .getQuestionFontSize()}px; margin-bottom:16px;',),),
              // TeXViewDocument("Enter numerical value${question.minRange != null ? " (Range: ${question.minRange} - ${question.maxRange})" : ""}", style: TeXViewStyle.fromCSS(
              //   'font-size:${controller
              //       .getQuestionFontSize()}px; margin-bottom:16px;',),),
            ]
        ),
        // controller.isLatex(_effectiveHtml(question, controller)) ? TeXView(child:  TeXViewColumn(
        //     children: [
        //       TeXViewDocument(_effectiveHtml(question, controller), style: TeXViewStyle.fromCSS(
        //         'font-size:${controller
        //             .getQuestionFontSize()}px; margin-bottom:16px;',),),
        //       // TeXViewDocument("Enter numerical value${question.minRange != null ? " (Range: ${question.minRange} - ${question.maxRange})" : ""}", style: TeXViewStyle.fromCSS(
        //       //   'font-size:${controller
        //       //       .getQuestionFontSize()}px; margin-bottom:16px;',),),
        //     ]
        // ),) : Column(
        //   children: [
        //
        //     Text(
        //       _effectiveHtml(question, controller),
        //       style: TextStyle(
        //         fontSize: controller.getQuestionFontSize(),
        //         height: 1.6,
        //         color: AppColors.textPrimary,
        //         fontWeight: FontWeight.w500,
        //       ),
        //     ),
        //     SizedBox(height: 20,),
        //     // Text(
        //     //   'Enter numerical value${question.minRange != null ? " (Range: ${question.minRange} - ${question.maxRange})" : ""}',
        //     //   style: const TextStyle(
        //     //     fontSize: 12,
        //     //     fontWeight: FontWeight.w600,
        //     //     color: Color(0xFF10B981),
        //     //   ),
        //     // ),
        //   ],
        ),
        GetBuilder<TestPlayerController>(
          builder: (controller) {
            final isInteger = question.isInteger;
            return TextField(
              controller: controller.numericalController,
              keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
              inputFormatters: isInteger
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : [_SingleDecimalFormatter()],
              decoration: InputDecoration(
                hintText: isInteger
                    ? 'Enter integer answer'
                    : 'Enter your answer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(20),
              ),
              style: TextStyle(
                fontSize: controller.getOptionFontSize(),
                fontWeight: FontWeight.w600,
              ),
              onChanged: (value) {
                final num = double.tryParse(value);
                if (num != null) {
                  controller.setNumericalAnswer(num);
                }
              },
            );
          },
        ),
      ],
    );
  }

  // True/False
  Widget _buildTrueFalse(Question question, TestPlayerController controller) {
    Widget buildOption(String option) {
      final isTrue = option.toLowerCase() == 'true';
      final isSelected = question.selectedAnswer == option;
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: isTrue ? 12 : 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.selectAnswer(option),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isTrue ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 48,
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Text(
                      option,
                      style: TextStyle(
                        fontSize: controller.getOptionFontSize() + 2,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeXView(
          style: const TeXViewStyle(
            backgroundColor: Colors.transparent,
            padding: TeXViewPadding.all(0),
          ),
          child: TeXViewDocument(
            _effectiveHtml(question, controller),
            style: TeXViewStyle.fromCSS(
              'font-size:${controller.getQuestionFontSize()}px; margin-bottom:16px;',
            ),
          ),
        ),
        Row(
          children: [
            buildOption('True'),
            buildOption('False'),
          ],
        ),
      ],
    );
  }

  // Single Dropdown
  Widget _buildSingleDropdown(Question question) {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: question.selectedAnswer,
            decoration: const InputDecoration(
              labelText: 'Select your answer',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: question.options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Obx(() => Text(
                  option,
                  style: TextStyle(fontSize: controller.getOptionFontSize()),
                )),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectAnswer(value);
              }
            },
          ),
        );
      },
    );
  }

  // Multi Dropdown
  Widget _buildMultiDropdown(Question question) {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.checklist_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Select multiple options from dropdown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            ...question.options.map((option) {
              final isSelected = question.selectedAnswers?.contains(option) ?? false;
              return CheckboxListTile(
                title: Obx(() => Text(
                  option,
                  style: TextStyle(fontSize: controller.getOptionFontSize()),
                )),
                value: isSelected,
                onChanged: (value) => controller.selectAnswer(option),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              );
            }),
          ],
        );
      },
    );
  }

  // Text Type
  Widget _buildTextType(Question question) {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            controller.isLatex(_effectiveHtml(question, controller)) ? TeXView(
              child:  TeXViewColumn(
                children: [
                  TeXViewDocument(_effectiveHtml(question, controller), style: TeXViewStyle.fromCSS(
                    'font-size:${controller
                        .getQuestionFontSize()}px; margin-bottom:16px;',),),
                  // TeXViewDocument("Enter numerical value${question.minRange != null ? " (Range: ${question.minRange} - ${question.maxRange})" : ""}", style: TeXViewStyle.fromCSS(
                  //   'font-size:${controller
                  //       .getQuestionFontSize()}px; margin-bottom:16px;',),),
                ]
            ),) : Column(
              children: [
                Text(
                  _effectiveHtml(question, controller),
                  style: TextStyle(
                    fontSize: controller.getQuestionFontSize(),
                    height: 1.6,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Text(
                //   'Enter numerical value${question.minRange != null ? " (Range: ${question.minRange} - ${question.maxRange})" : ""}',
                //   style: const TextStyle(
                //     fontSize: 12,
                //     fontWeight: FontWeight.w600,
                //     color: Color(0xFF10B981),
                //   ),
                // ),
              ],
            ),
            GetBuilder<TestPlayerController>(
              builder: (controller) {
                return TextField(
                  controller: controller.numericalController,  // 👈 important
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Enter your answer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: TextStyle(
                    fontSize: controller.getOptionFontSize(),
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) {
                    // final num = double.tryParse(value);
                    controller.setTextAnswer(value);
                  },
                );
              },
            ),
          ],
        );
        return TextField(
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(20),
          ),
          style: TextStyle(
            fontSize: controller.getOptionFontSize(),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (value) => controller.setTextAnswer(value),
        );
      },
    );
  }

  // Subjective
  Widget _buildSubjective(Question question,TestPlayerController controller) {
    return GetBuilder<TestPlayerController>(
      id: 'question',
      builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TeXView(
              style: const TeXViewStyle(
                backgroundColor: Colors.transparent,
                padding: TeXViewPadding.all(0),
              ),
              child: TeXViewDocument(
                _effectiveHtml(question, controller),
                style: TeXViewStyle.fromCSS(
                  'font-size:${controller.getQuestionFontSize()}px; margin-bottom:16px;',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.edit_note_rounded, color: Color(0xFF8B5CF6), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Write detailed answer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: controller.numericalController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(20),
              ),
              style: TextStyle(
                fontSize: controller.getOptionFontSize(),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              onChanged: (value) => controller.setTextAnswer(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption({
    required String label,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required TestPlayerController controller
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => Text(
                    text,
                    style: TextStyle(
                      fontSize: controller.getOptionFontSize(),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  )),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget texText(
      String text, {
        required double fontSize,
        String extraCss = '',
      }) {
    return TeXView(
      style: const TeXViewStyle(
        backgroundColor: Colors.transparent,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewColumn(
        children: [
          TeXViewDocument(
            text,
            style: TeXViewStyle.fromCSS(
              '''
            font-size:${fontSize}px;
            $extraCss
            ''',
            ),
          ),
        ],
      ),
    );
  }



  /// Combines passage (if any) + question HTML into a single HTML string
  /// so both render inside one TeXView and avoid the Android double-WebView crash.
  String _effectiveHtml(Question question, TestPlayerController controller) {
    final qHtml = question.questionHtml ?? '';
    final passage = question.passageHtml;
    if (passage == null || passage.isEmpty) return qHtml;
    final fs = controller.getQuestionFontSize();
    return '''
<div style="
  background:#f0f4ff;
  border-left:4px solid #4F46E5;
  border-radius:8px;
  padding:12px 14px;
  margin-bottom:16px;
  font-size:${fs}px;
  line-height:1.7;
  color:#1e293b;
  width:100%;
  box-sizing:border-box;
  word-wrap:break-word;
  overflow-wrap:break-word;
  white-space:normal;
">
  <div style="font-size:11px;font-weight:700;color:#4F46E5;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px;">Passage</div>
  <div style="word-wrap:break-word;overflow-wrap:break-word;white-space:normal;">$passage</div>
</div>
$qHtml''';
  }

}

class _SingleDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if ('.'.allMatches(text).length > 1) return oldValue;
    return newValue;
  }
}