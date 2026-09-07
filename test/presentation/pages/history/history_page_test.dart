import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/audio_player_handler.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/history/history_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/pages/history/history_page.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  group('HistoryPage screenshots', () {
    for (final size in _viewports) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets(
            '${size.width.toInt()}x${size.height.toInt()} $mode scale-$scale',
            (tester) async {
              await _setViewport(tester, size, textScale: scale);
              await _pumpHistory(tester, _successState, themeMode: mode);
              expect(tester.takeException(), isNull);
              final brightness = mode == ThemeMode.light ? 'light' : 'dark';
              await _capture(
                tester,
                'history-${size.width.toInt()}x${size.height.toInt()}-$brightness-scale-$scale',
              );
            },
          );
        }
      }
    }
  });
}

Future<void> _pumpHistory(
  WidgetTester tester,
  HistoryState state, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final historyCubit = _MockHistoryCubit()..show(state);
  final playerCubit = _MockPlayerCubit();
  final mediaSourceResolver = CustomMediaSourceResolver();
  final settingsCubit = AppSettingsCubit(
    _MockSettingsRepository(),
    mediaSourceResolver,
  );
  addTearDown(() {
    historyCubit.close();
    playerCubit.close();
    settingsCubit.close();
  });
  await tester.pumpWidget(
    RepositoryProvider<CustomMediaSourceResolver>.value(
      value: mediaSourceResolver,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HistoryCubit>.value(value: historyCubit),
          BlocProvider<PlayerCubit>.value(value: playerCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: RepaintBoundary(
            key: const ValueKey('history-capture'),
            child: HistoryPage(cubit: historyCubit),
          ),
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
  if (Platform.environment['CAPTURE_HISTORY_SCREENSHOTS'] != 'true') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('history-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Unable to encode history screenshot');
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

final _successState = HistoryState(
  status: HistoryStatus.success,
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
    isFavorite: false,
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

// Mock HistoryCubit
class _MockHistoryCubit extends Cubit<HistoryState> implements HistoryCubit {
  _MockHistoryCubit() : super(const HistoryState.initial());

  void show(HistoryState state) => emit(state);

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<List<MusicTrack>> fetchAllTracks({int limit = 500}) async =>
      state.tracks.take(limit).toList();
}

// Mock PlayerCubit
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
}

// Minimal mocks
class _MockMusicRepository implements MusicRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockSettingsRepository implements SettingsRepository {
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
