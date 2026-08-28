import 'package:flutter/material.dart';

/// Coordinates transient routes owned by persistent shell branches.
class PopupRouteCoordinator {
  final Set<PopupRouteObserver> _observers = {};

  PopupRouteObserver createObserver() {
    final observer = PopupRouteObserver._();
    _observers.add(observer);
    return observer;
  }

  /// Closes the active popup in every loaded branch before changing sections.
  void dismissPopups() {
    for (final observer in List<PopupRouteObserver>.of(_observers)) {
      observer.dismissPopup();
    }
  }
}

class PopupRouteObserver extends NavigatorObserver {
  PopupRouteObserver._();
  final List<Route<dynamic>> _routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _routes.remove(oldRoute);
    if (newRoute != null) _routes.add(newRoute);
  }

  void dismissPopup() {
    final navigator = this.navigator;
    if (navigator == null || _routes.isEmpty) return;
    if (_routes.last is PopupRoute<dynamic>) navigator.pop();
  }
}
