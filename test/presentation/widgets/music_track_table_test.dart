import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/widgets/cached_artwork.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';

void main() {
  testWidgets('MusicTrackTable row action has tooltip and touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [_track],
          onTrackTap: (_, _) {},
          onAddTrackToQueue: (_) {},
        ),
      ),
    );

    final addButton = find.byTooltip('加入队列');
    expect(addButton, findsOneWidget);
    expect(tester.getSize(addButton).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(addButton).height, greaterThanOrEqualTo(44));
  });

  testWidgets('MusicTrackTable uses placeholder for unknown duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: [_track.copyWith(duration: Duration.zero)],
          onTrackTap: (_, _) {},
        ),
      ),
    );

    expect(find.text('--:--'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
  });

  testWidgets('MusicTrackTable exposes stable desktop row actions', (
    tester,
  ) async {
    var playCount = 0;
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [_track],
          onTrackTap: (_, _) => playCount++,
          onAddTrackToQueue: (_) {},
        ),
      ),
    );

    expect(find.byTooltip('加入队列'), findsOneWidget);
    expect(find.byTooltip('更多操作'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('track-row-play-track-1')),
      findsOneWidget,
    );

    await tester.tap(find.text('夜曲'));
    await tester.pump();
    expect(playCount, 1);
  });

  testWidgets('library table renders quality and hover actions', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [
            MusicTrack(
              id: 'flac-track',
              title: 'Midnight City',
              artistName: 'M83',
              albumTitle: "Hurry Up, We're Dreaming",
              artworkUrl: '',
              duration: Duration(minutes: 4, seconds: 3),
              codec: 'flac',
            ),
          ],
          libraryStyle: true,
          onTrackTap: (_, _) {},
        ),
      ),
    );

    expect(find.text('全部歌曲'), findsOneWidget);
    expect(find.text('质量'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
    expect(find.byType(CachedArtwork), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(
      location: tester.getCenter(
        find.byKey(const ValueKey('track-row-play-flac-track')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('更多操作'), findsOneWidget);
    await gesture.removePointer();
  });

  testWidgets('library table prioritizes title and artist on narrow desktop', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [_track],
          libraryStyle: true,
          onTrackTap: (_, _) {},
        ),
      ),
    );

    expect(find.text('歌曲 / 艺术家'), findsOneWidget);
    expect(find.text('质量'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('track-row-play-track-1')))
          .height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('library table limits playback tap to the song identity area', (
    tester,
  ) async {
    var playCount = 0;
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [_track],
          libraryStyle: true,
          showActionBar: false,
          onTrackTap: (_, _) => playCount++,
        ),
      ),
    );

    await tester.tap(find.text(_track.albumTitle));
    await tester.pump();
    expect(playCount, 0);

    await tester.tap(find.text(_track.title));
    await tester.pump();
    expect(playCount, 1);
  });

  testWidgets('library table exposes one playback action per track', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [_track],
          libraryStyle: true,
          showActionBar: false,
          onTrackTap: (_, _) {},
        ),
      ),
    );

    final playAction = tester.getSemantics(
      find.byKey(const ValueKey('track-row-play-track-1')),
    );
    expect(playAction.label, contains('播放《夜曲》'));
    expect(
      playAction.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('library table supports compact display density', (tester) async {
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [_track],
          libraryStyle: true,
          showActionBar: false,
          density: MusicTrackTableDensity.compact,
          onTrackTap: (_, _) {},
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('track-row-play-track-1')))
          .height,
      lessThan(56),
    );
  });

  testWidgets('current track uses a distinct playing indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWidget(
        MusicTrackTable(
          tracks: const [_track],
          currentTrackId: _track.id,
          onTrackTap: (_, _) {},
        ),
      ),
    );

    expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}

Widget _buildWidget(Widget child) {
  final mediaSourceResolver = CustomMediaSourceResolver();
  final settingsCubit = AppSettingsCubit(
    _FakeSettingsRepository(),
    mediaSourceResolver,
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<CustomMediaSourceResolver>.value(
        value: mediaSourceResolver,
      ),
    ],
    child: BlocProvider<AppSettingsCubit>(
      create: (_) => settingsCubit,
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

const _track = MusicTrack(
  id: 'track-1',
  title: '夜曲',
  artistName: '周杰伦',
  albumTitle: '十一月的萧邦',
  artworkUrl: '',
  duration: Duration(minutes: 4),
);

class _FakeSettingsRepository implements SettingsRepository {
  AppSettingsSnapshot _snapshot = const AppSettingsSnapshot();

  @override
  Future<AppSettingsSnapshot> load() async => _snapshot;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    _snapshot = _snapshot.copyWith(themeMode: mode);
  }

  @override
  Future<void> saveDefaultQuality(AudioQuality quality) async {
    _snapshot = _snapshot.copyWith(defaultQuality: quality);
  }

  @override
  Future<void> saveGapBetweenTracks(Duration gap) async {
    _snapshot = _snapshot.copyWith(gapBetweenTracks: gap);
  }

  @override
  Future<void> saveLyricSyncOffset(Duration offset) async {
    _snapshot = _snapshot.copyWith(lyricSyncOffset: offset);
  }

  @override
  Future<void> saveMenuBarLyricsEnabled(bool enabled) async {
    _snapshot = _snapshot.copyWith(menuBarLyricsEnabled: enabled);
  }

  @override
  Future<void> saveCustomArtworkSourceEnabled(bool enabled) async {
    _snapshot = _snapshot.copyWith(customArtworkSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomArtworkSourceUrl(String url) async {
    _snapshot = _snapshot.copyWith(customArtworkSourceUrl: url);
  }

  @override
  Future<void> saveCustomLyricsSourceEnabled(bool enabled) async {
    _snapshot = _snapshot.copyWith(customLyricsSourceEnabled: enabled);
  }

  @override
  Future<void> saveCustomLyricsSourceUrl(String url) async {
    _snapshot = _snapshot.copyWith(customLyricsSourceUrl: url);
  }
}
