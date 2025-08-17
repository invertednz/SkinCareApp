import 'package:flutter/foundation.dart';

/// A ChangeNotifier that proxies multiple Listenables and re-emits
/// notifications when any of them changes. Useful for GoRouter.refreshListenable.
class MultiListenable extends ChangeNotifier {
  final List<Listenable> _sources = [];
  final List<VoidCallback> _detach = [];

  MultiListenable(List<Listenable> sources) {
    for (final s in sources) {
      addSource(s);
    }
  }

  void addSource(Listenable source) {
    _sources.add(source);
    void listener() => notifyListeners();
    source.addListener(listener);
    _detach.add(() => source.removeListener(listener));
  }

  @override
  void dispose() {
    for (final d in _detach) {
      d();
    }
    _detach.clear();
    _sources.clear();
    super.dispose();
  }
}
