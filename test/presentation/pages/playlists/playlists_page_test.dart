import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/playlists/playlists_state.dart';
import 'package:cross_platform_music_player/presentation/pages/playlists/playlists_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaylistsPage screenshots', () {
    for (final size in _viewports) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets(
            '${size.width.toInt()}x${size.height.toInt()} $mode scale-$scale',
            (tester) async {
              await _setViewport(tester, size, textScale: scale);
              await _pumpPlaylists(tester, _successState, themeMode: mode);
              expect(tester.takeException(), isNull);
              expect(find.byType(AppPageHeader), findsNothing);
              final brightness = mode == ThemeMode.light ? 'light' : 'dark';
              await _capture(
                tester,
                'playlists-${size.width.toInt()}x${size.height.toInt()}-$brightness-scale-$scale',
              );
            },
          );
        }
      }
    }
  });
}

Future<void> _pumpPlaylists(
  WidgetTester tester,
  PlaylistsState state, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final playlistsCubit = _MockPlaylistsCubit()..show(state);
  addTearDown(playlistsCubit.close);
  await tester.pumpWidget(
    BlocProvider<PlaylistsCubit>.value(
      value: playlistsCubit,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const RepaintBoundary(
          key: ValueKey('playlists-capture'),
          child: PlaylistsPage(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _setViewport(
  WidgetTester tester,
  ui.Size size, {
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_PLAYLISTS_SCREENSHOTS'] != 'true') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('playlists-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('Unable to encode playlists screenshot');
    }
    final directory = Directory('design-reference/screenshots/actual');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  });
}

const _viewports = [
  ui.Size(375, 812),
  ui.Size(390, 844),
  ui.Size(768, 900),
  ui.Size(1080, 900),
  ui.Size(1440, 900),
];

final _successState = PlaylistsState(
  status: PlaylistsStatus.success,
  allPlaylists: _mockPlaylists,
  playlists: _mockPlaylists,
  hasMore: false,
);

final _mockPlaylists = [
  const MusicPlaylist(
    id: '1',
    name: '私人雷达',
    artworkUrl: 'https://example.com/playlist1.jpg',
    trackCount: 30,
  ),
  const MusicPlaylist(
    id: '2',
    name: '每日推荐',
    artworkUrl: 'https://example.com/playlist2.jpg',
    trackCount: 50,
  ),
  const MusicPlaylist(
    id: '3',
    name: '华语经典',
    artworkUrl: 'https://example.com/playlist3.jpg',
    trackCount: 100,
  ),
];

// Mock FetchPlaylists
class _MockFetchPlaylists implements FetchPlaylists {
  @override
  Future<List<MusicPlaylist>> call({int limit = 20, int startIndex = 0}) async =>
      [];
}

// Mock PlaylistsCubit with show method
class _MockPlaylistsCubit extends PlaylistsCubit {
  _MockPlaylistsCubit() : super(_MockFetchPlaylists());

  void show(PlaylistsState state) => emit(state);
}
