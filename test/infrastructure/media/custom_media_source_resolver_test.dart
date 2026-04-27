import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomMediaSourceResolver artwork source', () {
    test('uses custom artwork url as primary when switch is enabled', () {
      final resolver = CustomMediaSourceResolver(
        initialSettings: const AppSettingsSnapshot(
          customArtworkSourceEnabled: true,
          customArtworkSourceUrl:
              'https://img.example.com/cover/{trackId}?artist={artist}&source={sourceUrl}&size={size}',
        ),
      );
      final track = MusicTrack(
        id: 'track-001',
        title: 'First Light',
        artistName: 'Nova',
        albumTitle: 'Galaxy',
        artworkUrl: 'https://emby.example.com/items/track-001/art.jpg',
        duration: const Duration(minutes: 3),
        albumId: 'album-001',
        artistId: 'artist-001',
      );

      final resolved = resolver.resolveArtworkSource(
        fallbackUrl: track.artworkUrl,
        context: ArtworkSourceContext.track(track),
        size: 640,
      );

      expect(resolved.usingCustomSource, isTrue);
      expect(resolved.primaryUrl, startsWith('https://img.example.com/cover/track-001'));
      expect(resolved.primaryUrl, contains('artist=Nova'));
      expect(
        resolved.primaryUrl,
        contains(
          'source=https%3A%2F%2Femby.example.com%2Fitems%2Ftrack-001%2Fart.jpg',
        ),
      );
      expect(resolved.primaryUrl, contains('size=640'));
      expect(resolved.fallbackUrl, track.artworkUrl);
      expect(resolved.hasFallback, isTrue);
    });

    test('uses built-in artwork directly when custom switch is disabled', () {
      final resolver = CustomMediaSourceResolver(
        initialSettings: const AppSettingsSnapshot(
          customArtworkSourceEnabled: false,
          customArtworkSourceUrl: 'https://img.example.com/cover/{trackId}',
        ),
      );

      final resolved = resolver.resolveArtworkSource(
        fallbackUrl: 'https://emby.example.com/items/track-001/art.jpg',
      );

      expect(resolved.usingCustomSource, isFalse);
      expect(
        resolved.primaryUrl,
        'https://emby.example.com/items/track-001/art.jpg',
      );
      expect(
        resolved.fallbackUrl,
        'https://emby.example.com/items/track-001/art.jpg',
      );
      expect(resolved.hasFallback, isFalse);
    });

    test('falls back to built-in artwork when custom switch is on but address is empty', () {
      final resolver = CustomMediaSourceResolver(
        initialSettings: const AppSettingsSnapshot(
          customArtworkSourceEnabled: true,
          customArtworkSourceUrl: '   ',
        ),
      );

      final resolved = resolver.resolveArtworkSource(
        fallbackUrl: 'https://emby.example.com/items/track-001/art.jpg',
      );

      expect(resolved.usingCustomSource, isFalse);
      expect(
        resolved.primaryUrl,
        'https://emby.example.com/items/track-001/art.jpg',
      );
    });
  });

  group('CustomMediaSourceResolver lyrics source', () {
    test('uses built-in lyrics fallback when custom lyrics switch is disabled', () async {
      final resolver = CustomMediaSourceResolver(
        initialSettings: const AppSettingsSnapshot(
          customLyricsSourceEnabled: false,
          customLyricsSourceUrl: 'https://lyrics.example.com/{trackId}',
        ),
      );
      var fallbackCalled = false;

      final lyrics = await resolver.fetchLyrics(
        trackId: 'track-001',
        fallback: () async {
          fallbackCalled = true;
          return const [
            LyricLine(start: Duration.zero, text: 'hello world'),
          ];
        },
      );

      expect(fallbackCalled, isTrue);
      expect(lyrics, isNotNull);
      expect(lyrics, hasLength(1));
      expect(lyrics!.first.text, 'hello world');
    });

    test('uses built-in lyrics fallback when custom lyrics address is empty', () async {
      final resolver = CustomMediaSourceResolver(
        initialSettings: const AppSettingsSnapshot(
          customLyricsSourceEnabled: true,
          customLyricsSourceUrl: ' ',
        ),
      );
      var fallbackCalled = false;

      final lyrics = await resolver.fetchLyrics(
        trackId: 'track-001',
        fallback: () async {
          fallbackCalled = true;
          return const [
            LyricLine(start: Duration.zero, text: 'fallback lyric'),
          ];
        },
      );

      expect(fallbackCalled, isTrue);
      expect(lyrics, isNotNull);
      expect(lyrics!.first.text, 'fallback lyric');
    });
  });
}
