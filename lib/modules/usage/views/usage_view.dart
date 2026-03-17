import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/routes/app_routes.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';
import 'package:suguna_exam_app/core/utils/responsive_helper.dart';
import 'package:suguna_exam_app/core/widgets/app_layout.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UsageView extends StatefulWidget {
  const UsageView({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UsageView();
  }
}

class _UsageView extends State<UsageView> {
  String htmlString = '';
  WebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedRoute: AppRoutes.usage,
      subjectName: "Usage",
      // showBackButton: true,
      showSidebar: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return webViewController== null ? CircularProgressIndicator() : WebViewWidget(controller: webViewController!);
          // if (ResponsiveHelper.isTablet(context)) {
          //   return _buildTabletLayout(context);
          // } else {
          //   return _buildMobileLayout(context);
          // }
        },
      ),
    );
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  Future<void> loadData() async {
    htmlString = await loadHtml();
    setState(() {
      webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(htmlString);
    });
  }

  Future<String> loadHtml() async {
    return await rootBundle.loadString('assets/usage.html');
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white,
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Please read the following instructions carefully",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Text("View In: "),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: "English",
                      items: const [
                        DropdownMenuItem(
                          value: "English",
                          child: Text("English"),
                        ),
                      ],
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= GENERAL INSTRUCTIONS =================
                    _sectionTitle("General Instructions:"),

                    const SizedBox(height: 12),

                    _bulletText(
                      "1. The clock has been set at the server and the countdown timer at the top right corner of your screen will display the time remaining for you to complete the exam. When the clock runs out the exam ends by default - you are not required to end or submit your exam.",
                    ),

                    _bulletText(
                      "2. The question palette at the right of screen shows one of the following statuses of each of the questions numbered:",
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "The Marked for Review status simply acts as a reminder that you have set to look at the question again. If an answer is selected for a question that is Marked for Review, the answer will be considered in the final evaluation.",
                      style: TextStyle(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ================= NAVIGATION =================
                    _sectionTitle("Navigating to a question:"),

                    const SizedBox(height: 12),

                    _bulletText(
                      "4. To select a question to answer, you can do one of the following:",
                    ),

                    _subBulletText(
                      "a. Click on the question number on the question palette at the right of your screen to go to that numbered question directly. Note that using this option does NOT save your answer to the current question.",
                    ),

                    _subBulletText(
                      "b. Click on Save and Next to save answer to current question and to go to the next question in sequence.",
                    ),

                    _subBulletText(
                      "c. Click on Mark for Review and Next to save answer to current question, mark it for review, and to go to the next question in sequence.",
                    ),

                    _bulletText(
                      "5. You can view the entire paper by clicking on the Question Paper button.",
                    ),

                    const SizedBox(height: 28),

                    // ================= ANSWERING =================
                    _sectionTitle("Answering questions:"),

                    const SizedBox(height: 12),

                    _bulletText("6. For multiple choice type question:"),

                    _subBulletText(
                      "a. To select your answer, click on one of the option buttons.",
                    ),
                    _subBulletText(
                      "b. To change your answer, click the another desired option button",
                    ),
                    _subBulletText(
                      "c. To save your answer, you MUST click on Save & Next",
                    ),
                    _subBulletText(
                      "d. To deselect a chosen answer, click on the chosen option again or click on the Clear Response button.",
                    ),
                    _subBulletText(
                      "e. To mark a question for review click on Mark for Review & Next.",
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "7. To change an answer to a question, first select the question and then click on the new answer option followed by a click on the Save & Next button.",
                      style: TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "8. Questions that are saved or marked for review after answering will ONLY be considered for evaluation.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _subBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(AppConstants.contentPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Legend',
              style: TextStyle(
                fontSize: AppConstants.sectionTitleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildLegendItem(context, AppColors.scoreRed, '0.0 - 2.0'),
            _buildLegendItem(context, AppColors.scoreOrange, '2.1 - 4.0'),
            _buildLegendItem(context, AppColors.scoreYellow, '4.1 - 7.0'),
            _buildLegendItem(context, AppColors.scoreLightGreen, '7.1 - 8.0'),
            _buildLegendItem(context, AppColors.scoreDarkGreen, '8.1 - 10.0'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String meaning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: AppConstants.circleSize,
            height: AppConstants.circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: AppColors.border, width: 1),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            meaning,
            style: const TextStyle(
              fontSize: AppConstants.normalTextSize,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
