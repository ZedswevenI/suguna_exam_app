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
  Widget _buildMCQSingle(Question question, TestPlayerController controller) {
    return TeXView(
      loadingWidgetBuilder: (_) => const SizedBox.shrink(),
      style: const TeXViewStyle(
        backgroundColor: Colors.white,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewColumn(children: [
        TeXViewDocument(
          _effectiveHtml(question, controller),
          style: TeXViewStyle.fromCSS(
            'font-size:${controller.getQuestionFontSize()}px; margin-bottom:16px;',
          ),
        ),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final label = String.fromCharCode(65 + index);
          final isSelected = question.selectedAnswer == label;
          return TeXViewInkWell(
            id: 'option_$index',
            onTap: (_) => controller.selectAnswer(label),
            child: TeXViewDocument(
              '''
<style>
  html, body {
    background: #ffffff !important;
    -webkit-tap-highlight-color: transparent !important;
  }
  *, *:active, *:focus, *:hover {
    -webkit-tap-highlight-color: transparent !important;
    outline: none !important;
    user-select: none !important;
    -webkit-touch-callout: none !important;
  }
</style>
<div style="display:flex; align-items:flex-start; gap:12px; -webkit-tap-highlight-color:transparent;">
  <div style="
    width:24px; height:24px; border-radius:50%;
    font-size:10px; font-weight:700; text-align:center; line-height:24px;
    color:${isSelected ? '#ffffff' : '#374151'};
    background-color:${isSelected ? '#2563eb' : '#d1d5db'};
    flex-shrink:0; -webkit-tap-highlight-color:transparent;
  ">$label</div>
  <div style="flex:1; font-size:${controller.getOptionFontSize()}px; font-weight:${isSelected ? '600' : '500'}; -webkit-tap-highlight-color:transparent;">
    $option
  </div>
</div>
              ''',
              style: TeXViewStyle.fromCSS('''
padding:12px; margin-bottom:8px; border-radius:8px; cursor:pointer;
-webkit-tap-highlight-color: transparent;
border:${isSelected ? '2px solid #2563eb' : '1px solid #e5e7eb'};
background-color:${isSelected ? '#eff6ff' : 'transparent'};
transition: all 0.2s ease;
              '''),
            ),
          );
        }),
      ]),
    );
  }


  // MCQ - Multiple Answer
  Widget _buildMCQMultiple(Question question, TestPlayerController controller) {
    return TeXView(
      loadingWidgetBuilder: (_) => const SizedBox.shrink(),
      style: const TeXViewStyle(
        backgroundColor: Colors.white,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewColumn(children: [
        TeXViewDocument(
          _effectiveHtml(question, controller),
          style: TeXViewStyle.fromCSS(
            'font-size:${controller.getQuestionFontSize()}px; margin-bottom:16px;',
          ),
        ),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final label = String.fromCharCode(65 + index);
          final isSelected =
              question.selectedAnswers?.contains(label) ?? false;
          return TeXViewInkWell(
            id: 'multi_$index',
            onTap: (_) => controller.selectAnswer(label),
            child: TeXViewDocument(
              '''
<style>
  html, body {
    background: #ffffff !important;
    -webkit-tap-highlight-color: transparent !important;
  }
  *, *:active, *:focus, *:hover {
    -webkit-tap-highlight-color: transparent !important;
    outline: none !important;
    user-select: none !important;
    -webkit-touch-callout: none !important;
  }
</style>
<div style="display:flex; align-items:flex-start; gap:12px; -webkit-tap-highlight-color:transparent;">
  <div style="
    width:24px; height:24px; border-radius:6px;
    font-size:10px; font-weight:700; flex-shrink:0;
    text-align:center; line-height:24px;
    color:${isSelected ? '#ffffff' : '#374151'};
    background-color:${isSelected ? '#2563eb' : '#d1d5db'};
    -webkit-tap-highlight-color:transparent;
  ">$label</div>
  <div style="flex:1; font-size:${controller.getOptionFontSize()}px; font-weight:${isSelected ? '600' : '500'};">
    $option
  </div>
  <div style="
    width:20px; height:20px;
    border:2px solid ${isSelected ? '#2563eb' : '#9ca3af'};
    border-radius:4px;
    background-color:${isSelected ? '#2563eb' : '#ffffff'};
    display:inline-block; position:relative; flex-shrink:0;
  ">
    ${isSelected ? '<div style="position:absolute; left:4px; top:0; width:6px; height:11px; border:solid #ffffff; border-width:0 2px 2px 0; transform:rotate(45deg);"></div>' : ''}
  </div>
</div>
              ''',
              style: TeXViewStyle.fromCSS('''
padding:12px; margin-bottom:8px; border-radius:8px; cursor:pointer;
-webkit-tap-highlight-color: transparent;
border:${isSelected ? '2px solid #2563eb' : '1px solid #e5e7eb'};
background-color:${isSelected ? '#eff6ff' : 'transparent'};
              '''),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildMAQ(
      Question question,
      TestPlayerController controller,
      ) {
    return _MAQView(
      key: ValueKey('maq_${question.questionId}_${question.number}'),
      question: question,
      controller: controller,
      effectiveHtml: _effectiveHtml(question, controller),
    );
  }


  // Numerical Answer
  Widget _buildNumerical(Question question,TestPlayerController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CachedTeX(
          key: ValueKey('num_q_${question.questionId}_${question.number}'),
          html: _effectiveHtml(question, controller),
          fontSize: controller.getQuestionFontSize(),
          extraCss: 'margin-bottom:16px;',
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
        _CachedTeX(
          key: ValueKey('tf_q_${question.questionId}_${question.number}'),
          html: _effectiveHtml(question, controller),
          fontSize: controller.getQuestionFontSize(),
          extraCss: 'margin-bottom:16px;',
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
            _CachedTeX(
              key: ValueKey('txt_q_${question.questionId}_${question.number}'),
              html: _effectiveHtml(question, controller),
              fontSize: controller.getQuestionFontSize(),
              extraCss: 'margin-bottom:16px;',
            ),
            if (false) Column(
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
            _CachedTeX(
              key: ValueKey('subj_q_${question.questionId}_${question.number}'),
              html: _effectiveHtml(question, controller),
              fontSize: controller.getQuestionFontSize(),
              extraCss: 'margin-bottom:16px;',
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
      loadingWidgetBuilder: (_) => const SizedBox.shrink(),
      style: const TeXViewStyle(
        backgroundColor: Colors.white,
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
    // Force every <img> and <table> inside the passage / question HTML to
    // shrink to the container width so images don't get cropped on the right.
    const fitMediaCss = '''
<style>
  .passage-body img, .question-body img {
    max-width: 100% !important;
    height: auto !important;
    display: block;
    margin: 6px 0;
  }
  .passage-body table, .question-body table { max-width: 100% !important; }
  .passage-body, .question-body {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    word-wrap: break-word;
    overflow-wrap: break-word;
  }
</style>
''';
    return '''
$fitMediaCss
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
">
  <div style="font-size:11px;font-weight:700;color:#4F46E5;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px;">Passage</div>
  <div class="passage-body">$passage</div>
</div>
<div class="question-body">$qHtml</div>''';
  }

}

/// Holds a TeXView in state and only rebuilds the underlying webview when
/// the [html] or [fontSize] actually changes. This stops the webview from
/// reloading (and visibly flickering) when the parent rebuilds for unrelated
/// reasons — e.g. selecting an MCQ option, typing in a numerical answer.
class _CachedTeX extends StatefulWidget {
  final String html;
  final double fontSize;
  final String? extraCss;
  const _CachedTeX({
    super.key,
    required this.html,
    required this.fontSize,
    this.extraCss,
  });

  @override
  State<_CachedTeX> createState() => _CachedTeXState();
}

class _CachedTeXState extends State<_CachedTeX> {
  late Widget _cached;

  @override
  void initState() {
    super.initState();
    _cached = _build();
  }

  @override
  void didUpdateWidget(_CachedTeX old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html ||
        old.fontSize != widget.fontSize ||
        old.extraCss != widget.extraCss) {
      _cached = _build();
    }
  }

  Widget _build() {
    return TeXView(
      loadingWidgetBuilder: (_) => const SizedBox.shrink(),
      style: const TeXViewStyle(
        backgroundColor: Colors.white,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewDocument(
        widget.html,
        style: TeXViewStyle.fromCSS(
          'font-size:${widget.fontSize}px; ${widget.extraCss ?? ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _cached;
}

class _SingleDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if ('.'.allMatches(text).length > 1) return oldValue;
    return newValue;
  }
}

/// Match-the-following view.
/// The TeXView header is built once and held in state, so cell taps that change
/// only the grid don't force the underlying webview to reload (avoids flicker).
class _MAQView extends StatefulWidget {
  final Question question;
  final TestPlayerController controller;
  final String effectiveHtml;
  const _MAQView({
    super.key,
    required this.question,
    required this.controller,
    required this.effectiveHtml,
  });

  @override
  State<_MAQView> createState() => _MAQViewState();
}

class _MAQViewState extends State<_MAQView> {
  late Widget _teXHeader;
  late List<MatchPair> _pairs;
  late List<String> _rightOptions;
  late List<String> _rightTexts;

  bool _isEmptyText(String t) {
    final stripped = t
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', '')
        .trim();
    return stripped.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _rebuildHeader();
  }

  void _rebuildHeader() {
    final allPairs = widget.question.matchPairs ?? const <MatchPair>[];
    _pairs = allPairs.where((p) => !_isEmptyText(p.leftText)).toList();
    final rawOptions = _pairs.isNotEmpty ? _pairs.first.rightOptions : const <String>[];
    final rawTexts = _pairs.isNotEmpty ? _pairs.first.rightTexts : const <String>[];
    _rightOptions = [];
    _rightTexts = [];
    for (var i = 0; i < rawOptions.length; i++) {
      final t = i < rawTexts.length ? rawTexts[i] : '';
      if (_isEmptyText(t)) continue;
      _rightOptions.add(rawOptions[i]);
      _rightTexts.add(t);
    }

    final qFs = widget.controller.getQuestionFontSize();
    final oFs = widget.controller.getOptionFontSize();

    final leftItemsHtml = StringBuffer();
    for (final pair in _pairs) {
      leftItemsHtml.write('''
        <div style="display:flex; align-items:center; margin-bottom:14px;">
          <span style="font-weight:600; color:#1f2937; font-size:${oFs}px; margin-right:8px;">(${pair.left})</span>
          <span style="font-size:${oFs}px; color:#1f2937;">${pair.leftText}</span>
        </div>
      ''');
    }
    final rightItemsHtml = StringBuffer();
    for (int i = 0; i < _rightOptions.length; i++) {
      final label = _rightOptions[i];
      final text = i < _rightTexts.length ? _rightTexts[i] : '';
      rightItemsHtml.write('''
        <div style="display:flex; align-items:center; margin-bottom:14px;">
          <span style="font-weight:600; color:#1f2937; font-size:${oFs}px; margin-right:8px;">($label)</span>
          <span style="font-size:${oFs}px; color:#1f2937;">$text</span>
        </div>
      ''');
    }

    final headerHtml = '''
${widget.effectiveHtml}
<div style="display:flex; gap:24px; margin:12px 0 16px 0;">
  <div style="flex:1;">$leftItemsHtml</div>
  <div style="flex:1;">$rightItemsHtml</div>
</div>
<div style="height:1px; background:#d1d5db; margin-bottom:12px;"></div>
<div style="
  padding:8px 12px; margin-bottom:6px;
  background:rgba(79,70,229,0.08); border-radius:6px;
  font-size:12px; font-weight:600; color:#4F46E5;
">Tap a cell to match — multiple selections per row are allowed.</div>
''';

    _teXHeader = TeXView(
      loadingWidgetBuilder: (_) => const SizedBox.shrink(),
      style: const TeXViewStyle(
        backgroundColor: Colors.white,
        padding: TeXViewPadding.all(0),
      ),
      child: TeXViewDocument(
        headerHtml,
        style: TeXViewStyle.fromCSS('font-size:${qFs}px;'),
      ),
    );
  }

  Widget _gridCell({
    required Widget child,
    Color bg = Colors.transparent,
    VoidCallback? onTap,
  }) {
    final box = Container(
      width: 44,
      height: 40,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: box,
    );
  }

  Widget _label(String text) => _gridCell(
    bg: const Color(0xFFF3F4F6),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Color(0xFF374151),
      ),
    ),
  );

  Widget _checkbox(bool isSelected) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
      border: Border.all(
        color: isSelected
            ? const Color(0xFF4F46E5)
            : const Color(0xFF9CA3AF),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(4),
    ),
    child: isSelected
        ? const Icon(Icons.check, size: 16, color: Colors.white)
        : null,
  );

  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty) {
      return const Text('No match data available for this question.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _teXHeader,
        const SizedBox(height: 4),
        // Only the grid rebuilds on selection changes — the cached TeXView above stays put.
        GetBuilder<TestPlayerController>(
          id: 'palette',
          builder: (_) {
            final headerRow = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _gridCell(child: const SizedBox.shrink()),
                ..._rightOptions.map(_label),
              ],
            );
            final dataRows = _pairs.map((pair) {
              final selectedRights =
                  widget.question.matchAnswers?[pair.left] ??
                      const <String>[];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _label(pair.left),
                  ..._rightOptions.map((rightLabel) {
                    final isSelected = selectedRights.contains(rightLabel);
                    return _gridCell(
                      onTap: () =>
                          widget.controller.selectMatch(pair.left, rightLabel),
                      child: _checkbox(isSelected),
                    );
                  }),
                ],
              );
            }).toList();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [headerRow, ...dataRows],
              ),
            );
          },
        ),
      ],
    );
  }
}