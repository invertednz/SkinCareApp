import 'package:flutter/widgets.dart';
import '../services/analytics_service.dart';

class AnalyticsNavigatorObserver extends NavigatorObserver {
  void _send(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name ?? route.settings.toString();
    AnalyticsService.instance.screenView(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _send(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _send(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _send(newRoute);
  }
}
