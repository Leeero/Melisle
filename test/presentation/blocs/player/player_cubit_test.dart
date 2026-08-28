import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/audio_player_handler.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  group('PlayerCubit playback state machine', () {
    test('pause and resume preserve and continue position', () async {
      final repository = _PlaybackRepository();
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track]);
      controller.emitPosition(const Duration(seconds: 15));
      await pumpEventQueue();

      controller.emitZeroDuringPause = true;
      await cubit.togglePlayback();
      expect(cubit.state.position, const Duration(seconds: 15));
      expect(cubit.state.isPlaying, isFalse);

      await cubit.togglePlayback();
      controller.emitPosition(const Duration(seconds: 16));
      await pumpEventQueue();

      expect(cubit.state.position, const Duration(seconds: 16));
      expect(cubit.state.isPlaying, isTrue);
    });

    test(
      'buffering keeps the play control loading after position events',
      () async {
        final repository = _PlaybackRepository();
        final controller = _FakeAudioPlayerHandler();
        final cubit = PlayerCubit(
          repository: repository,
          controller: controller,
        );
        addTearDown(cubit.close);

        await cubit.playTracks([_track]);
        controller.currentPosition = const Duration(seconds: 20);
        controller.emitState(true, ProcessingState.buffering);
        controller.emitPosition(controller.currentPosition);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(controller.loadPositions, [Duration.zero]);
        expect(controller.playCalls, 1);
        expect(repository.streamUrlCalls, 1);
        expect(cubit.state.isPlaying, isTrue);
        expect(cubit.state.isLoading, isTrue);
      },
    );

    test('native null duration falls back to track metadata', () async {
      final repository = _PlaybackRepository();
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track]);
      controller.emitDuration(null);
      await pumpEventQueue();

      expect(cubit.state.duration, _track.duration);
    });

    test('active lyric changes exactly at its timestamp', () async {
      final repository = _PlaybackRepository(
        lyrics: const [
          LyricLine(start: Duration(seconds: 10), text: '第一句'),
          LyricLine(start: Duration(seconds: 20), text: '第二句'),
        ],
      );
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track]);
      await pumpEventQueue();
      controller.emitPosition(const Duration(seconds: 20));
      await pumpEventQueue();

      expect(cubit.state.currentLyricIndex, 1);
      expect(
        cubit.state.lyricSyncState.playbackPosition,
        const Duration(seconds: 20),
      );
      expect(cubit.state.lyrics[1].text, '第二句');
    });

    test('playback errors survive later position events', () async {
      final repository = _PlaybackRepository();
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track]);
      controller.emitPlaybackError(_track.id, StateError('decoder failed'));
      controller.emitPosition(const Duration(seconds: 3));
      await pumpEventQueue();

      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isPlaying, isFalse);
    });

    test(
      'natural completion advances despite metadata duration mismatch',
      () async {
        final repository = _PlaybackRepository();
        final controller = _FakeAudioPlayerHandler();
        final cubit = PlayerCubit(
          repository: repository,
          controller: controller,
        );
        addTearDown(cubit.close);

        await cubit.playTracks([_track, _track2]);
        controller.emitPosition(const Duration(minutes: 2, seconds: 40));
        controller.emitCompletion(_track.id);
        await pumpEventQueue(times: 20);

        expect(cubit.state.currentIndex, 1);
        expect(controller.loadedTrackIds, [_track.id, _track2.id]);
        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.isPlaying, isTrue);
        expect(
          repository.stoppedPositions[_track.id],
          const Duration(minutes: 2, seconds: 40),
        );
      },
    );

    test('stale completion from the previous source is ignored', () async {
      final repository = _PlaybackRepository();
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track, _track2]);
      await cubit.playIndex(1);
      controller.emitCompletion(_track.id);
      await pumpEventQueue(times: 10);

      expect(cubit.state.currentIndex, 1);
      expect(controller.loadedTrackIds, [_track.id, _track2.id]);
      expect(cubit.state.errorMessage, isNull);
    });

    test('completion of the last track stops without an error', () async {
      final repository = _PlaybackRepository();
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track]);
      controller.emitPosition(_track.duration);
      controller.emitState(true, ProcessingState.completed);
      controller.emitCompletion(_track.id);
      await pumpEventQueue(times: 10);

      expect(cubit.state.currentIndex, 0);
      expect(controller.loadedTrackIds, [_track.id]);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isPlaying, isFalse);
      expect(repository.stoppedPositions[_track.id], _track.duration);
    });

    test('loop-one completion reloads the same track', () async {
      final repository = _PlaybackRepository();
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track]);
      await cubit.setPlaybackMode(PlaybackModeOption.loopOne);
      controller.emitCompletion(_track.id);
      await pumpEventQueue(times: 20);

      expect(controller.loadedTrackIds, [_track.id, _track.id]);
      expect(cubit.state.currentIndex, 0);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isPlaying, isTrue);
    });

    test('stale playback errors do not stop the current track', () async {
      final repository = _PlaybackRepository();
      final controller = _FakeAudioPlayerHandler();
      final cubit = PlayerCubit(repository: repository, controller: controller);
      addTearDown(cubit.close);

      await cubit.playTracks([_track, _track2]);
      await cubit.playIndex(1);
      controller.emitPlaybackError(_track.id, StateError('stale failure'));
      await pumpEventQueue();

      expect(cubit.state.currentIndex, 1);
      expect(cubit.state.isPlaying, isTrue);
      expect(cubit.state.errorMessage, isNull);
    });
  });
}

const _track = MusicTrack(
  id: 'track-1',
  title: 'Track 1',
  artistName: 'Artist',
  albumTitle: 'Album',
  artworkUrl: '',
  duration: Duration(minutes: 3),
);

const _track2 = MusicTrack(
  id: 'track-2',
  title: 'Track 2',
  artistName: 'Artist',
  albumTitle: 'Album',
  artworkUrl: '',
  duration: Duration(minutes: 4),
);

class _PlaybackRepository extends Fake implements MusicRepository {
  _PlaybackRepository({this.lyrics});

  final List<LyricLine>? lyrics;
  int streamUrlCalls = 0;
  final Map<String, Duration> stoppedPositions = {};

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) {
    streamUrlCalls += 1;
    return Future.value('https://example.com/$trackId.mp3');
  }

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) async => lyrics;

  @override
  Future<void> reportPlaybackStart(
    String trackId,
    String playSessionId,
  ) async {}

  @override
  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) async {}

  @override
  Future<void> reportPlaybackStopped(
    String trackId,
    String playSessionId,
    Duration position,
  ) async {
    stoppedPositions[trackId] = position;
  }
}

class _FakeAudioPlayerHandler implements AudioPlayerHandler {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _stateController = StreamController<PlayerState>.broadcast();
  final _completionController = StreamController<String>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _errorController = StreamController<PlaybackFailure>.broadcast();

  final List<Duration> loadPositions = [];
  final List<String> loadedTrackIds = [];
  int playCalls = 0;
  int pauseCalls = 0;
  bool emitZeroDuringPause = false;
  bool _isPlaying = false;
  Duration currentPosition = Duration.zero;

  @override
  Future<void> Function()? onSkipNext;

  @override
  Future<void> Function()? onSkipPrevious;

  @override
  Future<void> Function(int index)? onSkipToIndex;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  @override
  Stream<String> get trackCompletionStream => _completionController.stream;

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  @override
  Stream<PlaybackFailure> get playbackErrorStream => _errorController.stream;

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isIdle => false;

  @override
  Duration get position => currentPosition;

  @override
  Future<void> loadOnly(
    AudioSource source, {
    Duration initialPosition = Duration.zero,
  }) async {
    loadPositions.add(initialPosition);
    final tag = source is IndexedAudioSource ? source.tag : null;
    if (tag is MusicTrack) {
      loadedTrackIds.add(tag.id);
    }
    currentPosition = initialPosition;
    emitState(false, ProcessingState.ready);
  }

  @override
  Future<void> play() async {
    playCalls += 1;
    emitState(true, ProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    if (emitZeroDuringPause) {
      emitPosition(Duration.zero);
      emitZeroDuringPause = false;
    }
    emitState(false, ProcessingState.ready);
  }

  void emitPosition(Duration position) {
    currentPosition = position;
    _positionController.add(position);
  }

  void emitDuration(Duration? duration) {
    _durationController.add(duration);
  }

  void emitState(bool playing, ProcessingState processingState) {
    _isPlaying = playing;
    _stateController.add(PlayerState(playing, processingState));
  }

  void emitPlaybackError(String trackId, Object error) {
    _isPlaying = false;
    _errorController.add(PlaybackFailure(trackId: trackId, error: error));
  }

  void emitCompletion(String trackId) {
    _completionController.add(trackId);
  }

  @override
  void publishQueue({
    required List<MusicTrack> tracks,
    required int currentIndex,
  }) {}

  @override
  Future<void> clearPlayback() async {}

  @override
  Future<void> dispose() async {
    await Future.wait([
      _positionController.close(),
      _durationController.close(),
      _stateController.close(),
      _completionController.close(),
      _volumeController.close(),
      _errorController.close(),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
