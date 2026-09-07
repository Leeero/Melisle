import 'package:cross_platform_music_player/presentation/utils/detail_route_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('returns to the route that opened a detail page', (tester) async {
    final router = _createRouter('/library?tab=albums');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byKey(const ValueKey('open-detail')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('detail-back')));
    await tester.pumpAndSettle();

    expect(find.text('媒体库：albums'), findsOneWidget);
    expect(find.text('详情页'), findsNothing);
  });

  testWidgets('uses the module fallback when a detail route has no history', (
    tester,
  ) async {
    final router = _createRouter('/artist/artist-1');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byKey(const ValueKey('detail-back')));
    await tester.pumpAndSettle();

    expect(find.text('媒体库：artists'), findsOneWidget);
  });

  testWidgets('returns direct playlist detail entries to the playlists tab', (
    tester,
  ) async {
    final router = _createRouter('/playlists/playlist-1');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byKey(const ValueKey('detail-back')));
    await tester.pumpAndSettle();

    expect(find.text('媒体库：playlists'), findsOneWidget);
  });
}

GoRouter _createRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/library',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'tracks';
          return Scaffold(
            body: Column(
              children: [
                Text('媒体库：$tab'),
                FilledButton(
                  key: const ValueKey('open-detail'),
                  onPressed: () => context.push('/album/album-1'),
                  child: const Text('打开详情'),
                ),
              ],
            ),
          );
        },
      ),
      GoRoute(
        path: '/album/:id',
        builder: (context, state) =>
            const _DetailBackButton(fallbackPath: '/library?tab=albums'),
      ),
      GoRoute(
        path: '/artist/:id',
        builder: (context, state) =>
            const _DetailBackButton(fallbackPath: '/library?tab=artists'),
      ),
      GoRoute(
        path: '/playlists/:id',
        builder: (context, state) =>
            const _DetailBackButton(fallbackPath: '/library?tab=playlists'),
      ),
    ],
  );
}

class _DetailBackButton extends StatelessWidget {
  const _DetailBackButton({required this.fallbackPath});

  final String fallbackPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('详情页'),
          FilledButton(
            key: const ValueKey('detail-back'),
            onPressed: () => popDetailRouteOrGo(context, fallbackPath),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
