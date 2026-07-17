import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:dio/dio.dart';

class EmbyApiClient {
  EmbyApiClient(this._dio);

  final Dio _dio;

  static const _clientName = AppConstants.apiClientName;
  static const _deviceName = AppConstants.appEnglishName;
  static const _deviceId = 'melisle';
  static const _appVersion = '1.0.0';

  /// 轻量歌曲字段：用于首页、媒体库、收藏和搜索，避免把 `MediaSources` 这种大字段一并拉下来。
  static const _trackListFields =
      'RunTimeTicks,Album,AlbumId,AlbumArtist,AlbumArtists,ArtistItems,PrimaryImageAspectRatio,UserData';

  /// 详情歌曲字段：在专辑 / 歌单等需要更完整元信息的场景再附带 `MediaSources`。
  static const _trackDetailFields =
      'RunTimeTicks,Album,AlbumId,AlbumArtist,AlbumArtists,ArtistItems,PrimaryImageAspectRatio,UserData,MediaSources';
  static const _albumFields =
      'PrimaryImageAspectRatio,ProductionYear,ChildCount,AlbumArtists,ArtistItems,UserData';
  static const _artistFields =
      'PrimaryImageAspectRatio,ChildCount,AlbumCount,AlbumItems,UserData';
  static const _playlistFields =
      'PrimaryImageAspectRatio,ChildCount,RunTimeTicks,UserData';

  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final normalizedServerUrl = _normalizeServerUrl(serverUrl);

    final response = await _dio.post<Map<String, dynamic>>(
      '$normalizedServerUrl/Users/AuthenticateByName',
      data: {'Username': username, 'Pw': password},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': AppConstants.httpUserAgent,
          'X-Emby-Authorization': _authorizationHeader(),
        },
      ),
    );

    final data = response.data ?? <String, dynamic>{};
    final user = (data['User'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final accessToken = data['AccessToken'] as String? ?? '';
    final userId = user['Id'] as String? ?? '';
    final userName = user['Name'] as String? ?? username;

    if (accessToken.isEmpty || userId.isEmpty) {
      throw const FormatException('Emby 登录响应缺少必要字段。');
    }

    final resolvedServerUrl = _resolveServerUrlFromResponse(
      fallbackServerUrl: normalizedServerUrl,
      responseUri: response.realUri,
      endpointPath: '/Users/AuthenticateByName',
    );

    return AuthSession(
      serverUrl: resolvedServerUrl,
      userId: userId,
      userName: userName,
      accessToken: accessToken,
      backendType: MusicBackendType.emby,
    );
  }

  Future<List<MusicAlbum>> fetchLatestAlbums(
    AuthSession session, {
    int limit = 12,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'MusicAlbum',
        'Recursive': true,
        'SortBy': 'DateCreated',
        'SortOrder': 'Descending',
        'Fields': _albumFields,
        'ImageTypeLimit': 1,
        'Limit': limit,
      },
      options: _authorizedOptions(session, requestLabel: 'home.latestAlbums'),
    );

    final items = _readItems(response.data);

    return items
        .map((item) => _toMusicAlbum(session, item))
        .where((album) => album.id.isNotEmpty)
        .toList();
  }

  Future<List<MusicAlbum>> fetchRandomAlbums(
    AuthSession session, {
    int limit = 6,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'MusicAlbum',
        'Recursive': true,
        'SortBy': 'Random',
        'Fields': _albumFields,
        'ImageTypeLimit': 1,
        'Limit': limit,
      },
      options: _authorizedOptions(session, requestLabel: 'home.randomAlbums'),
    );

    final items = _readItems(response.data);

    return items
        .map((item) => _toMusicAlbum(session, item))
        .where((album) => album.id.isNotEmpty)
        .toList();
  }

  Future<({List<MusicTrack> tracks, int? totalCount})> fetchTracks(
    AuthSession session, {
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: _buildQueryParameters(
        includeItemTypes: 'Audio',
        fields: _trackListFields,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
        sortBy: 'SortName',
      ),
      options: _authorizedOptions(session, requestLabel: 'library.tracks'),
    );

    final data = response.data;
    final totalCount = data?['TotalRecordCount'] as int?;
    final items = _readItems(data);

    final tracks = items
        .map((item) => _toMusicTrack(session, item))
        .where((track) => track.id.isNotEmpty)
        .toList();

    return (tracks: tracks, totalCount: totalCount);
  }

  Future<List<MusicAlbum>> fetchAlbums(
    AuthSession session, {
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: _buildQueryParameters(
        includeItemTypes: 'MusicAlbum',
        fields: _albumFields,
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
        sortBy: 'SortName',
      ),
      options: _authorizedOptions(session, requestLabel: 'library.albums'),
    );

    final items = _readItems(response.data);

    return items
        .map((item) => _toMusicAlbum(session, item))
        .where((album) => album.id.isNotEmpty)
        .toList();
  }

  Future<List<MusicArtist>> fetchArtists(
    AuthSession session, {
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  }) async {
    final params = _buildQueryParameters(
      includeItemTypes: 'MusicArtist',
      fields: _artistFields,
      limit: limit,
      startIndex: startIndex,
      searchQuery: searchQuery,
      sortBy: 'SortName',
    );
    if (genreId != null && genreId.isNotEmpty) {
      params['GenreIds'] = genreId;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: params,
      options: _authorizedOptions(session, requestLabel: 'library.artists'),
    );

    final items = _readItems(response.data);

    return items
        .map((item) => _toMusicArtist(session, item))
        .where((artist) => artist.id.isNotEmpty)
        .toList();
  }

  Future<List<Genre>> fetchGenres(AuthSession session) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Genres',
      queryParameters: {
        'UserId': session.userId,
        'IncludeItemTypes': 'MusicArtist',
        'ImageTypeLimit': 0,
      },
      options: _authorizedOptions(session, requestLabel: 'library.genres'),
    );

    final items = _readItems(response.data);
    return items
        .map(
          (item) => Genre(
            id: item['Id'] as String? ?? '',
            name: item['Name'] as String? ?? '',
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
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: _buildPlaylistQueryParameters(
        limit: limit,
        startIndex: startIndex,
        searchQuery: searchQuery,
      ),
      options: _authorizedOptions(session, requestLabel: 'playlists.list'),
    );

    final items = _readItems(response.data);

    return items
        .map((item) => _toMusicPlaylist(session, item))
        .where((playlist) => playlist.id.isNotEmpty)
        .toList();
  }

  Future<List<MusicTrack>> fetchAlbumTracks(
    AuthSession session,
    String albumId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'ParentId': albumId,
        'IncludeItemTypes': 'Audio',
        'Recursive': true,
        'SortBy': 'ParentIndexNumber,IndexNumber,SortName',
        'Fields': _trackDetailFields,
        'ImageTypeLimit': 1,
      },
      options: _authorizedOptions(session, requestLabel: 'album.tracks'),
    );

    final items = _readItems(response.data);

    return items
        .map((item) => _toMusicTrack(session, item))
        .where((track) => track.id.isNotEmpty)
        .toList();
  }

  Future<List<MusicTrack>> fetchPlaylistTracks(
    AuthSession session,
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Playlists/$playlistId/Items',
      queryParameters: {
        'UserId': session.userId,
        'Fields': _trackListFields,
        'ImageTypeLimit': 1,
        'Limit': ?limit,
        if (startIndex > 0) 'StartIndex': startIndex,
      },
      options: _authorizedOptions(session, requestLabel: 'playlist.tracks'),
    );

    final items = _readItems(response.data);

    return items
        .map((item) => _toMusicTrack(session, item))
        .where((track) => track.id.isNotEmpty)
        .toList();
  }

  /// 旧接口：直接 static 下载原始文件（AudioQuality.auto 等价于这个）。
  String buildStreamUrl(AuthSession session, String trackId) {
    final uri =
        Uri.parse(
          '${session.normalizedServerUrl}/Audio/$trackId/stream',
        ).replace(
          queryParameters: {'static': 'true', 'api_key': session.accessToken},
        );

    return uri.toString();
  }

  /// 通用音频端点，支持按音质切换容器/码率。
  ///
  /// Emby 会按 MaxStreamingBitrate / MaxAudioChannels / Container 等
  /// 决定是否直通原文件 还是 实时转码。
  String buildUniversalAudioUrl(
    AuthSession session,
    String trackId,
    AudioQuality quality,
  ) {
    if (quality == AudioQuality.auto) {
      return buildStreamUrl(session, trackId);
    }

    final profile = _qualityProfileFor(quality);
    final queryParams = <String, String>{
      'UserId': session.userId,
      'DeviceId': _deviceId,
      'api_key': session.accessToken,
      'MaxStreamingBitrate': '${profile.maxBitrate}',
      'Container': profile.container,
      'AudioCodec': profile.audioCodec,
      'TranscodingContainer': profile.container,
      'TranscodingProtocol': _transcodingProtocolFor(session),
    };

    final uri = Uri.parse(
      '${session.normalizedServerUrl}/Audio/$trackId/universal',
    ).replace(queryParameters: queryParams);
    return uri.toString();
  }

  String buildArtworkUrl(AuthSession session, String itemId, {int size = 480}) {
    final uri =
        Uri.parse(
          '${session.normalizedServerUrl}/Items/$itemId/Images/Primary',
        ).replace(
          queryParameters: {
            'fillWidth': '$size',
            'quality': '90',
            'api_key': session.accessToken,
          },
        );

    return uri.toString();
  }

  /// 单条 Item 详情（带 MediaSources，用于定位歌词轨道）。
  Future<Map<String, dynamic>?> fetchItemDetail(
    AuthSession session,
    String itemId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items/$itemId',
      options: _authorizedOptions(session),
    );
    return response.data;
  }

  /// 拉取某首歌的同步歌词。
  ///
  /// 策略：先查 MediaStreams 中的 subtitle/lyric 轨（`Type=Subtitle` 且 `Codec=lrc/srt/subrip`），
  /// 拿到 Index 和 MediaSourceId 后调 Subtitles/Stream.js 转成 JSON 解析。
  Future<List<LyricLine>?> fetchLyrics(
    AuthSession session,
    String trackId,
  ) async {
    final detail = await fetchItemDetail(session, trackId);
    return fetchLyricsFromItemDetail(session, trackId, detail);
  }

  Future<List<LyricLine>?> fetchLyricsFromItemDetail(
    AuthSession session,
    String trackId,
    Map<String, dynamic>? detail,
  ) async {
    if (detail == null) return null;

    final mediaSources = (detail['MediaSources'] as List?) ?? const [];
    if (mediaSources.isEmpty) return null;

    final mediaSource = mediaSources.first;
    if (mediaSource is! Map<String, dynamic>) return null;

    final mediaSourceId = mediaSource['Id'] as String? ?? trackId;
    final streams = (mediaSource['MediaStreams'] as List?) ?? const [];

    int? lyricIndex;
    for (final stream in streams) {
      if (stream is! Map<String, dynamic>) continue;
      final type = (stream['Type'] as String?)?.toLowerCase();
      final codec = (stream['Codec'] as String?)?.toLowerCase();
      if (type == 'subtitle' || type == 'lyric') {
        if (codec == 'lrc' ||
            codec == 'srt' ||
            codec == 'subrip' ||
            codec == 'ass' ||
            codec == null) {
          lyricIndex = stream['Index'] as int?;
          break;
        }
      }
    }

    if (lyricIndex == null) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${session.normalizedServerUrl}/Items/$trackId/$mediaSourceId/Subtitles/$lyricIndex/Stream.js',
        queryParameters: {'api_key': session.accessToken},
        options: _authorizedOptions(session),
      );

      final data = response.data;
      if (data == null) return null;

      final trackEvents = (data['TrackEvents'] as List?) ?? const [];
      if (trackEvents.isEmpty) return null;

      final lines = <LyricLine>[];
      for (final event in trackEvents) {
        if (event is! Map<String, dynamic>) continue;
        final text = (event['Text'] as String? ?? '').trim();
        if (text.isEmpty) continue;
        final startTicks = event['StartPositionTicks'];
        final start = _durationFromTicks(startTicks);
        lines.add(LyricLine(start: start, text: text));
      }

      if (lines.isEmpty) return null;
      lines.sort((a, b) => a.start.compareTo(b.start));
      return lines;
    } on DioException {
      return null;
    }
  }

  /// 切换收藏状态。POST / DELETE `/Users/{UserId}/FavoriteItems/{ItemId}`。
  Future<void> setFavorite(
    AuthSession session,
    String itemId,
    bool value,
  ) async {
    final url =
        '${session.normalizedServerUrl}/Users/${session.userId}/FavoriteItems/$itemId';
    if (value) {
      await _dio.post<void>(url, options: _authorizedOptions(session));
    } else {
      await _dio.delete<void>(url, options: _authorizedOptions(session));
    }
  }

  Future<void> reportPlaybackStart(
    AuthSession session,
    String trackId,
    String playSessionId,
  ) async {
    await _dio.post<void>(
      '${session.normalizedServerUrl}/Sessions/Playing',
      data: {
        'ItemId': trackId,
        'PlaySessionId': playSessionId,
        'CanSeek': true,
        'IsPaused': false,
        'PlayMethod': 'DirectStream',
      },
      options: _authorizedOptions(session),
    );
  }

  Future<void> reportPlaybackProgress(
    AuthSession session,
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) async {
    await _dio.post<void>(
      '${session.normalizedServerUrl}/Sessions/Playing/Progress',
      data: {
        'ItemId': trackId,
        'PlaySessionId': playSessionId,
        'PositionTicks': position.inMicroseconds * 10,
        'IsPaused': isPaused,
        'CanSeek': true,
        'PlayMethod': 'DirectStream',
      },
      options: _authorizedOptions(session),
    );
  }

  Future<void> reportPlaybackStopped(
    AuthSession session,
    String trackId,
    String playSessionId,
    Duration position,
  ) async {
    await _dio.post<void>(
      '${session.normalizedServerUrl}/Sessions/Playing/Stopped',
      data: {
        'ItemId': trackId,
        'PlaySessionId': playSessionId,
        'PositionTicks': position.inMicroseconds * 10,
      },
      options: _authorizedOptions(session),
    );
  }

  /// 最近播放（按 DatePlayed 降序）。
  Future<List<MusicTrack>> fetchRecentlyPlayed(
    AuthSession session, {
    int limit = 30,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'Audio',
        'Recursive': true,
        'SortBy': 'DatePlayed',
        'SortOrder': 'Descending',
        'Filters': 'IsPlayed',
        'Fields': _trackListFields,
        'ImageTypeLimit': 1,
        'Limit': limit,
      },
      options: _authorizedOptions(session, requestLabel: 'home.recentlyPlayed'),
    );

    final items = _readItems(response.data);
    return items
        .map((e) => _toMusicTrack(session, e))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  /// 最常播放（按 PlayCount 降序）。
  Future<List<MusicTrack>> fetchMostPlayed(
    AuthSession session, {
    int limit = 30,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'Audio',
        'Recursive': true,
        'SortBy': 'PlayCount',
        'SortOrder': 'Descending',
        'Filters': 'IsPlayed',
        'Fields': _trackListFields,
        'ImageTypeLimit': 1,
        'Limit': limit,
      },
      options: _authorizedOptions(session, requestLabel: 'home.mostPlayed'),
    );

    final items = _readItems(response.data);
    return items
        .map((e) => _toMusicTrack(session, e))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  /// 收藏的歌曲。
  Future<List<MusicTrack>> fetchFavoriteTracks(
    AuthSession session, {
    int limit = 100,
    int startIndex = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'Audio',
        'Recursive': true,
        'Filters': 'IsFavorite',
        'SortBy': 'SortName',
        'Fields': _trackListFields,
        'ImageTypeLimit': 1,
        'Limit': limit,
        'StartIndex': startIndex,
      },
      options: _authorizedOptions(session),
    );

    final items = _readItems(response.data);
    return items
        .map((e) => _toMusicTrack(session, e))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  Future<List<MusicAlbum>> fetchArtistAlbums(
    AuthSession session,
    String artistId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'MusicAlbum',
        'Recursive': true,
        'AlbumArtistIds': artistId,
        'SortBy': 'ProductionYear,SortName',
        'SortOrder': 'Descending',
        'Fields': _albumFields,
        'ImageTypeLimit': 1,
      },
      options: _authorizedOptions(session),
    );

    final items = _readItems(response.data);
    return items
        .map((e) => _toMusicAlbum(session, e))
        .where((a) => a.id.isNotEmpty)
        .toList();
  }

  Future<List<MusicTrack>> fetchArtistTopTracks(
    AuthSession session,
    String artistId, {
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'Audio',
        'Recursive': true,
        'ArtistIds': artistId,
        'SortBy': 'PlayCount,SortName',
        'SortOrder': 'Descending',
        'Fields': _trackListFields,
        'ImageTypeLimit': 1,
        'Limit': limit,
      },
      options: _authorizedOptions(session),
    );

    final items = _readItems(response.data);
    return items
        .map((e) => _toMusicTrack(session, e))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  /// 跨类型搜索 —— 并发发四条请求，每条复用对应的 fetchXxx。
  Future<SearchResults> searchAll(
    AuthSession session,
    String query, {
    int perTypeLimit = 30,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return SearchResults.empty;

    final results = await Future.wait([
      fetchTracks(session, limit: perTypeLimit, searchQuery: trimmed),
      fetchAlbums(session, limit: perTypeLimit, searchQuery: trimmed),
      fetchArtists(session, limit: perTypeLimit, searchQuery: trimmed),
      fetchPlaylists(session, limit: perTypeLimit, searchQuery: trimmed),
    ]);

    return SearchResults(
      tracks:
          (results[0] as ({List<MusicTrack> tracks, int? totalCount})).tracks,
      albums: results[1] as List<MusicAlbum>,
      artists: results[2] as List<MusicArtist>,
      playlists: results[3] as List<MusicPlaylist>,
    );
  }

  Options _authorizedOptions(AuthSession session, {String? requestLabel}) {
    return Options(
      headers: {
        'User-Agent': AppConstants.httpUserAgent,
        'X-Emby-Token': session.accessToken,
        'X-Emby-Authorization': _authorizationHeader(
          token: session.accessToken,
        ),
      },
      extra: requestLabel == null ? null : {'requestLabel': requestLabel},
    );
  }

  String _authorizationHeader({String? token}) {
    final buffer = StringBuffer(
      'MediaBrowser Client="$_clientName", '
      'Device="$_deviceName", '
      'DeviceId="$_deviceId", '
      'Version="$_appVersion"',
    );

    if (token != null && token.isNotEmpty) {
      buffer.write(', Token="$token"');
    }

    return buffer.toString();
  }

  String _normalizeServerUrl(String serverUrl) {
    final trimmed = serverUrl.trim();

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }

  String _resolveServerUrlFromResponse({
    required String fallbackServerUrl,
    required Uri responseUri,
    required String endpointPath,
  }) {
    final normalizedEndpoint = endpointPath.startsWith('/')
        ? endpointPath
        : '/$endpointPath';
    final responsePath = responseUri.path;
    if (!responsePath.endsWith(normalizedEndpoint)) {
      return fallbackServerUrl;
    }

    final basePath = responsePath.substring(
      0,
      responsePath.length - normalizedEndpoint.length,
    );
    final resolved = responseUri.replace(
      path: basePath,
      query: null,
      fragment: null,
    );
    return _normalizeServerUrl(resolved.toString());
  }

  String _transcodingProtocolFor(AuthSession session) {
    final scheme = Uri.tryParse(session.normalizedServerUrl)?.scheme;
    return scheme == 'https' ? 'https' : 'http';
  }

  Map<String, dynamic> _buildQueryParameters({
    required String includeItemTypes,
    required String fields,
    required int limit,
    required int startIndex,
    required String? searchQuery,
    String sortBy = 'SortName',
  }) {
    final queryParameters = <String, dynamic>{
      'IncludeItemTypes': includeItemTypes,
      'Recursive': true,
      'SortBy': sortBy,
      'Fields': fields,
      'ImageTypeLimit': 1,
      'Limit': limit,
      'StartIndex': startIndex,
    };

    final normalizedSearchQuery = searchQuery?.trim();
    if (normalizedSearchQuery != null && normalizedSearchQuery.isNotEmpty) {
      queryParameters['SearchTerm'] = normalizedSearchQuery;
    }

    return queryParameters;
  }

  Map<String, dynamic> _buildPlaylistQueryParameters({
    required int limit,
    required int startIndex,
    required String? searchQuery,
  }) {
    final queryParameters = <String, dynamic>{
      'IncludeItemTypes': 'Playlist',
      'Recursive': true,
      'SortBy': 'SortName',
      'Fields': _playlistFields,
      'Limit': limit,
      'StartIndex': startIndex,
      'EnableUserData': false,
      'EnableImages': false,
      'ImageTypeLimit': 0,
      'EnableTotalRecordCount': false,
    };

    final normalizedSearchQuery = searchQuery?.trim();
    if (normalizedSearchQuery != null && normalizedSearchQuery.isNotEmpty) {
      queryParameters['SearchTerm'] = normalizedSearchQuery;
    }

    return queryParameters;
  }

  List<Map<String, dynamic>> _readItems(Map<String, dynamic>? data) {
    return (data?['Items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  MusicAlbum _toMusicAlbum(AuthSession session, Map<String, dynamic> item) {
    final userData = item['UserData'];
    final favorite = userData is Map<String, dynamic>
        ? (userData['IsFavorite'] == true)
        : false;
    return MusicAlbum(
      id: item['Id'] as String? ?? '',
      title: item['Name'] as String? ?? '未知专辑',
      artistName: _resolveArtistName(item),
      artworkUrl: buildArtworkUrl(session, item['Id'] as String? ?? ''),
      trackCount: _readInt(item['ChildCount']),
      year: _readNullableInt(item['ProductionYear']),
      artistId: _resolveArtistId(item),
      isFavorite: favorite,
    );
  }

  MusicArtist _toMusicArtist(AuthSession session, Map<String, dynamic> item) {
    return MusicArtist(
      id: item['Id'] as String? ?? '',
      name: item['Name'] as String? ?? '未知艺术家',
      artworkUrl: buildArtworkUrl(session, item['Id'] as String? ?? ''),
      albumCount: _readInt(item['AlbumCount'] ?? item['AlbumItems']),
      trackCount: _readInt(item['ChildCount']),
    );
  }

  MusicPlaylist _toMusicPlaylist(
    AuthSession session,
    Map<String, dynamic> item,
  ) {
    return MusicPlaylist(
      id: item['Id'] as String? ?? '',
      name: item['Name'] as String? ?? '未命名歌单',
      artworkUrl: buildArtworkUrl(session, item['Id'] as String? ?? ''),
      trackCount: _readInt(item['ChildCount']),
    );
  }

  MusicTrack _toMusicTrack(AuthSession session, Map<String, dynamic> item) {
    final userData = item['UserData'];
    final favorite = userData is Map<String, dynamic>
        ? (userData['IsFavorite'] == true)
        : false;
    final playCount = userData is Map<String, dynamic>
        ? _readInt(userData['PlayCount'])
        : 0;
    final lastPlayed = userData is Map<String, dynamic>
        ? _parseDateTime(userData['LastPlayedDate'])
        : null;

    int? bitRate;
    String? codec;
    String? container;
    final mediaSources = item['MediaSources'];
    if (mediaSources is List && mediaSources.isNotEmpty) {
      final first = mediaSources.first;
      if (first is Map<String, dynamic>) {
        bitRate = _readNullableInt(first['Bitrate']);
        container = (first['Container'] as String?)?.toLowerCase();
        final streams = first['MediaStreams'];
        if (streams is List) {
          for (final s in streams) {
            if (s is Map<String, dynamic> &&
                (s['Type'] as String?)?.toLowerCase() == 'audio') {
              codec = (s['Codec'] as String?)?.toLowerCase();
              bitRate ??= _readNullableInt(s['BitRate']);
              break;
            }
          }
        }
      }
    }

    return MusicTrack(
      id: item['Id'] as String? ?? '',
      title: item['Name'] as String? ?? '未知歌曲',
      artistName: _resolveArtistName(item),
      albumTitle: item['Album'] as String? ?? '未知专辑',
      artworkUrl: buildArtworkUrl(session, item['Id'] as String? ?? ''),
      duration: _durationFromTicks(item['RunTimeTicks']),
      albumId: item['AlbumId'] as String?,
      artistId: _resolveArtistId(item),
      isFavorite: favorite,
      playCount: playCount,
      lastPlayedAt: lastPlayed,
      bitRate: bitRate,
      codec: codec,
      container: container,
    );
  }

  String _resolveArtistName(Map<String, dynamic> item) {
    final albumArtist = item['AlbumArtist'] as String?;
    if (albumArtist != null && albumArtist.trim().isNotEmpty) {
      return albumArtist;
    }

    final albumArtists = item['AlbumArtists'];
    if (albumArtists is List && albumArtists.isNotEmpty) {
      final first = albumArtists.first;
      if (first is Map<String, dynamic>) {
        final name = first['Name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          return name;
        }
      }
    }

    final artistItems = item['ArtistItems'];
    if (artistItems is List && artistItems.isNotEmpty) {
      final first = artistItems.first;
      if (first is Map<String, dynamic>) {
        final name = first['Name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          return name;
        }
      }
    }

    return '未知艺术家';
  }

  String? _resolveArtistId(Map<String, dynamic> item) {
    final albumArtists = item['AlbumArtists'];
    if (albumArtists is List && albumArtists.isNotEmpty) {
      final first = albumArtists.first;
      if (first is Map<String, dynamic>) {
        final id = first['Id'] as String?;
        if (id != null && id.isNotEmpty) return id;
      }
    }

    final artistItems = item['ArtistItems'];
    if (artistItems is List && artistItems.isNotEmpty) {
      final first = artistItems.first;
      if (first is Map<String, dynamic>) {
        final id = first['Id'] as String?;
        if (id != null && id.isNotEmpty) return id;
      }
    }

    return null;
  }

  int _readInt(Object? value) {
    return _readNullableInt(value) ?? 0;
  }

  int? _readNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('$value');
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Duration _durationFromTicks(Object? ticks) {
    final value = _readInt(ticks);
    return Duration(microseconds: value ~/ 10);
  }

  _QualityProfile _qualityProfileFor(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.lossless:
        // 无损：直通 FLAC；Emby 会在无损源时直接 stream=true。
        return const _QualityProfile(
          container: 'flac',
          audioCodec: 'flac',
          maxBitrate: 1411000,
        );
      case AudioQuality.high:
        return const _QualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 320000,
        );
      case AudioQuality.medium:
        return const _QualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 192000,
        );
      case AudioQuality.low:
        return const _QualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 128000,
        );
      case AudioQuality.auto:
        return const _QualityProfile(
          container: 'mp3',
          audioCodec: 'mp3',
          maxBitrate: 320000,
        );
    }
  }
}

class _QualityProfile {
  const _QualityProfile({
    required this.container,
    required this.audioCodec,
    required this.maxBitrate,
  });

  final String container;
  final String audioCodec;
  final int maxBitrate;
}
