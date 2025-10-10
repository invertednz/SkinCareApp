import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildDietView(String assetPath) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..loadFlutterAsset(assetPath);
  return WebViewWidget(controller: controller);
}
