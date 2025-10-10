// Web implementation: render an iframe pointing to the asset path
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

final Map<String, bool> _registeredViews = {};

Widget buildDietView(String assetPath) {
  final viewType = 'diet-iframe-${assetPath.hashCode}';
  if (_registeredViews[viewType] != true) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final element = html.IFrameElement()
        ..src = assetPath
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      return element;
    });
    _registeredViews[viewType] = true;
  }
  return HtmlElementView(viewType: viewType);
}
