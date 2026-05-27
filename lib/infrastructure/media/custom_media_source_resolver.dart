import 'dart:convert';

import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:dio/dio.dart';

class CustomSourceTestResult {
  const CustomSourceTestResult({
    required this.isSuccess,
    required this.message,
    this.resolvedUrl,
    this.statusCode,
  });

  final bool isSuccess;
  final String message;
  final String? resolvedUrl;
  final int? statusCode;
}

class ArtworkSourceContext {
  const ArtworkSourceContext({
    this.itemId,
    this.trackId,
    this.albumId,
    this.artistId,
    this.title,
    this.artistName,
    this.albumTitle,
  });

  factory ArtworkSourceContext.track(MusicTrack track) {
    return ArtworkSourceContext(
      itemId: track.id,
      trackId: track.id,
      albumId: track.albumId,
      artistId: track.artistId,
      title: track.title,
      artistName: track.artistName,
      albumTitle: track.albumTitle,
    );
  }

  factory ArtworkSourceContext.album(MusicAlbum album) {
    return ArtworkSourceContext(
      itemId: album.id,
      albumId: album.id,
      artistId: album.artistId,
      title: album.title,
      artistName: album.artistName,
      albumTitle: album.title,
    );
  }

  factory ArtworkSourceContext.artist(MusicArtist artist) {
    return ArtworkSourceContext(
      itemId: artist.id,
      artistId: artist.id,
      title: artist.name,
      artistName: artist.name,
    );
  }

  factory ArtworkSourceContext.playlist(MusicPlaylist playlist) {
    return ArtworkSourceContext(
      itemId: playlist.id,
      title: playlist.name,
      albumTitle: playlist.name,
    );
  }

  final String? itemId;
  final String? trackId;
  final String? albumId;
  final String? artistId;
  final String? title;
  final String? artistName;
  final String? albumTitle;
}

class ResolvedArtworkSource {
  const ResolvedArtworkSource({
    required this.primaryUrl,
    required this.fallbackUrl,
    required this.usingCustomSource,
  });

  final String primaryUrl;
  final String fallbackUrl;
  final bool usingCustomSource;

  bool get hasPrimary => primaryUrl.trim().isNotEmpty;

  bool get hasFallback {
    final normalizedFallback = fallbackUrl.trim();
    final normalizedPrimary = primaryUrl.trim();
    return normalizedFallback.isNotEmpty &&
        normalizedFallback != normalizedPrimary;
  }
}

class CustomMediaSourceResolver {
  CustomMediaSourceResolver({
    Dio? dio,
    AppSettingsSnapshot initialSettings = const AppSettingsSnapshot(),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 12),
             ),
           ),
       _settings = initialSettings;

  final Dio _dio;
  AppSettingsSnapshot _settings;

  void updateSettings(AppSettingsSnapshot settings) {
    _settings = settings;
  }

  ResolvedArtworkSource resolveArtworkSource({
    required String fallbackUrl,
    ArtworkSourceContext? context,
    int size = 480,
  }) {
    final normalizedFallbackUrl = fallbackUrl.trim();
    final address = _settings.customArtworkSourceUrl.trim();
    if (!_settings.customArtworkSourceEnabled || address.isEmpty) {
      return ResolvedArtworkSource(
        primaryUrl: normalizedFallbackUrl,
        fallbackUrl: normalizedFallbackUrl,
        usingCustomSource: false,
      );
    }

    final resolved = _buildResolvedUrl(
      address,
      _buildContext(
        fallbackUrl: normalizedFallbackUrl,
        itemId: context?.itemId ?? context?.trackId,
        trackId: context?.trackId,
        albumId: context?.albumId,
        artistId: context?.artistId,
        title: context?.title,
        artistName: context?.artistName,
        albumTitle: context?.albumTitle,
        size: size,
      ),
      queryParameterKeys: _queryParameterKeysFor(address, isLyrics: false),
    );

    if (resolved == null || resolved.trim().isEmpty) {
      return ResolvedArtworkSource(
        primaryUrl: normalizedFallbackUrl,
        fallbackUrl: normalizedFallbackUrl,
        usingCustomSource: false,
      );
    }

    return ResolvedArtworkSource(
      primaryUrl: resolved,
      fallbackUrl: normalizedFallbackUrl,
      usingCustomSource: true,
    );
  }

  String resolveArtworkUrl({
    required String fallbackUrl,
    ArtworkSourceContext? context,
    String? itemId,
    String? trackId,
    String? albumId,
    String? artistId,
    String? title,
    String? artistName,
    String? albumTitle,
    int size = 480,
  }) {
    return resolveArtworkSource(
      fallbackUrl: fallbackUrl,
      context:
          context ??
          ArtworkSourceContext(
            itemId: itemId,
            trackId: trackId,
            albumId: albumId,
            artistId: artistId,
            title: title,
            artistName: artistName,
            albumTitle: albumTitle,
          ),
      size: size,
    ).primaryUrl;
  }

  Future<List<LyricLine>?> fetchLyrics({
    required String trackId,
    String? title,
    String? artistName,
    String? albumTitle,
    Future<List<LyricLine>?> Function()? fallback,
  }) async {
    final address = _settings.customLyricsSourceUrl.trim();
    if (_settings.customLyricsSourceEnabled && address.isNotEmpty) {
      final resolvedUrl = _buildResolvedLyricsUrl(
        address,
        _buildContext(
          trackId: trackId,
          itemId: trackId,
          title: title,
          artistName: artistName,
          albumTitle: albumTitle,
        ),
      );

      if (resolvedUrl != null) {
        try {
          final response = await _dio.get<String>(
            resolvedUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: const {'User-Agent': AppConstants.httpUserAgent},
              validateStatus: (status) => status != null && status < 500,
            ),
          );
          if (_isSuccessfulStatus(response.statusCode)) {
            final lyrics = _parseLyricsResponse(
              response.data ?? '',
              contentType: response.headers.value(Headers.contentTypeHeader),
            );
            if (lyrics.isNotEmpty) {
              return lyrics;
            }
          }
        } catch (_) {
          // Ignore and fall back to the built-in source.
        }
      }
    }

    if (fallback != null) {
      return fallback();
    }
    return null;
  }

  Future<CustomSourceTestResult> testArtworkSource(String rawAddress) {
    final resolvedUrl = _buildResolvedUrl(
      rawAddress,
      _sampleArtworkContext,
      queryParameterKeys: _queryParameterKeysFor(rawAddress, isLyrics: false),
    );
    return _testUrl(resolvedUrl, expectLyrics: false);
  }

  Future<CustomSourceTestResult> testLyricsSource(String rawAddress) {
    final resolvedUrl = _buildResolvedLyricsUrl(
      rawAddress,
      _sampleLyricsContext,
    );
    return _testUrl(resolvedUrl, expectLyrics: true);
  }

  Map<String, String> get _sampleArtworkContext => _buildContext(
    fallbackUrl: 'https://example.com/assets/cover.jpg',
    itemId: 'track-demo-001',
    trackId: 'track-demo-001',
    albumId: 'album-demo-001',
    artistId: 'artist-demo-001',
    title: 'Test Track',
    artistName: 'Test Artist',
    albumTitle: 'Test Album',
    size: 480,
  );

  Map<String, String> get _sampleLyricsContext => _buildContext(
    itemId: 'track-demo-001',
    trackId: 'track-demo-001',
    albumId: 'album-demo-001',
    artistId: 'artist-demo-001',
    title: 'Test Track',
    artistName: 'Test Artist',
    albumTitle: 'Test Album',
  );

  Future<CustomSourceTestResult> _testUrl(
    String? resolvedUrl, {
    required bool expectLyrics,
  }) async {
    if (resolvedUrl == null) {
      return const CustomSourceTestResult(
        isSuccess: false,
        message: '请输入合法的 http/https 地址。',
      );
    }

    try {
      final response = await _dio.get<Object?>(
        resolvedUrl,
        options: Options(
          responseType: expectLyrics ? ResponseType.plain : ResponseType.bytes,
          headers: const {'User-Agent': AppConstants.httpUserAgent},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final statusCode = response.statusCode;
      if (!_isSuccessfulStatus(statusCode)) {
        return CustomSourceTestResult(
          isSuccess: false,
          message: '地址可访问，但返回了异常状态码：${statusCode ?? 'unknown'}。',
          resolvedUrl: resolvedUrl,
          statusCode: statusCode,
        );
      }

      final contentType = response.headers.value(Headers.contentTypeHeader);
      if (!expectLyrics) {
        return CustomSourceTestResult(
          isSuccess: true,
          message: '测试通过，已成功访问自定义封面地址${_formatContentType(contentType)}。',
          resolvedUrl: resolvedUrl,
          statusCode: statusCode,
        );
      }

      final body = response.data is String
          ? response.data as String
          : utf8.decode(
              (response.data as List<int>? ?? const <int>[]),
              allowMalformed: true,
            );
      final parsed = _parseLyricsResponse(body, contentType: contentType);
      if (parsed.isNotEmpty) {
        return CustomSourceTestResult(
          isSuccess: true,
          message: '测试通过，已识别到 ${parsed.length} 行歌词。',
          resolvedUrl: resolvedUrl,
          statusCode: statusCode,
        );
      }

      return CustomSourceTestResult(
        isSuccess: true,
        message: '地址可访问，但示例响应里没有识别到歌词内容；如服务依赖真实曲目信息，可继续在实际播放时验证。',
        resolvedUrl: resolvedUrl,
        statusCode: statusCode,
      );
    } on DioException catch (error) {
      return CustomSourceTestResult(
        isSuccess: false,
        message: '测试失败：${error.message ?? '网络请求异常'}',
        resolvedUrl: resolvedUrl,
      );
    } catch (error) {
      return CustomSourceTestResult(
        isSuccess: false,
        message: '测试失败：$error',
        resolvedUrl: resolvedUrl,
      );
    }
  }

  String _formatContentType(String? contentType) {
    if (contentType == null || contentType.trim().isEmpty) {
      return '';
    }
    return '（$contentType）';
  }

  bool _isSuccessfulStatus(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 400;
  }

  Map<String, String> _buildContext({
    String? fallbackUrl,
    String? itemId,
    String? trackId,
    String? albumId,
    String? artistId,
    String? title,
    String? artistName,
    String? albumTitle,
    int? size,
  }) {
    final normalizedAlbumTitle = _normalizeAlbumTitle(albumTitle);
    return {
      'sourceUrl': fallbackUrl ?? '',
      'fallbackUrl': fallbackUrl ?? '',
      'id': itemId ?? '',
      'itemId': itemId ?? '',
      'trackId': trackId ?? itemId ?? '',
      'albumId': albumId ?? '',
      'artistId': artistId ?? '',
      'title': title ?? '',
      'artist': artistName ?? '',
      'artistName': artistName ?? '',
      'album': normalizedAlbumTitle,
      'albumTitle': normalizedAlbumTitle,
      'size': size?.toString() ?? '',
    };
  }

  String _normalizeAlbumTitle(String? albumTitle) {
    final trimmed = albumTitle?.trim() ?? '';
    if (trimmed == '[Unknown Album]') {
      return '';
    }
    return trimmed;
  }

  String? _buildResolvedUrl(
    String rawAddress,
    Map<String, String> context, {
    Iterable<String>? queryParameterKeys,
  }) {
    final trimmed = rawAddress.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (_placeholderPattern.hasMatch(trimmed)) {
      final replaced = trimmed.replaceAllMapped(_placeholderPattern, (match) {
        final key = match.group(1) ?? '';
        final value = context[key] ?? '';
        return Uri.encodeComponent(value);
      });
      final uri = Uri.tryParse(replaced);
      if (!_isSupportedHttpUri(uri)) {
        return null;
      }
      return uri.toString();
    }

    final uri = Uri.tryParse(trimmed);
    if (!_isSupportedHttpUri(uri)) {
      return null;
    }

    final queryParameters = Map<String, String>.from(uri!.queryParameters);
    final queryKeys = queryParameterKeys ?? context.keys;
    for (final key in queryKeys) {
      final value = context[key]?.trim() ?? '';
      if (value.isEmpty || queryParameters.containsKey(key)) {
        continue;
      }
      queryParameters[key] = value;
    }

    return uri.replace(queryParameters: queryParameters).toString();
  }

  String? _buildResolvedLyricsUrl(
    String rawAddress,
    Map<String, String> context,
  ) {
    return _buildResolvedUrl(
      rawAddress,
      context,
      queryParameterKeys: _queryParameterKeysFor(rawAddress, isLyrics: true),
    );
  }

  Iterable<String>? _queryParameterKeysFor(
    String rawAddress, {
    required bool isLyrics,
  }) {
    final uri = Uri.tryParse(rawAddress.trim());
    if (isLyrics) {
      return const ['title', 'album', 'artist'];
    }
    if (_isLrcCxEndpoint(uri, 'cover')) {
      return const ['title'];
    }
    return null;
  }

  bool _isLrcCxEndpoint(Uri? uri, String expectedPath) {
    if (!_isSupportedHttpUri(uri) || uri!.host.toLowerCase() != 'api.lrc.cx') {
      return false;
    }
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty &&
        pathSegments.last.toLowerCase() == expectedPath;
  }

  bool _isSupportedHttpUri(Uri? uri) {
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  List<LyricLine> _parseLyricsResponse(String raw, {String? contentType}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    if ((contentType?.contains('json') ?? false) ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('[')) {
      try {
        final json = jsonDecode(trimmed);
        final parsed = _parseJsonLyrics(json);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Fall back to LRC/text parsing.
      }
    }

    return _parseLrcLyrics(trimmed);
  }

  List<LyricLine> _parseJsonLyrics(dynamic json) {
    if (json is Map<String, dynamic>) {
      final trackEvents = json['TrackEvents'];
      if (trackEvents is List) {
        final lines = <LyricLine>[];
        for (final event in trackEvents.whereType<Map<String, dynamic>>()) {
          final text = (event['Text'] as String? ?? '').trim();
          if (text.isEmpty) continue;
          final ticks = event['StartPositionTicks'];
          final start = _durationFromTicks(ticks);
          lines.add(LyricLine(start: start, text: text));
        }
        if (lines.isNotEmpty) {
          lines.sort((a, b) => a.start.compareTo(b.start));
          return lines;
        }
      }

      final embeddedText = json['lyrics'] ?? json['lrc'] ?? json['content'];
      if (embeddedText is String && embeddedText.trim().isNotEmpty) {
        final lines = _parseLyricsResponse(embeddedText);
        if (lines.isNotEmpty) {
          return lines;
        }
      }

      final nestedData = json['data'] ?? json['items'] ?? json['lines'];
      if (nestedData is List) {
        return _parseJsonLyricEntries(nestedData);
      }
    }

    if (json is List) {
      return _parseJsonLyricEntries(json);
    }

    return const [];
  }

  List<LyricLine> _parseJsonLyricEntries(List<dynamic> entries) {
    final lines = <LyricLine>[];
    for (final entry in entries.whereType<Map<String, dynamic>>()) {
      final text = (entry['text'] ?? entry['lyric'] ?? entry['lyrics'] ?? '')
          .toString()
          .trim();
      if (text.isEmpty) continue;

      final start = _durationFromJsonEntry(entry);
      if (start == null) continue;
      lines.add(LyricLine(start: start, text: text));
    }

    lines.sort((a, b) => a.start.compareTo(b.start));
    return lines;
  }

  Duration? _durationFromJsonEntry(Map<String, dynamic> entry) {
    const candidates = [
      'startMs',
      'timeMs',
      'positionMs',
      'timestampMs',
      'start',
      'time',
      'position',
      'timestamp',
    ];

    for (final key in candidates) {
      final value = entry[key];
      if (value == null) continue;
      final duration = _durationFromDynamic(value, keyHint: key);
      if (duration != null) {
        return duration;
      }
    }

    return null;
  }

  Duration? _durationFromDynamic(dynamic value, {String? keyHint}) {
    if (value is int) {
      if (keyHint?.toLowerCase().contains('ms') ?? false) {
        return Duration(milliseconds: value);
      }
      if (value >= 100000) {
        return Duration(milliseconds: value);
      }
      return Duration(seconds: value);
    }

    if (value is double) {
      if (keyHint?.toLowerCase().contains('ms') ?? false) {
        return Duration(milliseconds: value.round());
      }
      return Duration(milliseconds: (value * 1000).round());
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final asTimestamp = _parseTimestamp(trimmed);
      if (asTimestamp != null) {
        return asTimestamp;
      }
      final asDouble = double.tryParse(trimmed);
      if (asDouble == null) return null;
      if (keyHint?.toLowerCase().contains('ms') ?? false) {
        return Duration(milliseconds: asDouble.round());
      }
      return Duration(milliseconds: (asDouble * 1000).round());
    }

    return null;
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
        lines.add(LyricLine(start: duration, text: text, sourceOffset: offset));
      }
    }

    lines.sort((a, b) => a.start.compareTo(b.start));
    return lines;
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

  Duration _durationFromTicks(dynamic ticks) {
    final value = _readInt(ticks);
    return Duration(microseconds: value ~/ 10);
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static final RegExp _placeholderPattern = RegExp(r'\{([a-zA-Z0-9_]+)\}');
  static final RegExp _lrcTimestampPattern = RegExp(
    r'\[(\d{1,2}:\d{1,2}(?:[\.:]\d{1,3})?)\]',
  );
  static final RegExp _lrcOffsetPattern = RegExp(
    r'^\s*\[offset:\s*([+-]?\d+)\s*\]\s*$',
    caseSensitive: false,
  );
  static final RegExp _timestampPattern = RegExp(
    r'^(\d{1,2}):(\d{1,2})(?:[\.:](\d{1,3}))?$',
  );
}
