import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/audio_player_handler.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/pages/favorites/favorites_page.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FavoritesPage screenshots', () {
    for (final size in _viewports) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets(
            '${size.width.toInt()}x${size.height.toInt()} $mode scale-$scale',
            (tester) async {
              await _setViewport(tester, size, textScale: scale);
              await _pumpFavorites(tester, _successState, themeMode: mode);
              expect(tester.takeException(), isNull);
              final brightness = mode == ThemeMode.light ? 'light' : 'dark';
              await _capture(
                tester,
                'favorites-${size.width.toInt()}x${size.height.toInt()}-$brightness-scale-$scale',
              );
            },
          );
        }
      }
    }
  });

  testWidgets('当前播放的收藏歌曲只显示取消收藏按钮', (tester) async {
    await _setViewport(tester, const ui.Size(1080, 900));
    await _pumpFavorites(
      tester,
      _successState,
      currentTrack: _mockTracks.first,
    );

    final durationOpacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('3:30'),
        matching: find.byType(AnimatedOpacity),
      ),
    );

    expect(durationOpacity.opacity, 0);
    expect(find.byTooltip('取消收藏'), findsOneWidget);
  });
}

Future<void> _pumpFavorites(
  WidgetTester tester,
  FavoritesListState state, {
  ThemeMode themeMode = ThemeMode.light,
  MusicTrack? currentTrack,
}) async {
  final favoritesCubit = _MockFavoritesCubit();
  final favoritesListCubit = _MockFavoritesListCubit()..show(state);
  final playerCubit = _MockPlayerCubit();
  if (currentTrack != null) {
    playerCubit.showCurrentTrack(currentTrack);
  }
  addTearDown(() {
    favoritesCubit.close();
    favoritesListCubit.close();
    playerCubit.close();
  });
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
        BlocProvider<FavoritesListCubit>.value(value: favoritesListCubit),
        BlocProvider<PlayerCubit>.value(value: playerCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const RepaintBoundary(
          key: ValueKey('favorites-capture'),
          child: FavoritesPage(),
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
  if (Platform.environment['CAPTURE_FAVORITES_SCREENSHOTS'] != 'true') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('favorites-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Unable to encode favorites screenshot');
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

final _successState = FavoritesListState(
  status: FavoritesListStatus.success,
  tracks: _mockTracks,
  hasMore: false,
);

final _mockTracks = [
  MusicTrack(
    id: '1',
    title: '测试歌曲一',
    artistName: '测试歌手',
    albumTitle: '测试专辑',
    albumId: 'album-1',
    artistId: 'artist-1',
    duration: const Duration(minutes: 3, seconds: 30),
    artworkUrl: 'https://example.com/art1.jpg',
    isFavorite: true,
  ),
  MusicTrack(
    id: '2',
    title: '测试歌曲二',
    artistName: '另一位歌手',
    albumTitle: '另一张专辑',
    albumId: 'album-2',
    artistId: 'artist-2',
    duration: const Duration(minutes: 4, seconds: 15),
    artworkUrl: 'https://example.com/art2.jpg',
    isFavorite: true,
  ),
];

// Mock FavoritesCubit
class _MockFavoritesCubit extends FavoritesCubit {
  _MockFavoritesCubit() : super(_MockMusicRepository());

  @override
  bool isFavorite(String itemId, {bool fallback = false}) {
    return state.entries[itemId] ?? fallback;
  }

  @override
  void seed(String itemId, bool isFavorite) {
    final next = Map<String, bool>.from(state.entries)..[itemId] = isFavorite;
    emit(state.copyWith(entries: next));
  }

  @override
  void seedAll(Map<String, bool> map) {
    if (map.isEmpty) return;
    final next = Map<String, bool>.from(state.entries)..addAll(map);
    emit(state.copyWith(entries: next));
  }

  @override
  Future<bool> toggle(String itemId, {required bool currentValue}) async {
    final desired = !currentValue;
    final next = Map<String, bool>.from(state.entries)..[itemId] = desired;
    emit(state.copyWith(entries: next));
    return true;
  }
}

// Mock FavoritesListCubit
class _MockFavoritesListCubit extends FavoritesListCubit {
  _MockFavoritesListCubit()
      : super(_MockFetchFavoriteTracks(), _MockFavoritesCubit());

  void show(FavoritesListState state) => emit(state);

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async {}

  @override
  void removeTrack(String trackId) {
    final next = state.tracks.where((track) => track.id != trackId).toList();
    emit(state.copyWith(tracks: next));
  }
}

// Mock PlayerCubit - use noSuchMethod for simplicity
class _MockPlayerCubit extends PlayerCubit {
  _MockPlayerCubit()
      : super(
          repository: _MockMusicRepository(),
          controller: _MockAudioPlayerHandler(),
        );

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> toggle() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> seekToProgress(double progress) async {}

  @override
  Future<void> playTrack(MusicTrack track) async {}

  @override
  Future<void> playAlbum(String albumId, {int startIndex = 0}) async {}

  @override
  Future<void> playPlaylist(String playlistId, {int startIndex = 0}) async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> addToQueue(MusicTrack track) async {}

  @override
  Future<void> removeFromQueue(int index) async {}

  @override
  Future<void> clearQueue() async {}

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> toggleShuffle() async {}

  @override
  Future<void> cycleRepeatMode() async {}

  void showCurrentTrack(MusicTrack track) {
    emit(PlayerViewState(queue: [track]));
  }
}

// Minimal mocks for dependencies
class _MockMusicRepository implements MusicRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockFetchFavoriteTracks {
  Future<List<MusicTrack>> call({int limit = 100, int startIndex = 0}) async =>
      [];
}

class _MockAudioPlayerHandler implements AudioPlayerHandler {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
