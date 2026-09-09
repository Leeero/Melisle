import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/application/usecases/fetch_favorite_tracks.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/audio_player_handler.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_list_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/favorites/favorites_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('favorite-track-row-play-1')),
        matching: find.byTooltip('取消收藏'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('移动端收藏歌曲使用内容边距和低强调取消收藏操作', (tester) async {
    await _setViewport(tester, const ui.Size(390, 844));
    await _pumpFavorites(
      tester,
      _successState,
      currentTrack: _mockTracks.first,
    );

    expect(find.text('播放全部'), findsOneWidget);
    expect(find.textContaining('播放全部（'), findsNothing);

    final firstArtwork = tester.getRect(find.byType(CachedArtwork).first);
    expect(
      firstArtwork.left,
      greaterThanOrEqualTo(AppSpacingTokens.pageHorizontalCompact),
    );

    final favoriteIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byTooltip('取消收藏').first,
        matching: find.byIcon(Icons.favorite_rounded),
      ),
    );
    expect(favoriteIcon.color, AppTheme.light().colorScheme.onSurfaceVariant);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpFavorites(
  WidgetTester tester,
  FavoritesListState state, {
  ThemeMode themeMode = ThemeMode.light,
  MusicTrack? currentTrack,
}) async {
  final repository = _MockMusicRepository(tracks: state.tracks);
  final favoritesCubit = _MockFavoritesCubit();
  final favoritesListCubit = _MockFavoritesListCubit()..show(state);
  final playerCubit = _MockPlayerCubit();
  final mediaSourceResolver = CustomMediaSourceResolver();
  final settingsCubit = AppSettingsCubit(
    _MockSettingsRepository(),
    mediaSourceResolver,
  );
  if (currentTrack != null) {
    playerCubit.showCurrentTrack(currentTrack);
  }
  addTearDown(() {
    favoritesCubit.close();
    favoritesListCubit.close();
    playerCubit.close();
    settingsCubit.close();
  });
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicRepository>.value(value: repository),
        RepositoryProvider<CustomMediaSourceResolver>.value(
          value: mediaSourceResolver,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
          BlocProvider<FavoritesListCubit>.value(value: favoritesListCubit),
          BlocProvider<PlayerCubit>.value(value: playerCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: const RepaintBoundary(
            key: ValueKey('favorites-capture'),
            child: Scaffold(body: FavoritesPage()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
    if (bytes == null) {
      throw StateError('Unable to encode favorites screenshot');
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
    : super(FetchFavoriteTracks(_MockMusicRepository()), _MockFavoritesCubit());

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

  Future<void> play() async {}

  Future<void> pause() async {}

  Future<void> toggle() async {}

  Future<void> seekTo(Duration position) async {}

  Future<void> seekToProgress(double progress) async {}

  Future<void> playTrack(MusicTrack track) async {}

  Future<void> playAlbum(String albumId, {int startIndex = 0}) async {}

  Future<void> playPlaylist(String playlistId, {int startIndex = 0}) async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> addToQueue(MusicTrack track) async {}

  Future<void> removeFromQueue(int index) async {}

  @override
  Future<void> clearQueue() async {}

  Future<void> reorderQueue(int oldIndex, int newIndex) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> toggleShuffle() async {}

  Future<void> cycleRepeatMode() async {}

  void showCurrentTrack(MusicTrack track) {
    emit(PlayerViewState(queue: [track]));
  }
}

// Minimal mocks for dependencies
class _MockMusicRepository implements MusicRepository {
  _MockMusicRepository({this.tracks = const []});

  final List<MusicTrack> tracks;

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async => tracks;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockAudioPlayerHandler implements AudioPlayerHandler {
  @override
  Future<void> Function()? onSkipNext;

  @override
  Future<void> Function()? onSkipPrevious;

  @override
  Future<void> Function(int index)? onSkipToIndex;

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<PlaybackFailure> get playbackErrorStream => const Stream.empty();

  @override
  Stream<String> get trackCompletionStream => const Stream.empty();

  @override
  Stream<double> get volumeStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockSettingsRepository implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
