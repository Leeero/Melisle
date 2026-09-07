import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Returns to the previous route when possible, otherwise opens [fallbackPath].
///
/// Detail routes live inside the library shell, so the nearest Navigator does
/// not always own the route history. Querying GoRouter keeps the decision on
/// the same navigation stack that performed the push.
void popDetailRouteOrGo(BuildContext context, String fallbackPath) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.go(fallbackPath);
}
