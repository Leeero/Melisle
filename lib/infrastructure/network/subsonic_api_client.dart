import 'dart:convert';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class SubsonicApiClient {
  SubsonicApiClient(this._dio);

  final Dio _dio;
  final _playlistEntryCache =
      <String, _CacheEntry<List<Map<String, dynamic>>>>{};

  static const _apiVersion = '1.16.1';
  static const _clientName = AppConstants.apiClientName;
  static const _artistImageSize = 600;
  static const _playlistEntryCacheTtl = Duration(minutes: 3);

  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final normalizedServerUrl = _normalizeServerUrl(serverUrl);
    final payload = await _requestWithCredentials(
      normalizedServerUrl,
      username: username,
      password: password,
      method: 'ping',
    );

    final status = (payload['status'] as String? ?? '').trim().toLowerCase();
    if (status != 'ok') {
      throw const FormatException('Navidrome 登录失败：Subsonic ping 未返回成功状态。');
    }

    final resolvedUserName = await _fetchCurrentUserName(
      normalizedServerUrl,
      username: username,
      password: password,
    );

    return AuthSession(
      serverUrl: normalizedServerUrl,
      userId: username,
      userName: resolvedUserName ?? username,
      accessToken: password,
      backendType: MusicBackendType.navidrome,
    );
  }

  Future<Map<String, dynamic>?> fetchSong(
    AuthSession session,
    String trackId,
  ) async {
    final payload = await _request(
      session,
      'getSong',
      queryParameters: {'id': trackId},
    );
    return _asMap(payload['song']);
  }

  Future<String?> fetchLyricsText(
    AuthSession session, {
    required String? title,
    required String? artist,
  }) async {
    final safeTitle = title?.trim() ?? '';
    if (safeTitle.isEmpty) return null;

    final payload = await _request(
      session,
      'getLyrics',
      queryParameters: {
        'title': safeTitle,
        if ((artist?.trim().isNotEmpty ?? false)) 'artist': artist!.trim(),
      },
    );
    final lyrics = _asMap(payload['lyrics']);
    return (lyrics?['value'] as String?)?.trim();
  }

  Future<List<MusicAlbum>> fetchLatestAlbums(
    AuthSession session, {
    int limit = 12,
  }) {
    return fetchAlbumList(session, type: 'newest', limit: limit, startIndex: 0);
  }

  Future<List<MusicAlbum>> fetchAlbumList(
    AuthSession session, {
    required String type,
    int limit = 60,
    int startIndex = 0,
  }) async {
    final payload = await _request(
      session,
      'getAlbumList2',
      queryParameters: {'type': type, 'size': limit, 'offset': startIndex},
    );
    final albums = _readMaps(_asMap(payload['albumList2'])?['album']);
    return [
      for (final album in albums)
        _toMusicAlbum(session, album).copyWith(isFavorite: _isStarred(album)),
    ].where((album) => album.id.isNotEmpty).toList();
  }

  Future<List<MusicTrack>> fetchTracks(
    AuthSession session, {
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final payload = await _request(
      session,
      'search3',
      queryParameters: {
        'query': searchQuery?.trim() ?? '',
        'artistCount': 0,
        'albumCount': 0,
        'songCount': limit,
        'songOffset': startIndex,
      },
    );
    final songs = _readMaps(_asMap(payload['searchResult3'])?['song']);
    return [
      for (final song in songs)
        _toMusicTrack(session, song).copyWith(isFavorite: _isStarred(song)),
    ].where((track) => track.id.isNotEmpty).toList();
  }

  Future<List<MusicAlbum>> fetchAlbums(
    AuthSession session, {
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final query = searchQuery?.trim();
    if (query != null && query.isNotEmpty) {
      final payload = await _request(
        session,
        'search3',
        queryParameters: {
          'query': query,
          'artistCount': 0,
          'songCount': 0,
          'albumCount': limit,
          'albumOffset': startIndex,
        },
      );
      final albums = _readMaps(_asMap(payload['searchResult3'])?['album']);
      return [
        for (final album in albums)
          _toMusicAlbum(session, album).copyWith(isFavorite: _isStarred(album)),
      ].where((album) => album.id.isNotEmpty).toList();
    }

    return fetchAlbumList(
      session,
      type: 'alphabeticalByArtist',
      limit: limit,
      startIndex: startIndex,
    );
  }

  Future<List<MusicArtist>> fetchArtists(
    AuthSession session, {
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId, // Subsonic 不支持按 genre 筛选艺术家，忽略此参数
  }) async {
    final query = searchQuery?.trim();
    if (query != null && query.isNotEmpty) {
      final payload = await _request(
        session,
        'search3',
        queryParameters: {
          'query': query,
          'albumCount': 0,
          'songCount': 0,
          'artistCount': limit,
          'artistOffset': startIndex,
        },
      );
      final artists = _readMaps(_asMap(payload['searchResult3'])?['artist']);
      return [
        for (final artist in artists) _toMusicArtist(session, artist),
      ].where((artist) => artist.id.isNotEmpty).toList();
    }

    final payload = await _request(session, 'getArtists');
    final indices = _readMaps(_asMap(payload['artists'])?['index']);
    final flattened = <Map<String, dynamic>>[];
    for (final index in indices) {
      flattened.addAll(_readMaps(index['artist']));
    }
    final sliced = _slice(flattened, startIndex: startIndex, limit: limit);
    return [
      for (final artist in sliced) _toMusicArtist(session, artist),
    ].where((artist) => artist.id.isNotEmpty).toList();
  }

  Future<List<Genre>> fetchGenres(AuthSession session) async {
    final payload = await _request(session, 'getGenres');
    final genreList = _asMap(payload['genres']);
    if (genreList == null) return const [];
    final items = _readMaps(genreList['genre']);
    return items
        .map(
          (item) => Genre(
            id: (item['name'] as String? ?? '').trim(),
            name: (item['name'] as String? ?? '').trim(),
          ),
        )
        .where((g) => g.id.isNotEmpty)
        .toList();
  }

  Future<List<MusicPlaylist>> fetchPlaylists(
    AuthSession session, {
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final playlists = await _fetchPlaylistMaps(session);
    final filtered = _filterByQuery(
      playlists,
      searchQuery,
      labelOf: (item) => (item['name'] as String?) ?? '',
    );
    final sliced = _slice(filtered, startIndex: startIndex, limit: limit);
    return [
      for (final playlist in sliced) _toMusicPlaylist(session, playlist),
    ].where((playlist) => playlist.id.isNotEmpty).toList();
  }

  Future<List<MusicTrack>> fetchAlbumTracks(
    AuthSession session,
    String albumId,
  ) async {
    final payload = await _request(
      session,
      'getAlbum',
      queryParameters: {'id': albumId},
    );
    final songs = _readMaps(_asMap(payload['album'])?['song']);
    return [
      for (final song in songs)
        _toMusicTrack(session, song).copyWith(isFavorite: _isStarred(song)),
    ].where((track) => track.id.isNotEmpty).toList();
  }

  Future<List<MusicTrack>> fetchPlaylistTracks(
    AuthSession session,
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async {
    final entries = await _fetchPlaylistEntryMaps(session, playlistId);
    final sliced = limit == null
        ? entries
        : _slice(entries, startIndex: startIndex, limit: limit);
    return [
      for (final entry in sliced)
        _toMusicTrack(session, entry).copyWith(isFavorite: _isStarred(entry)),
    ].where((track) => track.id.isNotEmpty).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPlaylistMaps(
    AuthSession session,
  ) async {
    final payload = await _request(session, 'getPlaylists');
    return _readMaps(_asMap(payload['playlists'])?['playlist']);
  }

  Future<List<Map<String, dynamic>>> _fetchPlaylistEntryMaps(
    AuthSession session,
    String playlistId,
  ) async {
    final key = '${session.normalizedServerUrl}|${session.userId}|$playlistId';
    final cached = _playlistEntryCache[key];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.value;
    }

    final payload = await _request(
      session,
      'getPlaylist',
      queryParameters: {'id': playlistId},
    );
    final entries = _readMaps(_asMap(payload['playlist'])?['entry']);
    _playlistEntryCache[key] = _CacheEntry(
      value: entries,
      expiresAt: DateTime.now().add(_playlistEntryCacheTtl),
    );
    return entries;
  }

  String buildStreamUrl(
    AuthSession session,
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) {
    final params = <String, Object?>{'id': trackId};
    switch (quality) {
      case AudioQuality.auto:
      case AudioQuality.lossless:
        break;
      case AudioQuality.high:
        params['maxBitRate'] = 320;
        params['format'] = 'mp3';
        break;
      case AudioQuality.medium:
        params['maxBitRate'] = 192;
        params['format'] = 'mp3';
        break;
      case AudioQuality.low:
        params['maxBitRate'] = 128;
        params['format'] = 'mp3';
        break;
    }
    return _buildAuthenticatedUrl(
      serverUrl: session.normalizedServerUrl,
      username: session.userName,
      password: session.accessToken,
      method: 'stream',
      queryParameters: params,
      format: null,
    );
  }

  Future<void> setFavorite(
    AuthSession session,
    String itemId,
    bool value,
  ) async {
    await _request(
      session,
      value ? 'star' : 'unstar',
      queryParameters: {'id': itemId},
    );
  }

  Future<void> scrobble(
    AuthSession session,
    String trackId, {
    required bool submission,
    DateTime? playedAt,
  }) async {
    await _request(
      session,
      'scrobble',
      queryParameters: {
        'id': trackId,
        'submission': submission,
        'time': (playedAt ?? DateTime.now()).millisecondsSinceEpoch,
      },
    );
  }

  Future<List<MusicTrack>> fetchRecentlyPlayed(
    AuthSession session, {
    int limit = 30,
  }) {
    return _hydrateTracksFromAlbums(session, type: 'recent', limit: limit);
  }

  Future<List<MusicTrack>> fetchMostPlayed(
    AuthSession session, {
    int limit = 30,
  }) {
    return _hydrateTracksFromAlbums(session, type: 'frequent', limit: limit);
  }

  Future<List<MusicTrack>> fetchFavoriteTracks(
    AuthSession session, {
    int limit = 100,
    int startIndex = 0,
  }) async {
    final payload = await _request(session, 'getStarred2');
    final songs = _readMaps(_asMap(payload['starred2'])?['song']);
    final sliced = _slice(songs, startIndex: startIndex, limit: limit);
    return [
      for (final song in sliced)
        _toMusicTrack(session, song).copyWith(isFavorite: true),
    ].where((track) => track.id.isNotEmpty).toList();
  }

  Future<List<MusicAlbum>> fetchArtistAlbums(
    AuthSession session,
    String artistId,
  ) async {
    final payload = await _request(
      session,
      'getArtist',
      queryParameters: {'id': artistId},
    );
    final albums = _readMaps(_asMap(payload['artist'])?['album']);
    return [
      for (final album in albums)
        _toMusicAlbum(session, album).copyWith(isFavorite: _isStarred(album)),
    ].where((album) => album.id.isNotEmpty).toList();
  }

  Future<List<MusicTrack>> fetchArtistTopTracks(
    AuthSession session,
    String artistId, {
    int limit = 20,
  }) async {
    final artistPayload = await _request(
      session,
      'getArtist',
      queryParameters: {'id': artistId},
    );
    final artist = _asMap(artistPayload['artist']);
    final artistName = (artist?['name'] as String?)?.trim();
    if (artistName != null && artistName.isNotEmpty) {
      try {
        final topSongsPayload = await _request(
          session,
          'getTopSongs',
          queryParameters: {'artist': artistName, 'count': limit},
        );
        final songs = _readMaps(_asMap(topSongsPayload['topSongs'])?['song']);
        if (songs.isNotEmpty) {
          return [
            for (final song in songs)
              _toMusicTrack(
                session,
                song,
              ).copyWith(isFavorite: _isStarred(song)),
          ].where((track) => track.id.isNotEmpty).toList();
        }
      } catch (_) {
        // Navidrome 上该接口可能依赖 Last.fm；失败时回退到专辑遍历。
      }
    }

    final albums = _readMaps(artist?['album']);
    final tracks = <MusicTrack>[];
    for (final album in albums) {
      final albumId = (album['id'] as String?)?.trim();
      if (albumId == null || albumId.isEmpty) continue;
      final albumTracks = await fetchAlbumTracks(session, albumId);
      tracks.addAll(albumTracks);
      if (tracks.length >= limit) break;
    }
    return tracks.take(limit).toList();
  }

  Future<SearchResults> search(AuthSession session, String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return SearchResults.empty;
    }

    final payload = await _request(
      session,
      'search3',
      queryParameters: {
        'query': trimmed,
        'artistCount': 12,
        'albumCount': 12,
        'songCount': 12,
      },
    );
    final result =
        _asMap(payload['searchResult3']) ?? const <String, dynamic>{};
    final artistMaps = _readMaps(result['artist']);
    final albumMaps = _readMaps(result['album']);
    final songMaps = _readMaps(result['song']);
    final playlists = await fetchPlaylists(
      session,
      limit: 12,
      startIndex: 0,
      searchQuery: trimmed,
    );

    return SearchResults(
      artists: [
        for (final artist in artistMaps) _toMusicArtist(session, artist),
      ].where((artist) => artist.id.isNotEmpty).toList(),
      albums: [
        for (final album in albumMaps)
          _toMusicAlbum(session, album).copyWith(isFavorite: _isStarred(album)),
      ].where((album) => album.id.isNotEmpty).toList(),
      tracks: [
        for (final song in songMaps)
          _toMusicTrack(session, song).copyWith(isFavorite: _isStarred(song)),
      ].where((track) => track.id.isNotEmpty).toList(),
      playlists: playlists,
    );
  }

  Future<List<MusicTrack>> _hydrateTracksFromAlbums(
    AuthSession session, {
    required String type,
    required int limit,
  }) async {
    final albumBatchSize = limit <= 12 ? 6 : 10;
    final albums = await fetchAlbumList(
      session,
      type: type,
      limit: albumBatchSize,
      startIndex: 0,
    );
    if (albums.isEmpty) return const [];

    final merged = <MusicTrack>[];
    final seen = <String>{};
    for (final album in albums) {
      final albumTracks = await fetchAlbumTracks(session, album.id);
      for (final track in albumTracks) {
        if (!seen.add(track.id)) continue;
        merged.add(track);
        if (merged.length >= limit) {
          return merged;
        }
      }
    }
    return merged;
  }

  MusicTrack _toMusicTrack(AuthSession session, Map<String, dynamic> json) {
    final id = (json['id'] as String? ?? '').trim();
    final title = (json['title'] as String? ?? '').trim();
    final artistName = _primaryArtistName(json) ?? '未知艺术家';
    final albumTitle = (json['album'] as String? ?? '').trim();
    final durationSeconds = _readInt(json['duration']);
    final playedAt = _parseDateTime(json['played']);
    return MusicTrack(
      id: id,
      title: title.isEmpty ? '未知曲目' : title,
      artistName: artistName,
      albumTitle: albumTitle,
      artworkUrl: _resolveArtworkUrl(session, json),
      duration: Duration(seconds: durationSeconds),
      albumId: (json['albumId'] as String?)?.trim(),
      artistId: _primaryArtistId(json),
      isFavorite: _isStarred(json),
      playCount: _readInt(json['playCount']),
      lastPlayedAt: playedAt,
      bitRate: _readIntOrNull(json['bitRate']),
      codec: _codecFromJson(json),
      container: (json['suffix'] as String?)?.trim(),
    );
  }

  MusicAlbum _toMusicAlbum(AuthSession session, Map<String, dynamic> json) {
    final id = (json['id'] as String? ?? '').trim();
    final title = (json['name'] as String? ?? '').trim();
    final artistName =
        (json['displayArtist'] as String?)?.trim() ??
        (json['artist'] as String?)?.trim() ??
        '未知艺术家';
    return MusicAlbum(
      id: id,
      title: title.isEmpty ? '未知专辑' : title,
      artistName: artistName,
      artworkUrl: _resolveArtworkUrl(session, json),
      trackCount: _readInt(json['songCount']),
      year: _readIntOrNull(json['year']),
      artistId: (json['artistId'] as String?)?.trim(),
      isFavorite: _isStarred(json),
    );
  }

  MusicArtist _toMusicArtist(AuthSession session, Map<String, dynamic> json) {
    final id = (json['id'] as String? ?? '').trim();
    final imageUrl = (json['artistImageUrl'] as String?)?.trim();
    final coverArtId = (json['coverArt'] as String?)?.trim();
    return MusicArtist(
      id: id,
      name: (json['name'] as String? ?? '').trim(),
      artworkUrl: imageUrl != null && imageUrl.isNotEmpty
          ? imageUrl
          : (coverArtId != null && coverArtId.isNotEmpty
                ? buildCoverArtUrl(session, coverArtId, size: _artistImageSize)
                : ''),
      albumCount: _readInt(json['albumCount']),
    );
  }

  MusicPlaylist _toMusicPlaylist(
    AuthSession session,
    Map<String, dynamic> json,
  ) {
    final id = (json['id'] as String? ?? '').trim();
    final coverArtId = (json['coverArt'] as String?)?.trim();
    return MusicPlaylist(
      id: id,
      name: (json['name'] as String? ?? '').trim(),
      artworkUrl: coverArtId != null && coverArtId.isNotEmpty
          ? buildCoverArtUrl(session, coverArtId)
          : '',
      trackCount: _readInt(json['songCount'] ?? json['entryCount']),
    );
  }

  String buildCoverArtUrl(AuthSession session, String coverArtId, {int? size}) {
    final queryParameters = <String, Object?>{'id': coverArtId};
    if (size != null) {
      queryParameters['size'] = size;
    }

    return _buildAuthenticatedUrl(
      serverUrl: session.normalizedServerUrl,
      username: session.userName,
      password: session.accessToken,
      method: 'getCoverArt',
      queryParameters: queryParameters,
      format: null,
    );
  }

  Future<Map<String, dynamic>> _request(
    AuthSession session,
    String method, {
    Map<String, Object?>? queryParameters,
  }) {
    return _requestWithCredentials(
      session.normalizedServerUrl,
      username: session.userName,
      password: session.accessToken,
      method: method,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _requestWithCredentials(
    String serverUrl, {
    required String username,
    required String password,
    required String method,
    Map<String, Object?>? queryParameters,
  }) async {
    final url = _buildAuthenticatedUrl(
      serverUrl: serverUrl,
      username: username,
      password: password,
      method: method,
      queryParameters: queryParameters,
      format: 'json',
    );

    final response = await _dio.get<Object?>(
      url,
      options: Options(
        headers: const {'User-Agent': AppConstants.httpUserAgent},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Navidrome 请求失败：HTTP ${response.statusCode ?? 'unknown'}',
        type: DioExceptionType.badResponse,
      );
    }

    return _unwrapSubsonicResponse(response.data);
  }

  Map<String, dynamic> _unwrapSubsonicResponse(Object? data) {
    final root = data is Map<String, dynamic>
        ? data
        : jsonDecode('$data') as Map<String, dynamic>;
    final payload = _asMap(root['subsonic-response']);
    if (payload == null) {
      throw const FormatException('Navidrome 响应缺少 subsonic-response。');
    }

    final status = (payload['status'] as String? ?? '').trim().toLowerCase();
    if (status == 'ok') {
      return payload;
    }

    final error = _asMap(payload['error']);
    final message = (error?['message'] as String?)?.trim();
    final code = error?['code'];
    throw StateError(
      'Navidrome 接口返回失败状态${code == null ? '' : '（$code）'}：${message ?? 'unknown error'}',
    );
  }

  String _buildAuthenticatedUrl({
    required String serverUrl,
    required String username,
    required String password,
    required String method,
    Map<String, Object?>? queryParameters,
    String? format = 'json',
  }) {
    final normalizedServerUrl = _normalizeServerUrl(serverUrl);
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final token = md5.convert(utf8.encode('$password$salt')).toString();
    final query = <String, Object?>{
      'u': username,
      't': token,
      's': salt,
      'v': _apiVersion,
      'c': _clientName,
      ...?queryParameters,
    };
    if (format != null) {
      query['f'] = format;
    }
    final uri = Uri.parse(
      '$normalizedServerUrl/rest/${method.trim()}.view',
    ).replace(queryParameters: _stringifyQueryParameters(query));
    return uri.toString();
  }

  Future<String?> _fetchCurrentUserName(
    String serverUrl, {
    required String username,
    required String password,
  }) async {
    try {
      final payload = await _requestWithCredentials(
        serverUrl,
        username: username,
        password: password,
        method: 'getUser',
        queryParameters: {'username': username},
      );
      final user = _asMap(payload['user']);
      final resolved = (user?['username'] as String?)?.trim();
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    } catch (_) {
      // Ignore and fall back to the submitted username.
    }
    return null;
  }

  String _normalizeServerUrl(String serverUrl) {
    var normalized = serverUrl.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String _resolveArtworkUrl(AuthSession session, Map<String, dynamic> json) {
    final direct = (json['artistImageUrl'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final coverArtId = (json['coverArt'] as String?)?.trim();
    if (coverArtId == null || coverArtId.isEmpty) {
      return '';
    }
    return buildCoverArtUrl(session, coverArtId);
  }

  String? _primaryArtistName(Map<String, dynamic> json) {
    final displayArtist = (json['displayArtist'] as String?)?.trim();
    if (displayArtist != null && displayArtist.isNotEmpty) {
      return displayArtist;
    }

    final artist = (json['artist'] as String?)?.trim();
    if (artist != null && artist.isNotEmpty) {
      return artist;
    }

    final artists = _readMaps(json['artists']);
    if (artists.isNotEmpty) {
      final name = (artists.first['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    return null;
  }

  String? _primaryArtistId(Map<String, dynamic> json) {
    final directId = (json['artistId'] as String?)?.trim();
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }

    final artists = _readMaps(json['artists']);
    if (artists.isNotEmpty) {
      final id = (artists.first['id'] as String?)?.trim();
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }

    final albumArtists = _readMaps(json['albumArtists']);
    if (albumArtists.isNotEmpty) {
      final id = (albumArtists.first['id'] as String?)?.trim();
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }

    return null;
  }

  String? _codecFromJson(Map<String, dynamic> json) {
    final contentType = (json['contentType'] as String?)?.trim();
    if (contentType != null && contentType.contains('/')) {
      return contentType.split('/').last;
    }
    return (json['suffix'] as String?)?.trim();
  }

  bool _isStarred(Map<String, dynamic> json) {
    final starred = json['starred'];
    if (starred is bool) return starred;
    if (starred is String) return starred.trim().isNotEmpty;
    return starred != null;
  }

  DateTime? _parseDateTime(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  int? _readIntOrNull(dynamic value) {
    if (value == null) return null;
    final parsed = _readInt(value);
    return parsed <= 0 ? null : parsed;
  }

  Map<String, String> _stringifyQueryParameters(Map<String, Object?> params) {
    return {
      for (final entry in params.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return {for (final entry in value.entries) '${entry.key}': entry.value};
    }
    return null;
  }

  List<Map<String, dynamic>> _readMaps(Object? value) {
    if (value is List) {
      return value.map(_asMap).whereType<Map<String, dynamic>>().toList();
    }
    final map = _asMap(value);
    if (map != null) {
      return [map];
    }
    return const [];
  }

  List<Map<String, dynamic>> _slice(
    List<Map<String, dynamic>> items, {
    required int startIndex,
    required int limit,
  }) {
    if (startIndex >= items.length) {
      return const [];
    }
    final end = (startIndex + limit).clamp(0, items.length);
    return items.sublist(startIndex, end);
  }

  List<Map<String, dynamic>> _filterByQuery(
    List<Map<String, dynamic>> items,
    String? rawQuery, {
    required String Function(Map<String, dynamic> item) labelOf,
  }) {
    final query = rawQuery?.trim().toLowerCase();
    if (query == null || query.isEmpty) {
      return items;
    }
    return items.where((item) {
      final label = labelOf(item).trim().toLowerCase();
      return label.contains(query);
    }).toList();
  }
}

class _CacheEntry<T> {
  const _CacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;
}
