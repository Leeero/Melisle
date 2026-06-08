import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/audio/track_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefetch resolves stream URL without creating player sources', () async {
    final repository = _StreamUrlCountingRepository();
    final resolver = TrackResolver(repository: repository);

    await resolver.prefetch(_track('track-1'), quality: AudioQuality.high);

    expect(repository.streamUrlCalls, 1);
    expect(repository.lastTrackId, 'track-1');
    expect(repository.lastQuality, AudioQuality.high);
  });
}

MusicTrack _track(String id) {
  return MusicTrack(
    id: id,
    title: id,
    artistName: 'artist',
    albumTitle: 'album',
    artworkUrl: '',
    duration: Duration.zero,
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
