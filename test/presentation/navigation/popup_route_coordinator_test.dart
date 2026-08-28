import 'package:cross_platform_music_player/presentation/navigation/popup_route_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dismissPopups closes an active popup route', (tester) async {
    final coordinator = PopupRouteCoordinator();
    final observer = coordinator.createObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(_TestPopupRoute()),
              child: const Text('打开弹层'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();
    expect(find.text('弹层内容'), findsOneWidget);

    coordinator.dismissPopups();
    await tester.pumpAndSettle();

    expect(find.text('弹层内容'), findsNothing);
  });
}

class _TestPopupRoute extends PopupRoute<void> {
  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => '关闭';

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const Center(child: Material(child: Text('弹层内容')));
}
