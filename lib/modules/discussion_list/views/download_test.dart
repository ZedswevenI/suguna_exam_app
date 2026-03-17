import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../topic_assignments/controllers/topic_assignments_controller.dart';

// ── Data model ────────────────────────────────────────────────────────────────

enum TestStatus { open, closed, analysis, yetToOpen }

class TestItem {
  final String testId;
  final String details;
  final String openFrom;
  final String openTill;
  final TestStatus status;

  const TestItem({
    required this.testId,
    required this.details,
    required this.openFrom,
    required this.openTill,
    this.status = TestStatus.open,
  });
}

// ── Sample data ───────────────────────────────────────────────────────────────

const _mostRecent = <TestItem>[
  TestItem(testId: '116201', details: 'ASS_ANALOGY - LATEST',               openFrom: '01 Mar 2026', openTill: '30 Mar 2026'),
  TestItem(testId: '116202', details: 'ASS_CLASSIFICATION - LATEST',        openFrom: '01 Mar 2026', openTill: '30 Mar 2026'),
  TestItem(testId: '116203', details: 'ASS_SERIES NON VERBAL - LATEST',     openFrom: '01 Mar 2026', openTill: '30 Mar 2026'),
  TestItem(testId: '116204', details: 'ASS_ARITHMETIC REASONING - LATEST',  openFrom: '01 Mar 2026', openTill: '30 Mar 2026'),
  TestItem(testId: '116205', details: 'ASS_CALENDER - LATEST',              openFrom: '01 Mar 2026', openTill: '30 Mar 2026', status: TestStatus.analysis),
  TestItem(testId: '116206', details: 'ASS_PLANT TISSUES - LATEST',         openFrom: '01 Mar 2026', openTill: '30 Mar 2026', status: TestStatus.closed),
  TestItem(testId: '116207', details: 'ASS_COMMUNICABLE DISEASES - LATEST', openFrom: '01 Mar 2026', openTill: '30 Mar 2026'),
  TestItem(testId: '116208', details: 'ASS_EXCRETORY PRODUCTS - LATEST',    openFrom: '01 Mar 2026', openTill: '30 Mar 2026', status: TestStatus.yetToOpen),
];

const _sixMonths = <TestItem>[
  TestItem(testId: '115601', details: 'ASS_ANALOGY - 6M',              openFrom: '01 Sep 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115602', details: 'ASS_CLASSIFICATION - 6M',       openFrom: '01 Sep 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115603', details: 'ASS_SERIES NON VERBAL - 6M',    openFrom: '01 Sep 2025', openTill: '13 Mar 2026', status: TestStatus.analysis),
  TestItem(testId: '115604', details: 'ASS_ARITHMETIC REASONING - 6M', openFrom: '01 Sep 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115605', details: 'ASS_CALENDER - 6M',             openFrom: '01 Sep 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115606', details: 'ASS_PLANT TISSUES - 6M',        openFrom: '01 Sep 2025', openTill: '13 Mar 2026', status: TestStatus.closed),
];

const _oneYear = <TestItem>[
  TestItem(testId: '115101', details: 'ASS_ANALOGY - 1Y',               openFrom: '01 Mar 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115102', details: 'ASS_CLASSIFICATION - 1Y',        openFrom: '01 Mar 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115103', details: 'ASS_SERIES NON VERBAL - 1Y',     openFrom: '01 Mar 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115104', details: 'ASS_ARITHMETIC REASONING - 1Y',  openFrom: '01 Mar 2025', openTill: '13 Mar 2026', status: TestStatus.analysis),
  TestItem(testId: '115105', details: 'ASS_CALENDER - 1Y',              openFrom: '01 Mar 2025', openTill: '13 Mar 2026'),
  TestItem(testId: '115106', details: 'ASS_PLANT TISSUES - 1Y',         openFrom: '01 Mar 2025', openTill: '13 Mar 2026', status: TestStatus.closed),
  TestItem(testId: '115107', details: 'ASS_COMMUNICABLE DISEASES - 1Y', openFrom: '01 Mar 2025', openTill: '13 Mar 2026'),
];

const _twoYears = <TestItem>[
  TestItem(testId: '115866', details: 'ASS_ANALOGY',                                                openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115867', details: 'ASS_CLASSIFICATION',                                         openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115871', details: 'ASS_EQUATIONS RATIO PROPORTION & VARIATION ASSIGNMENT - 1',  openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115875', details: 'ASS_ODD ONE OUT FIGURE ASSIGNMENT - 1',                      openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115880', details: 'ASS_IMAGES ASSIGNMENT - 1',                                  openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115881', details: 'ASS_SERIES NON VERBAL',                                      openFrom: '09 May 2019', openTill: '13 Mar 2026', status: TestStatus.analysis),
  TestItem(testId: '115884', details: 'ASS_CALENDER',                                               openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115894', details: 'ASS_ARITHMETIC REASONING',                                   openFrom: '09 May 2019', openTill: '13 Mar 2026', status: TestStatus.closed),
  TestItem(testId: '115904', details: 'ASS_PLANT TISSUES - 1',                                      openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115905', details: 'ASS_COMMUNICABLE DISEASES - 1',                              openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115906', details: 'ASS_EXCRETORY PRODUCTS AND THEIR ELIMINATION - 1',           openFrom: '09 May 2019', openTill: '13 Mar 2026', status: TestStatus.yetToOpen),
  TestItem(testId: '115907', details: 'ASS_Assignment I - Nutrition',                               openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115908', details: 'ASS_NTSE HWP 9 class',                                      openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115910', details: 'ASS_CONTROL AND CO-ORDINATION IN PLANTS - 1',               openFrom: '09 May 2019', openTill: '13 Mar 2026', status: TestStatus.closed),
  TestItem(testId: '115967', details: 'ASS_ASSIGNMENT - 2 - CLASSIFICATION',                        openFrom: '09 May 2019', openTill: '13 Mar 2026'),
  TestItem(testId: '115971', details: 'ASS_EQUATIONS RATIO PROPORTION & VARIATION ASSIGNMENT - II', openFrom: '09 May 2019', openTill: '13 Mar 2026'),
];



// ── Design tokens ─────────────────────────────────────────────────────────────

class _C {
  // App
  static const primary     = Color(0xFF4F46E5); // Indigo
  static const primaryDark = Color(0xFF3730A3);
  static const bgPage      = Color(0xFFF8F9FC);
  static const bgCard      = Colors.white;
  static const border      = Color(0xFFE8ECF4);

  // Status
  static const sOpen     = Color(0xFF059669); // emerald
  static const sClosed   = Color(0xFFDC2626); // red
  static const sAnalysis = Color(0xFF0284C7); // sky
  static const sYet      = Color(0xFFD97706); // amber

  static const sOpenBg     = Color(0xFFD1FAE5);
  static const sClosedBg   = Color(0xFFFEE2E2);
  static const sAnalysisBg = Color(0xFFDBEAFE);
  static const sYetBg      = Color(0xFFFEF3C7);
}

// ── Status extension ──────────────────────────────────────────────────────────

extension StatusStyle on TestStatus {
  Color get color {
    switch (this) {
      case TestStatus.open:      return _C.sOpen;
      case TestStatus.closed:    return _C.sClosed;
      case TestStatus.analysis:  return _C.sAnalysis;
      case TestStatus.yetToOpen: return _C.sYet;
    }
  }

  Color get bgColor {
    switch (this) {
      case TestStatus.open:      return _C.sOpenBg;
      case TestStatus.closed:    return _C.sClosedBg;
      case TestStatus.analysis:  return _C.sAnalysisBg;
      case TestStatus.yetToOpen: return _C.sYetBg;
    }
  }

  String get label {
    switch (this) {
      case TestStatus.open:      return 'Open';
      case TestStatus.closed:    return 'Closed';
      case TestStatus.analysis:  return 'Analysis';
      case TestStatus.yetToOpen: return 'Yet to Open';
    }
  }

  IconData get icon {
    switch (this) {
      case TestStatus.open:      return Icons.lock_open_rounded;
      case TestStatus.closed:    return Icons.lock_rounded;
      case TestStatus.analysis:  return Icons.bar_chart_rounded;
      case TestStatus.yetToOpen: return Icons.schedule_rounded;
    }
  }
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

  static const _labels = ['Most Recent', 'Six Months', 'One Year', 'Two Years','Three Years','Four Years'];
  static const _data   = [_mostRecent, _sixMonths, _oneYear, _twoYears,<TestItem>[],<TestItem>[]];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tab.dispose();
    _testIdCtrl.dispose();
    _passcodeCtrl.dispose();
    super.dispose();
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
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _gridView()),
              _Sidebar(testIdCtrl: _testIdCtrl, passcodeCtrl: _passcodeCtrl),
            ])
                : Column(children: [
              Expanded(child: _gridView()),
              _Sidebar(testIdCtrl: _testIdCtrl, passcodeCtrl: _passcodeCtrl),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _gridView() {
    return TabBarView(
      controller: _tab,
      children: List.generate(6, (i) => _TestGrid(items: _data[i])),
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
            // Nav row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  // Logo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Exam app',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const Spacer()
                ],
              ),
            ),
            // Tabs
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

class _TestGrid extends StatelessWidget {
  final List<TestItem> items;
  const _TestGrid({required this.items});

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
        itemCount: items.length,
        itemBuilder: (_, i) => _TestCard(item: items[i]),
      );
    });
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  final TestItem item;
  const _TestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final s = item.status;
    return InkWell(
      onTap: () {
        Get.put(TopicAssignmentsController());
        Get.toNamed(
          AppRoutes.assignmentInstructions,
          arguments: {
            'subtopicId': "5",
            'columnKey': '',
            'testId': '545',
            'selectedQuestion': {},
          },
        );
      },
      child: Container(
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
            // Colored top strip
            Container(
              height: 5,
              color: s.color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: ID + status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Test ID chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.bgPage,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _C.border),
                          ),
                          child: Text(
                            '#${item.testId}',
                            style: TextStyle(
                              color: s.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Status pill
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
                    // Details text
                    Expanded(
                      child: Text(
                        item.details,
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
                    const SizedBox(height: 8),
                    // Divider
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
                    // Date row
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 11, color: Color(0xFFADB5C7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.openFrom,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFFCBD5E1)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.openTill,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            textAlign: TextAlign.right,
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
    );
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
            // ── Legend ──
            _sectionLabel('LEGEND'),
            const SizedBox(height: 10),
            ...TestStatus.values.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: s.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s.icon, color: s.color, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.label,
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
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE8ECF4)),
            const SizedBox(height: 20),

            // ── Download panel ──
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

            // Download button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Download Test',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: _C.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            testIdCtrl.text.isEmpty
                                ? 'Please enter a Test ID'
                                : 'Downloading: ${testIdCtrl.text}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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