import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/track_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  test(
    'prefetch resolves stream URL without creating player sources',
    () async {
      final repository = _StreamUrlCountingRepository();
      final resolver = TrackResolver(repository: repository);

      await resolver.prefetch(_track('track-1'), quality: AudioQuality.high);

      expect(repository.streamUrlCalls, 1);
      expect(repository.lastTrackId, 'track-1');
      expect(repository.lastQuality, AudioQuality.high);
    },
  );

  test('remote sources avoid per-source proxy headers', () async {
    final repository = _StreamUrlCountingRepository();
    final resolver = TrackResolver(repository: repository);

    final source = await resolver.resolve(
      _track('track-1', duration: const Duration(minutes: 3)),
    );

    expect(source, isA<ProgressiveAudioSource>());
    final remoteSource = source as ProgressiveAudioSource;
    expect(remoteSource.headers, isNull);
    expect(remoteSource.duration, const Duration(minutes: 3));
  });
}

MusicTrack _track(String id, {Duration duration = Duration.zero}) {
  return MusicTrack(
    id: id,
    title: id,
    artistName: 'artist',
    albumTitle: 'album',
    artworkUrl: '',
    duration: duration,
  );
}

class _StreamUrlCountingRepository extends Fake implements MusicRepository {
  int streamUrlCalls = 0;
  String? lastTrackId;
  AudioQuality? lastQuality;

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async {
    streamUrlCalls += 1;
    lastTrackId = trackId;
    lastQuality = quality;
    return 'https://example.com/$trackId';
  }
}
