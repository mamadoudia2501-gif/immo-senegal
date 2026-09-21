import 'package:flutter/foundation.dart';

/// Court délai de chargement mock pour afficher un skeleton, sans backend.
class CatalogReady extends ChangeNotifier {
  CatalogReady({Duration delay = const Duration(milliseconds: 320)}) {
    if (delay <= Duration.zero) {
      ready = true;
    } else {
      Future<void>.delayed(delay, () {
        ready = true;
        notifyListeners();
      });
    }
  }

  bool ready = false;
}
