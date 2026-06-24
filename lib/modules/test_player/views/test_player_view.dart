import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';
import 'package:suguna_exam_app/data/services/sessions.dart';
import 'package:suguna_exam_app/modules/test_player/views/question_options_widget.dart';
import 'package:suguna_exam_app/modules/test_player/views/test_review_view.dart';

import '../../../core/routes/app_routes.dart';
import '../controllers/test_player_controller.dart';
import '../controllers/test_player_parser.dart';


class TestPlayerView extends StatefulWidget {
  const TestPlayerView({super.key});
  @override
  State<TestPlayerView> createState() => _TestPlayerViewState();
}

class _TestPlayerViewState extends State<TestPlayerView> with WidgetsBindingObserver{

  final ScrollController _categoryScrollController = ScrollController();
  final Map<int, GlobalKey> _categoryTabKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _ensureCurrentCategoryVisible(int rawIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _categoryTabKeys[rawIndex];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background — warn user
      // Get.snackbar(
      //   '⚠️ Warning',
      //   'Do not leave the exam screen!',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: const Color(0xFFEF4444),
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 3),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TestPlayerController>(
      id: 'palette',
      builder: (controller) {
        return PopScope(
          canPop: false,
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F7FA),
              body: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(controller),
                    Obx(() {
                      return Expanded(
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: IgnorePointer(
                                    ignoring: controller.isTimerCompleted,
                                    child: _buildQuestionPanel(controller),
                                  ),
                                ),
                                _buildQuestionPalette(controller),
                              ],
                            ),
                            if (controller.isSubmitting.value)
                              const Positioned.fill(
                                child: ColoredBox(
                                  color: Color(0x99000000),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                            color: Colors.white),
                                        SizedBox(height: 16),
                                        Text(
                                          'Submitting your exam…',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(TestPlayerController controller) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.book_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  controller.examCode,
                  // "${Session.instance.selectedSubject?.name} | ${Session.instance.selectedSubtopic?.name} | ${Session.instance.selectedSub}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Obx(() {
            final isWarning = controller.isLastFiveMinutes;
            final shouldBlink =
                controller.enableBlinkingTimer && controller.isLastOneMinute;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (!shouldBlink || controller.blinkOn.value) ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isWarning
                        ? [const Color(0xFFF97316), const Color(0xFFEA580C)] // orange
                        : [const Color(0xFFEF4444), const Color(0xFFDC2626)], // red
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isWarning
                          ? const Color(0xFFF97316)
                          : const Color(0xFFEF4444))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      controller.formattedTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(width: 16),
          // OutlinedButton.icon(
          //   onPressed: () {
          //     _showRetestConfirmation(controller);
          //   },
          //   icon: const Icon(Icons.exit_to_app_rounded, size: 18),
          //   label: const Text('Exit'),
          //   style: OutlinedButton.styleFrom(
          //     foregroundColor: const Color(0xFFEF4444),
          //     side: const BorderSide(color: Color(0xFFEF4444)),
          //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circula
          //      r(12),
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: controller.completeTest,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: const Text('Submit Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.scoreDarkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilterBar(TestPlayerController controller) {
    if (controller.availableSubjects.length <= 1) return const SizedBox.shrink();

    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text(
            'Subject:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "All" chip
                  // _buildSubjectChip(
                  //   label: 'All',
                  //   isSelected: controller.selectedSubjectFilter.value == 'All',
                  //   onTap: () => controller.setSubjectFilter('All'),
                  // ),
                  const SizedBox(width: 8),
                  ...controller.availableSubjects.map((subject) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSubjectChip(
                      label: subject.name,
                      isSelected: controller.selectedSubjectFilter.value == subject.name,
                      onTap: () => controller.setSubjectFilter(subject.name),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSubjectChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUESTION PANEL WITH CATEGORY TABS
  // ============================================================

  Widget _buildQuestionPanel(TestPlayerController controller) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: controller.isLoading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Center(child: CircularProgressIndicator())],
            )
          : Column(
              children: [
                _buildSubjectFilterBar(controller),
                _buildCategoryTabs(),
                Expanded(child: QuestionOptionsWidget()),
                _buildActionButtons(),
              ],
            ),
    );
  }


  Widget _buildCategoryTabs() {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {
        return Obx(
          () => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF8F9FC), Colors.white],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: List.generate(controller.filteredCategories.length, (index) {
                        final category = controller.filteredCategories[index];

                        // ← Always resolve raw index for both highlight check and onTap
                        final rawIndex = controller.categories
                            .indexWhere((c) => c.id == category.id);
                        final isSelected =
                            controller.currentCategoryIndex.value == rawIndex;
                        final tabKey = _categoryTabKeys.putIfAbsent(
                            rawIndex, () => GlobalKey());
                        if (isSelected) {
                          _ensureCurrentCategoryVisible(rawIndex);
                        }

                        return Padding(
                          key: tabKey,
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryTab(
                            category: category,
                            isSelected: isSelected,
                            onTap: () => controller.selectCategory(rawIndex), // ← raw, not index
                          ),
                        );
                      }),
                    ),
                    // child: Row(
                    //   children: List.generate(controller.filteredCategories.length, (
                    //     index,
                    //   ) {
                    //     final category = controller.filteredCategories[index];
                    //     final isSelected =
                    //         controller.currentCategoryIndex.value == index;
                    //     return Padding(
                    //       padding: const EdgeInsets.only(right: 8),
                    //       child: _buildCategoryTab(
                    //         category: category,
                    //         isSelected: isSelected,
                    //         onTap: () => controller.selectCategory(index),
                    //       ),
                    //     );
                    //   }),
                    // ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      _buildTextSizeButton(0, 'A'),
                      const SizedBox(width: 4),
                      _buildTextSizeButton(1, 'A+'),
                      const SizedBox(width: 4),
                      _buildTextSizeButton(2, 'A++'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => {
                      _showReportQuestionDialog(
                        controller,
                        controller.currentQuestion.questionId,
                        controller.currentQuestion.number,
                      )
                    },
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: BorderSide(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextSizeButton(int size, String label) {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {
        final isSelected = controller.textSize.value == size;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.setTextSize(size),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTab({
    required QuestionCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.questionCount.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [

              // Previous Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.previous(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Previous', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Clear Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.clearResponse(),
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:  Colors.black,
                    side: const BorderSide(color:  Colors.black),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Save & Mark
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.saveAndMarkForReview(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save & Mark for Review',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Mark & Next
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.markForReviewAndNext(),
                  label: const Text(
                    'Mark for Review & Next',
                    style: TextStyle(fontSize: 12),
                  ),
                  // icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF286090),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Save & Next
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.saveAndNext(),
                  label: const Text(
                    'Save & Next',
                    style: TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.scoreDarkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // QUESTION PALETTE
  // ============================================================

  Widget _buildQuestionPalette(TestPlayerController controller) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPaletteHeader(controller),
          if (controller.showCalculator)
            Expanded(child: _buildCalculator(controller))
          else ...[
            Flexible(child: _buildCategoryPalettes()),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaletteHeader(TestPlayerController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(
            controller.showCalculator ? Icons.calculate_rounded : Icons.grid_view_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            controller.showCalculator ? 'Calculator' : 'Question Palette',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (controller.calculatorType != CalculatorType.none)
            InkWell(
              onTap: controller.toggleCalculator,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.showCalculator
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.showCalculator ? Icons.grid_view_rounded : Icons.calculate_rounded,
                  color: controller.showCalculator ? AppColors.primary : Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CALCULATOR
  // ============================================================

  String _calcDisplay = '0';
  String _calcExpression = '';
  String _calcOperator = '';
  double _calcFirstOperand = 0;
  bool _calcShouldResetDisplay = false;

  Widget _buildCalculator(TestPlayerController controller) {
    return controller.calculatorType == CalculatorType.scientific
        ? _buildScientificCalculator()
        : _buildBasicCalculator();
  }

  String _formatResult(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _handleCalcInput(String value, void Function(void Function()) setCalcState) {
    setCalcState(() {
      if (value == 'C') {
        _calcDisplay = '0';
        _calcExpression = '';
        _calcOperator = '';
        _calcFirstOperand = 0;
        _calcShouldResetDisplay = false;
      } else if (value == '⌫') {
        if (_calcDisplay.length > 1) {
          _calcDisplay = _calcDisplay.substring(0, _calcDisplay.length - 1);
        } else {
          _calcDisplay = '0';
        }
      } else if (value == '+' || value == '-' || value == '×' || value == '÷') {
        _calcFirstOperand = double.tryParse(_calcDisplay) ?? 0;
        _calcOperator = value;
        _calcExpression = '$_calcDisplay $value';
        _calcShouldResetDisplay = true;
      } else if (value == 'xʸ') {
        _calcFirstOperand = double.tryParse(_calcDisplay) ?? 0;
        _calcOperator = 'xʸ';
        _calcExpression = '$_calcDisplay ^';
        _calcShouldResetDisplay = true;
      } else if (value == '=') {
        double secondOperand = double.tryParse(_calcDisplay) ?? 0;
        double result = 0;
        switch (_calcOperator) {
          case '+':
            result = _calcFirstOperand + secondOperand;
            break;
          case '-':
            result = _calcFirstOperand - secondOperand;
            break;
          case '×':
            result = _calcFirstOperand * secondOperand;
            break;
          case '÷':
            result = secondOperand != 0 ? _calcFirstOperand / secondOperand : 0;
            break;
          case 'xʸ':
            result = math.pow(_calcFirstOperand, secondOperand).toDouble();
            break;
          default:
            result = secondOperand;
        }
        _calcExpression = '$_calcExpression $_calcDisplay =';
        _calcDisplay = _formatResult(result);
        _calcOperator = '';
        _calcShouldResetDisplay = true;
      } else if (value == '.') {
        if (!_calcDisplay.contains('.')) {
          _calcDisplay = '$_calcDisplay.';
        }
      } else if (value == '±') {
        if (_calcDisplay != '0') {
          _calcDisplay = _calcDisplay.startsWith('-')
              ? _calcDisplay.substring(1)
              : '-$_calcDisplay';
        }
      } else if (value == '%') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcDisplay = _formatResult(current / 100);
      } else if (value == '√') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        if (current >= 0) {
          _calcExpression = '√$_calcDisplay';
          _calcDisplay = _formatResult(math.sqrt(current));
        }
      } else if (value == 'sin') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcExpression = 'sin($_calcDisplay°)';
        _calcDisplay = _formatResult(math.sin(current * math.pi / 180));
        _calcShouldResetDisplay = true;
      } else if (value == 'cos') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcExpression = 'cos($_calcDisplay°)';
        _calcDisplay = _formatResult(math.cos(current * math.pi / 180));
        _calcShouldResetDisplay = true;
      } else if (value == 'tan') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcExpression = 'tan($_calcDisplay°)';
        _calcDisplay = _formatResult(math.tan(current * math.pi / 180));
        _calcShouldResetDisplay = true;
      } else if (value == 'log') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        if (current > 0) {
          _calcExpression = 'log($_calcDisplay)';
          _calcDisplay = _formatResult(math.log(current) / math.ln10);
          _calcShouldResetDisplay = true;
        }
      } else if (value == 'ln') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        if (current > 0) {
          _calcExpression = 'ln($_calcDisplay)';
          _calcDisplay = _formatResult(math.log(current));
          _calcShouldResetDisplay = true;
        }
      } else if (value == 'x²') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcExpression = '$_calcDisplay²';
        _calcDisplay = _formatResult(current * current);
        _calcShouldResetDisplay = true;
      } else if (value == 'x³') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcExpression = '$_calcDisplay³';
        _calcDisplay = _formatResult(current * current * current);
        _calcShouldResetDisplay = true;
      } else if (value == '1/x') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        if (current != 0) {
          _calcExpression = '1/$_calcDisplay';
          _calcDisplay = _formatResult(1 / current);
          _calcShouldResetDisplay = true;
        }
      } else if (value == 'π') {
        _calcDisplay = _formatResult(math.pi);
        _calcShouldResetDisplay = true;
      } else if (value == 'e') {
        _calcDisplay = _formatResult(math.e);
        _calcShouldResetDisplay = true;
      } else if (value == 'n!') {
        int current = (double.tryParse(_calcDisplay) ?? 0).toInt();
        if (current >= 0 && current <= 20) {
          int factorial = 1;
          for (int i = 2; i <= current; i++) {
            factorial *= i;
          }
          _calcExpression = '$current!';
          _calcDisplay = factorial.toString();
          _calcShouldResetDisplay = true;
        }
      } else if (value == '|x|') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcExpression = '|$_calcDisplay|';
        _calcDisplay = _formatResult(current.abs());
        _calcShouldResetDisplay = true;
      } else if (value == 'EXP') {
        double current = double.tryParse(_calcDisplay) ?? 0;
        _calcExpression = 'e^$_calcDisplay';
        _calcDisplay = _formatResult(math.exp(current));
        _calcShouldResetDisplay = true;
      } else {
        // Number input
        if (_calcShouldResetDisplay) {
          _calcDisplay = value;
          _calcShouldResetDisplay = false;
        } else {
          _calcDisplay = _calcDisplay == '0' ? value : _calcDisplay + value;
        }
      }
    });
  }

  Widget _buildCalcDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFFF8F9FC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_calcExpression.isNotEmpty)
            Text(
              _calcExpression,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _calcDisplay,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- BASIC CALCULATOR ----

  Widget _buildBasicCalculator() {
    return StatefulBuilder(
      builder: (context, setCalcState) {
        void onPressed(String value) => _handleCalcInput(value, setCalcState);

        return Column(
          children: [
            _buildCalcDisplay(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildCalcRow(['C', '⌫', '%', '÷'], onPressed, isTopRow: true),
                    _buildCalcRow(['7', '8', '9', '×'], onPressed),
                    _buildCalcRow(['4', '5', '6', '-'], onPressed),
                    _buildCalcRow(['1', '2', '3', '+'], onPressed),
                    _buildCalcRow(['±', '0', '.', '='], onPressed),
                    _buildCalcRow(['√'], onPressed),
                  ].expand((row) => [row, const SizedBox(height: 6)]).toList()
                    ..removeLast(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- SCIENTIFIC CALCULATOR ----

  Widget _buildScientificCalculator() {
    return StatefulBuilder(
      builder: (context, setCalcState) {
        void onPressed(String value) => _handleCalcInput(value, setCalcState);

        return Column(
          children: [
            _buildCalcDisplay(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    // Scientific function rows
                    _buildCalcRow(['sin', 'cos', 'tan', 'π'], onPressed, isTopRow: true, fontSize: 13),
                    _buildCalcRow(['log', 'ln', 'EXP', 'e'], onPressed, fontSize: 13),
                    _buildCalcRow(['x²', 'x³', 'xʸ', '√'], onPressed, fontSize: 13),
                    _buildCalcRow(['n!', '1/x', '|x|', '%'], onPressed, fontSize: 13),
                    // Standard rows
                    _buildCalcRow(['C', '⌫', '±', '÷'], onPressed),
                    _buildCalcRow(['7', '8', '9', '×'], onPressed),
                    _buildCalcRow(['4', '5', '6', '-'], onPressed),
                    _buildCalcRow(['1', '2', '3', '+'], onPressed),
                    _buildCalcRow(['0', '.', '='], onPressed),
                  ].expand((row) => [row, const SizedBox(height: 4)]).toList()
                    ..removeLast(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalcRow(List<String> buttons, void Function(String) onPressed, {bool isTopRow = false, double? fontSize}) {
    return Expanded(
      child: Row(
        children: buttons
            .expand((btn) => [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _buildCalcButton(btn, onPressed, isTopRow: isTopRow, fontSize: fontSize),
                    ),
                  ),
                ])
            .toList(),
      ),
    );
  }

  Widget _buildCalcButton(String label, void Function(String) onPressed, {bool isTopRow = false, double? fontSize}) {
    final isOperator = ['+', '-', '×', '÷', '='].contains(label);
    final isScientific = ['sin', 'cos', 'tan', 'log', 'ln', 'EXP', 'x²', 'x³', 'xʸ', 'n!', '1/x', '|x|', 'π', 'e'].contains(label);
    final isSpecial = ['C', '⌫', '%', '±', '√'].contains(label);

    Color bgColor;
    Color textColor;

    if (label == '=') {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
    } else if (isScientific) {
      bgColor = const Color(0xFFE8EAF6);
      textColor = const Color(0xFF3949AB);
    } else if (isSpecial) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    } else {
      bgColor = const Color(0xFFF5F7FA);
      textColor = AppColors.textPrimary;
    }

    final double effectiveFontSize = fontSize ?? (label == '⌫' ? 18 : 20);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onPressed(label),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: isOperator || label == '=' ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {
        // Calculate totals across all categories
        int answeredCount = 0;
        int notAnsweredCount = 0;
        int markedCount = 0;
        int answeredAndMarkedCount = 0;
        int notVisitedCount = 0;

        for (var category in controller.filteredCategories) {
          for (var question in category.questions) {
            switch (question.status) {
              case QuestionStatus.answered:
                answeredCount++;
                break;
              case QuestionStatus.notAnswered:
                notAnsweredCount++;
                break;
              case QuestionStatus.markedForReview:
                markedCount++;
                break;
              case QuestionStatus.answeredAndMarked:
                answeredAndMarkedCount++;
                break;
              case QuestionStatus.notVisited:
                notVisitedCount++;
                break;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildLegendItem(
                color: const Color(0xFF10B981),
                label: 'Answered',
                status: QuestionStatus.answered,
                icon: Icons.check_circle_rounded,
                count: answeredCount,
              ),
              const SizedBox(height: 6),
              _buildLegendItem(
                color: const Color(0xFFEF4444),
                label: 'Not Answered',
                status: QuestionStatus.notAnswered,
                icon: Icons.cancel_rounded,
                count: notAnsweredCount,
              ),
              const SizedBox(height: 6),
              _buildLegendItem(
                status: QuestionStatus.markedForReview,
                color: const Color(0xFFF59E0B),
                label: 'Marked',
                icon: Icons.bookmark_rounded,
                count: markedCount,
              ),
              const SizedBox(height: 6),
              _buildLegendItem(
                color: const Color(0xFF8B5CF6),
                label: 'Ans & Marked',
                status: QuestionStatus.answeredAndMarked,
                icon: Icons.bookmark_added_rounded,
                count: answeredAndMarkedCount,
              ),
              const SizedBox(height: 6),
              _buildLegendItem(
                color: const Color(0xFF6B7280),
                label: 'Not Visited',
                status: QuestionStatus.notVisited,
                icon: Icons.circle_outlined,
                count: notVisitedCount,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem({
    required QuestionStatus status,
    required Color color,
    required String label,
    required IconData icon,
    required int count,
  }) {
    return Row(
      children: [
        _buildMiniPalette(status: status),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPalette({
    required QuestionStatus status,
  }) {
    // Give the mini-palette extra room so the green tick badge isn't clipped.
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: _buildMiniPaletteCore(status),
      ),
    );
  }

  Widget _buildMiniPaletteCore(QuestionStatus status) {
    Color bgColor;
    Color textColor = Colors.white;
    bool showTick = false;
    BorderRadius borderRadius = BorderRadius.circular(4);

    switch (status) {
      case QuestionStatus.notVisited:
        bgColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF111827);
        break;

      case QuestionStatus.notAnswered:
        bgColor = const Color(0xFFDC2626);
        borderRadius = const BorderRadius.vertical(
          bottom: Radius.circular(10),
        );
        break;

      case QuestionStatus.answered:
        bgColor = const Color(0xFF16A34A);
        borderRadius = const BorderRadius.vertical(
          top: Radius.circular(10),
        );
        break;

      case QuestionStatus.markedForReview:
        bgColor = const Color(0xFF7C3AED);
        borderRadius = BorderRadius.circular(10);
        break;

      case QuestionStatus.answeredAndMarked:
        bgColor = const Color(0xFF7C3AED);
        borderRadius = BorderRadius.circular(10);
        showTick = true;
        break;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: const Color(0xFF9CA3AF),
          width: 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Text(
              '',
              style: TextStyle(color: textColor),
            ),
          ),
          if (showTick)
            const Positioned(
              top: -3,
              right: -3,
              child: Icon(
                Icons.check_circle,
                size: 10,
                color: Color(0xFF22C55E),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPalettes() {
    return GetBuilder<TestPlayerController>(
      builder: (controller) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: controller.filteredCategories.length,
          itemBuilder: (context, categoryIndex) {
            final category = controller.filteredCategories[categoryIndex];
            final rawCategoryIndex = controller.categories
                .indexWhere((c) => c.id == category.id);

            return Obx(() {
              final isCurrentCategory =
                  controller.currentCategoryIndex.value == rawCategoryIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCurrentCategory
                      ? AppColors.primary.withOpacity(0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentCategory
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCurrentCategory
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentCategory
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${category.questionCount}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isCurrentCategory
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GetBuilder<TestPlayerController>(
                      builder: (_) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(category.questions.length, (
                                questionIndex,
                                ) {
                              final question = category.questions[questionIndex];

                              // ← Resolve raw question index by question number
                              final rawQuestionIndex = rawCategoryIndex != -1
                                  ? controller.categories[rawCategoryIndex]
                                  .questions
                                  .indexWhere((q) => q.number == question.number)
                                  : questionIndex;

                              final isCurrent = isCurrentCategory &&
                                  controller.currentQuestionIndex.value ==
                                      rawQuestionIndex;

                              return _buildQuestionNumber(
                                number: question.number,
                                status: question.status,
                                isCurrent: isCurrent,
                                onTap: () => controller.selectQuestion(
                                  rawCategoryIndex,
                                  rawQuestionIndex != -1
                                      ? rawQuestionIndex
                                      : questionIndex,
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }

  Widget _buildQuestionNumber({
    required int number,
    required QuestionStatus status,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color textColor = Colors.white;
    bool showTick = false;
    BoxBorder border =  Border.all(
      color: isCurrent ? Colors.black : const Color(0xFF9CA3AF),
      width: isCurrent ? 2 : 1,
    );
    BorderRadiusGeometry borderRadiusGeometry = BorderRadius.circular(6);

    switch (status) {
      case QuestionStatus.notVisited:
        bgColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF111827);
        break;

      case QuestionStatus.notAnswered:
        bgColor = const Color(0xFFDC2626);
        borderRadiusGeometry  = BorderRadiusGeometry.vertical(
          bottom: Radius.circular(18)
        );
        break;

      case QuestionStatus.answered:
        bgColor = const Color(0xFF16A34A);
        borderRadiusGeometry  = BorderRadiusGeometry.vertical(
            top: Radius.circular(18)
        );
        break;

      case QuestionStatus.markedForReview:
        bgColor = const Color(0xFF7C3AED);
        borderRadiusGeometry  = BorderRadiusGeometry.circular(18);
        break;

      case QuestionStatus.answeredAndMarked:
        bgColor = const Color(0xFF7C3AED);
        showTick = true;
        borderRadiusGeometry  = BorderRadiusGeometry.circular(18);
        break;
    }

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: borderRadiusGeometry,
                border: border,
              ),
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (showTick)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRetestConfirmation(TestPlayerController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.refresh_rounded, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('Exit?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to retake close this test? All your current answers will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              controller.clearData();
              Get.offAllNamed(AppRoutes.discussion);
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }
  void _showReportQuestionDialog(
      TestPlayerController controller,
      String questionId,
      int questionNumber,
      ) {
    final TextEditingController commentController = TextEditingController();
    String selectedIssue = "Incorrect Answer";

    final List<String> issueTypes = [
      "Incorrect Answer",
      "Typo / Spelling Mistake",
      "Question Not Clear",
      "Options Missing / Incorrect",
      "Duplicate Question",
      "Other",
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 500, // wider dialog
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          color: Colors.red, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        "Report Question $questionNumber",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// ISSUE TYPE DROPDOWN
                  const Text(
                    "Type of Issue",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedIssue,
                    items: issueTypes
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedIssue = value!;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// COMMENT BOX
                  const Text(
                    "Describe the issue",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    maxLength: 250,
                    decoration: InputDecoration(
                      hintText: "Write your comment here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ACTION BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (commentController.text.trim().isEmpty) {
                            Get.snackbar(
                              "Error",
                              "Please enter a comment",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          Get.back();


                          controller.reportQuestion(
                            questionId: questionId,
                            issueType: selectedIssue,
                            comment: commentController.text.trim(),
                          );
                          Get.snackbar(
                            "Reported",
                            "Question reported successfully",
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );


                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text("Submit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
