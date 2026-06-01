import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/exam_model.dart';
import '../controllers/discussion_list_controller.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

class _C {
  static const primary     = Color(0xFF4F46E5);
  static const bgPage      = Color(0xFFF8F9FC);
  static const bgCard      = Colors.white;
  static const border      = Color(0xFFE8ECF4);

  // Status colors
  static const sLive       = Color(0xFF059669);
  static const sLiveBg     = Color(0xFFD1FAE5);
  static const sOpen       = Color(0xFF0284C7);
  static const sOpenBg     = Color(0xFFDBEAFE);
  static const sAttempted  = Color(0xFF7C3AED);
  static const sAttemptedBg = Color(0xFFEDE9FE);
  static const sResult     = Color(0xFFD97706);
  static const sResultBg   = Color(0xFFFEF3C7);
  static const sClosed     = Color(0xFFDC2626);
  static const sClosedBg   = Color(0xFFFEE2E2);
  static const sDefault    = Color(0xFF64748B);
  static const sDefaultBg  = Color(0xFFF1F5F9);
}

// ── Status helpers ────────────────────────────────────────────────────────────

class _ExamStatusStyle {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String label;

  const _ExamStatusStyle({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.label,
  });

  static _ExamStatusStyle fromExam(ExamModel exam) {
    if (exam.isResultVisible) {
      return const _ExamStatusStyle(
        color: _C.sResult, bgColor: _C.sResultBg,
        icon: Icons.bar_chart_rounded, label: 'Result Published',
      );
    }
    if (exam.isLive && exam.canAttempt) {
      return const _ExamStatusStyle(
        color: _C.sLive, bgColor: _C.sLiveBg,
        icon: Icons.play_circle_rounded, label: 'Live',
      );
    }
    if (exam.canAttempt) {
      return const _ExamStatusStyle(
        color: _C.sOpen, bgColor: _C.sOpenBg,
        icon: Icons.lock_open_rounded, label: 'Open',
      );
    }
    if (exam.isAttempted) {
      return const _ExamStatusStyle(
        color: _C.sAttempted, bgColor: _C.sAttemptedBg,
        icon: Icons.check_circle_rounded, label: 'Attempted',
      );
    }
    if (exam.status == 'published') {
      return const _ExamStatusStyle(
        color: _C.sDefault, bgColor: _C.sDefaultBg,
        icon: Icons.schedule_rounded, label: 'Published',
      );
    }
    return _ExamStatusStyle(
      color: _C.sClosed, bgColor: _C.sClosedBg,
      icon: Icons.lock_rounded, label: exam.status.replaceAll('_', ' '),
    );
  }
}

// ── Legend items ──────────────────────────────────────────────────────────────

const _legendItems = <({Color color, Color bgColor, IconData icon, String label})>[
  (color: _C.sLive,      bgColor: _C.sLiveBg,      icon: Icons.play_circle_rounded,  label: 'Live'),
  (color: _C.sOpen,      bgColor: _C.sOpenBg,      icon: Icons.lock_open_rounded,    label: 'Open'),
  (color: _C.sAttempted, bgColor: _C.sAttemptedBg, icon: Icons.check_circle_rounded, label: 'Attempted'),
  (color: _C.sResult,    bgColor: _C.sResultBg,    icon: Icons.bar_chart_rounded,    label: 'Result Published'),
  (color: _C.sClosed,    bgColor: _C.sClosedBg,    icon: Icons.lock_rounded,         label: 'Closed'),
];

// ── Date formatter ────────────────────────────────────────────────────────────

final _dateFmt = DateFormat('dd MMM yyyy');   // existing
final _timeFmt = DateFormat('hh:mm a');        // add this

// ── Tab time filter ──────────────────────────────────────────────────────────

List<ExamModel> _filterByRange(List<ExamModel> exams, int fromMonths, int toMonths) {
  final now = DateTime.now();
  final to = now.subtract(Duration(days: toMonths * 30));
  if (fromMonths == 0) {
    // Most Recent: upcoming + exams within the last period
    return exams.where((e) => e.startDateTime.isAfter(to)).toList();
  }
  final from = now.subtract(Duration(days: fromMonths * 30));
  return exams.where((e) => e.startDateTime.isBefore(from) && e.startDateTime.isAfter(to)).toList();
}

// ── Main widget ───────────────────────────────────────────────────────────────

class DownloadTest extends StatefulWidget {
  const DownloadTest({super.key});

  @override
  State<DownloadTest> createState() => _DownloadTestState();
}

class _DownloadTestState extends State<DownloadTest>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _testIdCtrl   = TextEditingController();
  final _passcodeCtrl = TextEditingController();

  final controller = Get.find<DiscussionListController>();

  static const _labels = ['Most Recent', 'Six Months', 'One Year', 'Two Years', 'Three Years', 'Four Years'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this, initialIndex: 0, animationDuration: Duration.zero);
  }

  @override
  void dispose() {
    _tab.dispose();
    _testIdCtrl.dispose();
    _passcodeCtrl.dispose();
    super.dispose();
  }

  List<ExamModel> _getFilteredExams(int tabIndex) {
    final allExams = controller.exams;
    switch (tabIndex) {
      case 0: return _filterByRange(allExams, 0, 1);    // Most Recent: last 1 month
      case 1: return _filterByRange(allExams, 1, 6);    // Six Months: 1–6 months ago
      case 2: return _filterByRange(allExams, 6, 12);   // One Year: 6–12 months ago
      case 3: return _filterByRange(allExams, 12, 24);  // Two Years: 1–2 years ago
      case 4: return _filterByRange(allExams, 24, 36);  // Three Years: 2–3 years ago
      case 5: return _filterByRange(allExams, 36, 48);  // Four Years: 3–4 years ago
      default: return allExams;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: _C.bgPage,
      body: Column(
        children: [
          _AppHeader(tabController: _tab, labels: _labels),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.isNotEmpty) {
                return _ErrorView(
                  message: controller.errorMessage.value,
                  onRetry: controller.fetchExams,
                );
              }
              return wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _gridView()),
                      _Sidebar(testIdCtrl: _testIdCtrl, passcodeCtrl: _passcodeCtrl),
                    ])
                  : Column(children: [
                      Expanded(child: _gridView()),
                      _Sidebar(testIdCtrl: _testIdCtrl, passcodeCtrl: _passcodeCtrl),
                    ]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _gridView() {
    return TabBarView(
      controller: _tab,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(6, (i) {
        return RefreshIndicator(
          color: _C.primary,
          onRefresh: () async => controller.fetchExams(),
          child: Obx(() {
            final filtered = _getFilteredExams(i);
            if (filtered.isEmpty) {
              // ListView so RefreshIndicator has a scrollable to attach to
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No exams available',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                    ),
                  ),
                ],
              );
            }
            return _ExamGrid(exams: filtered);
          }),
        );
      }),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final TabController tabController;
  final List<String> labels;
  const _AppHeader({required this.tabController, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.primary,
        boxShadow: [BoxShadow(color: Color(0x284F46E5), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Exam App',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () => Get.find<DiscussionListController>().fetchExams(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: tabController,
              isScrollable: false,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
              tabs: labels.map((l) => Tab(text: l)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid ──────────────────────────────────────────────────────────────────────

class _ExamGrid extends StatelessWidget {
  final List<ExamModel> exams;
  const _ExamGrid({required this.exams});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 600 ? 3 : c.maxWidth > 400 ? 2 : 1;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: exams.length,
        itemBuilder: (_, i) => _ExamCard(exam: exams[i]),
      );
    });
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final s = _ExamStatusStyle.fromExam(exam);
    final ctrl = Get.find<DiscussionListController>();
    return Obx(() {
      final isDownloading = ctrl.downloadingExamId.value == exam.examId;
      return InkWell(
        onTap: isDownloading ? null : () => ctrl.onExamTap(exam),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _C.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 5, color: s.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _C.bgPage,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _C.border),
                                  ),
                                  child: Text(
                                    exam.examCode,
                                    style: TextStyle(
                                      color: s.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: s.bgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(s.icon, size: 11, color: s.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.label,
                                      style: TextStyle(
                                        color: s.color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              exam.examName,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exam.totalQuestions}Q  •  ${exam.totalMarks} marks  •  ${exam.duration} min',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 12, color: Color(0xFFADB5C7)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_dateFmt.format(exam.startDateTime)}  •  ${_timeFmt.format(exam.startDateTime)} → ${_timeFmt.format(exam.endDateTime)}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Download overlay
            if (isDownloading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28, height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Downloading...',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    });
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final TextEditingController testIdCtrl;
  final TextEditingController passcodeCtrl;
  const _Sidebar({required this.testIdCtrl, required this.passcodeCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('LEGEND'),
            const SizedBox(height: 10),
            ..._legendItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE8ECF4)),
            const SizedBox(height: 20),

            _sectionLabel('DOWNLOAD TEST'),
            const SizedBox(height: 14),

            _InputField(
              controller: testIdCtrl,
              hint: 'Enter Test ID',
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 10),
            _InputField(
              controller: passcodeCtrl,
              hint: 'Enter Passcode',
              icon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final ctrl = Get.find<DiscussionListController>();
                final downloading = ctrl.isDownloading.value;
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: downloading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    downloading ? 'Downloading...' : 'Download Test',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: downloading
                      ? null
                      : () => ctrl.downloadByTestId(
                            testIdCtrl.text,
                            passcodeCtrl.text,
                          ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFADB5C7),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFADB5C7), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFADB5C7), size: 18),
        filled: true,
        fillColor: _C.bgPage,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
