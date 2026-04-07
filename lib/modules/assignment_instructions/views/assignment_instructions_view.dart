import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suguna_exam_app/modules/assignment_instructions/controllers/assignment_instructions_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/routes/app_routes.dart';

class AssignmentInstructionsView extends StatefulWidget {
  final bool startTest;
  const AssignmentInstructionsView({super.key, this.startTest = true});

  @override
  State<AssignmentInstructionsView> createState() =>
      _AssignmentInstructionsViewState();
}

class _AssignmentInstructionsViewState
    extends State<AssignmentInstructionsView> {
  late final AssignmentInstructionsController controller;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AssignmentInstructionsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWebView());
  }

  void _initWebView() {
    final html = controller.instructionContentHtml.value;
    if (html.isEmpty) return;
    final wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_wrapHtml(html));
    setState(() => _webController = wc);
  }

  String _wrapHtml(String body) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: sans-serif; font-size: 14px; color: #1E293B;
         margin: 0; padding: 8px 12px; line-height: 1.6; }
  p { margin: 0 0 8px 0; }
</style>
</head>
<body>$body</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.startTest) {
          Get.offAllNamed(AppRoutes.discussion);
        } else {
          Get.close(1);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ─────────────────────────────────────────────
                Obx(() {
                  final title = controller.instructionTitle.value;
                  if (title.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE8ECF4)),
                      const SizedBox(height: 16),
                    ],
                  );
                }),

                // ── HTML Content ──────────────────────────────────────
                Expanded(
                  child: Obx(() {
                    final html = controller.instructionContentHtml.value;
                    if (html.isEmpty) {
                      return const Center(
                        child: Text(
                          'No instructions available.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      );
                    }
                    if (_webController == null) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _initWebView());
                      return const Center(child: CircularProgressIndicator());
                    }
                    return WebViewWidget(controller: _webController!);
                  }),
                ),

                const SizedBox(height: 24),

                // ── Button ────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      backgroundColor: const Color(0xFF4F46E5),
                    ),
                    onPressed: () {
                      if (widget.startTest) {
                        controller.onAccept();
                      } else {
                        Get.close(1);
                      }
                    },
                    child: Text(
                      widget.startTest ? "Start Test" : "Close",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
