import 'dart:math' as math;

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/infrastructure/network/subsonic_api_client.dart';
import 'package:cross_platform_music_player/infrastructure/persistence/auth_session_store.dart';

class SubsonicMusicRepository implements MusicRepository {
  SubsonicMusicRepository({
    required SubsonicApiClient client,
    required AuthSessionStore sessionStore,
    required CustomMediaSourceResolver mediaSourceResolver,
  }) : _client = client,
       _sessionStore = sessionStore,
       _mediaSourceResolver = mediaSourceResolver;

  final SubsonicApiClient _client;
  final AuthSessionStore _sessionStore;
  final CustomMediaSourceResolver _mediaSourceResolver;

  AuthSession? _cachedSession;

  @override
  Future<AuthSession?> restoreSession() async {
    if (_cachedSession != null) {
      return _cachedSession!.backendType == MusicBackendType.navidrome
          ? _cachedSession
          : null;
    }

    final session = await _sessionStore.read();
    if (session == null || session.backendType != MusicBackendType.navidrome) {
      return null;
    }
    _cachedSession = session;
    return session;
  }

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final session = await _client.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    await _sessionStore.save(session);
    _cachedSession = session;
    return session;
  }

  @override
  Future<void> logout() async {
    final session = await restoreSession();
    if (session == null) return;
    _cachedSession = null;
    await _sessionStore.clear();
  }

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async {
    return _client.fetchLatestAlbums(await _requireSession(), limit: limit);
  }

  @override
  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6}) async {
    return _client.fetchRandomAlbums(await _requireSession(), limit: limit);
  }

  @override
  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final tracks = await _client.fetchTracks(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
    return PaginatedResult(items: tracks);
  }

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return _client.fetchAlbums(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async {
    return _client.fetchArtists(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
      genreId: genreId,
    );
  }

  @override
  Future<List<Genre>> fetchGenres() async {
    return _client.fetchGenres(await _requireSession());
  }

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    return _client.fetchPlaylists(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async {
    return _client.fetchAlbumTracks(await _requireSession(), albumId);
  }

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async {
    return _client.fetchPlaylistTracks(
      await _requireSession(),
      playlistId,
      limit: limit,
      startIndex: startIndex,
    );
  }

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async {
    return _client.buildStreamUrl(
      await _requireSession(),
      trackId,
      quality: quality,
    );
  }

  @override
  Future<void> setFavorite(String itemId, bool value) async {
    await _client.setFavorite(await _requireSession(), itemId, value);
  }

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) async {
    final session = await _requireSession();
    final song = await _client.fetchSong(session, trackId);
    final title = (song?['title'] as String?)?.trim();
    final artistName = _resolveArtistName(song);
    final albumTitle = (song?['album'] as String?)?.trim();
    final totalDuration = Duration(seconds: _readInt(song?['duration']));

    return _mediaSourceResolver.fetchLyrics(
      trackId: trackId,
      title: title,
      artistName: artistName,
      albumTitle: albumTitle,
      fallback: () async {
        final rawLyrics = await _client.fetchLyricsText(
          session,
          title: title,
          artist: artistName,
        );
        return _parseBuiltInLyrics(rawLyrics, totalDuration: totalDuration);
      },
    );
  }

  @override
  Future<void> reportPlaybackStart(String trackId, String playSessionId) async {
    await _client.scrobble(
      await _requireSession(),
      trackId,
      submission: false,
      playedAt: DateTime.now(),
    );
  }

  @override
  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) async {
    // Navidrome / Subsonic 不需要周期性进度上报；真正记播放由 scrobble(submission=true) 完成。
  }

  @override
  Future<void> reportPlaybackStopped(
    String trackId,
    String playSessionId,
    Duration position,
  ) async {
    await _client.scrobble(
      await _requireSession(),
      trackId,
      submission: true,
      playedAt: DateTime.now(),
    );
  }

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async {
    return _client.fetchRecentlyPlayed(await _requireSession(), limit: limit);
  }

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async {
    return _client.fetchMostPlayed(await _requireSession(), limit: limit);
  }

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async {
    return _client.fetchFavoriteTracks(
      await _requireSession(),
      limit: limit,
      startIndex: startIndex,
    );
  }

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async {
    return _client.fetchArtistAlbums(await _requireSession(), artistId);
  }

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async {
    return _client.fetchArtistTopTracks(
      await _requireSession(),
      artistId,
      limit: limit,
    );
  }

  @override
  Future<SearchResults> search(String query) async {
    return _client.search(await _requireSession(), query);
  }

  Future<AuthSession> _requireSession() async {
    final session = await restoreSession();
    if (session == null) {
      throw StateError('当前没有可用的 Navidrome 会话，请先登录。');
    }
    return session;
  }

  String? _resolveArtistName(Map<String, dynamic>? song) {
    if (song == null) return null;
    final displayArtist = (song['displayArtist'] as String?)?.trim();
    if (displayArtist != null && displayArtist.isNotEmpty) {
      return displayArtist;
    }
    final artist = (song['artist'] as String?)?.trim();
    if (artist != null && artist.isNotEmpty) {
      return artist;
    }
    final artists = song['artists'];
    if (artists is List && artists.isNotEmpty) {
      final first = artists.first;
      if (first is Map<String, dynamic>) {
        final name = (first['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }
    return null;
  }

  List<LyricLine>? _parseBuiltInLyrics(
    String? rawLyrics, {
    required Duration totalDuration,
  }) {
    final raw = rawLyrics?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    final lrcLines = _parseLrcLyrics(raw);
    if (lrcLines.isNotEmpty) {
      return lrcLines;
    }

    final textLines = raw
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (textLines.isEmpty) {
      return null;
    }

    if (textLines.length == 1) {
      return [LyricLine(start: Duration.zero, text: textLines.first)];
    }

    final fallbackStepMs = totalDuration.inMilliseconds > 0
        ? math.max(totalDuration.inMilliseconds ~/ textLines.length, 1500)
        : 3000;

    return [
      for (var i = 0; i < textLines.length; i++)
        LyricLine(
          start: Duration(milliseconds: fallbackStepMs * i),
          text: textLines[i],
        ),
    ];
  }

  List<LyricLine> _parseLrcLyrics(String raw) {
    final lines = <LyricLine>[];
    final rows = raw.split(RegExp(r'\r?\n'));
    final offset = _parseLrcOffset(rows);
    for (final row in rows) {
      final matches = _lrcTimestampPattern.allMatches(row).toList();
      if (matches.isEmpty) continue;
      final text = row.replaceAll(_lrcTimestampPattern, '').trim();
      if (text.isEmpty) continue;
      for (final match in matches) {
        final timestamp = match.group(1);
        final duration = timestamp == null ? null : _parseTimestamp(timestamp);
        if (duration == null) continue;
        lines.add(
          LyricLine(start: _applyLrcOffset(duration, offset), text: text),
        );
      }
    }
    lines.sort((a, b) => a.start.compareTo(b.start));
    return lines;
  }

  Duration _applyLrcOffset(Duration duration, Duration offset) {
    final shifted = duration + offset;
    if (shifted.isNegative) {
      return Duration.zero;
    }
    return shifted;
  }

  Duration _parseLrcOffset(List<String> rows) {
    for (final row in rows) {
      final match = _lrcOffsetPattern.firstMatch(row);
      if (match == null) continue;
      final rawOffset = match.group(1);
      if (rawOffset == null) continue;
      final offsetMs = int.tryParse(rawOffset.trim());
      if (offsetMs != null) {
        return Duration(milliseconds: offsetMs);
      }
    }
    return Duration.zero;
  }

  Duration? _parseTimestamp(String raw) {
    final trimmed = raw.trim().replaceAll(',', '.');
    final match = _timestampPattern.firstMatch(trimmed);
    if (match == null) return null;

    final minutes = int.tryParse(match.group(1) ?? '');
    final seconds = int.tryParse(match.group(2) ?? '');
    final fraction = match.group(3) ?? '0';
    if (minutes == null || seconds == null) return null;

    var milliseconds = 0;
    if (fraction.isNotEmpty) {
      if (fraction.length == 1) {
        milliseconds = int.parse(fraction) * 100;
      } else if (fraction.length == 2) {
        milliseconds = int.parse(fraction) * 10;
      } else {
        milliseconds = int.parse(fraction.substring(0, 3));
      }
    }

    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  static final RegExp _lrcTimestampPattern = RegExp(
    r'\[(\d{1,2}:\d{1,2}(?:[\.:]\d{1,3})?)\]',
  );
  static final RegExp _lrcOffsetPattern = RegExp(
    r'^\s*\[offset:([+-]?\d+)]\s*$',
    caseSensitive: false,
  );
  static final RegExp _timestampPattern = RegExp(
    r'^(\d{1,2}):(\d{1,2})(?:[\.:](\d{1,3}))?$',
  );
}
