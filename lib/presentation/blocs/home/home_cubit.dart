import 'package:cross_platform_music_player/application/usecases/fetch_latest_albums.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/home/home_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._fetchLatestAlbums, this._repository, {AppDatabase? database})
    : _database = database,
      super(const HomeState.initial());

  static const _homeAlbumsLimit = 8;
  static const _homeTracksLimit = 12;

  final FetchLatestAlbums _fetchLatestAlbums;
  final MusicRepository _repository;
  final AppDatabase? _database;

  Future<void> load() async {
    _debugLog('load start');
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));

    var albums = <MusicAlbum>[];
    var recently = <MusicTrack>[];
    var most = <MusicTrack>[];
    final errors = <String>[];

    _debugLog('section recentlyPlayed start');
    final recentlyResult = await _loadRecentlyPlayedSection();
    recently = recentlyResult.data;
    if (recentlyResult.errorMessage case final message?) {
      errors.add(message);
    }
    _debugLog(
      'section recentlyPlayed done items=${recently.length} error=${_errorSummary(recentlyResult.errorMessage)}',
    );
    _emitPartialSuccess(
      albums: albums,
      recentlyPlayed: recently,
      mostPlayed: most,
    );

    _debugLog('section mostPlayed start');
    final mostResult = await _loadMostPlayedSection();
    most = mostResult.data;
    if (mostResult.errorMessage case final message?) {
      errors.add(message);
    }
    _debugLog(
      'section mostPlayed done items=${most.length} error=${_errorSummary(mostResult.errorMessage)}',
    );
    _emitPartialSuccess(
      albums: albums,
      recentlyPlayed: recently,
      mostPlayed: most,
    );

    _debugLog('section latestAlbums start');
    final albumsResult = await _loadLatestAlbumsSection();
    albums = albumsResult.data;
    if (albumsResult.errorMessage case final message?) {
      errors.add(message);
    }
    _debugLog(
      'section latestAlbums done items=${albums.length} error=${_errorSummary(albumsResult.errorMessage)}',
    );
    _emitPartialSuccess(
      albums: albums,
      recentlyPlayed: recently,
      mostPlayed: most,
    );

    final hasAnyData =
        albums.isNotEmpty || recently.isNotEmpty || most.isNotEmpty;
    if (!hasAnyData && errors.isNotEmpty) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          albums: albums,
          recentlyPlayed: recently,
          mostPlayed: most,
          errorMessage: errors.join('；'),
        ),
      );
      _debugLog(
        'load finish status=failure albums=${albums.length} recently=${recently.length} most=${most.length} errors=${errors.length}',
      );
      return;
    }

    emit(
      state.copyWith(
        status: HomeStatus.success,
        albums: albums,
        recentlyPlayed: recently,
        mostPlayed: most,
        errorMessage: errors.isEmpty ? null : errors.join('；'),
      ),
    );
    _debugLog(
      'load finish status=success albums=${albums.length} recently=${recently.length} most=${most.length} errors=${errors.length}',
    );
  }

  Future<_HomeSectionResult<List<MusicAlbum>>>
  _loadLatestAlbumsSection() async {
    try {
      final albums = await _fetchLatestAlbums(limit: _homeAlbumsLimit);
      return _HomeSectionResult(data: albums);
    } catch (error) {
      return _HomeSectionResult(
        data: const [],
        errorMessage: '最近加入加载失败：$error',
      );
    }
  }

  /// 先看本地 `play_history`；只要本地已有记录，就优先展示，避免首页被慢接口拖住。
  Future<_HomeSectionResult<List<MusicTrack>>>
  _loadRecentlyPlayedSection() async {
    final local = await _loadLocalRecent();
    if (local.isNotEmpty) {
      return _HomeSectionResult(data: local);
    }

    try {
      final remote = await _repository.fetchRecentlyPlayed(
        limit: _homeTracksLimit,
      );
      return _HomeSectionResult(data: _mergeTracks(local, remote));
    } catch (error) {
      return _HomeSectionResult(
        data: local,
        errorMessage: local.isEmpty ? '最近在听加载失败：$error' : null,
      );
    }
  }

  Future<_HomeSectionResult<List<MusicTrack>>> _loadMostPlayedSection() async {
    final local = await _loadLocalMostPlayed();
    if (local.length >= 4) {
      return _HomeSectionResult(data: local);
    }

    try {
      final remote = await _repository.fetchMostPlayed(limit: _homeTracksLimit);
      return _HomeSectionResult(data: _mergeTracks(local, remote));
    } catch (error) {
      return _HomeSectionResult(
        data: local,
        errorMessage: local.isEmpty ? '常听的歌加载失败：$error' : null,
      );
    }
  }

  Future<List<MusicTrack>> _loadLocalRecent() async {
    final db = _database;
    if (db == null) return const [];
    try {
      final rows = await db.recentPlays(limit: 20);
      final seen = <String>{};
      final tracks = <MusicTrack>[];
      for (final r in rows) {
        if (!seen.add(r.trackId)) continue;
        tracks.add(
          MusicTrack(
            id: r.trackId,
            title: r.title,
            artistName: r.artistName ?? '未知艺术家',
            albumTitle: r.albumTitle ?? '',
            artworkUrl: r.artworkUrl ?? '',
            albumId: r.albumId,
            artistId: r.artistId,
            duration: Duration.zero,
            lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(r.playedAtMs),
          ),
        );
        if (tracks.length >= _homeTracksLimit) break;
      }
      return tracks;
    } catch (_) {
      return const [];
    }
  }

  Future<List<MusicTrack>> _loadLocalMostPlayed() async {
    final db = _database;
    if (db == null) return const [];
    try {
      final rows = await db.mostPlayed(limit: _homeTracksLimit);
      return [
        for (final r in rows)
          MusicTrack(
            id: r.trackId,
            title: r.title,
            artistName: r.artistName ?? '未知艺术家',
            albumTitle: r.albumTitle ?? '',
            artworkUrl: r.artworkUrl ?? '',
            albumId: r.albumId,
            artistId: r.artistId,
            duration: Duration.zero,
            playCount: r.playCount,
            lastPlayedAt: r.lastPlayedAtMs == 0
                ? null
                : DateTime.fromMillisecondsSinceEpoch(r.lastPlayedAtMs),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _emitPartialSuccess({
    required List<MusicAlbum> albums,
    required List<MusicTrack> recentlyPlayed,
    required List<MusicTrack> mostPlayed,
  }) {
    final hasAnyData =
        albums.isNotEmpty || recentlyPlayed.isNotEmpty || mostPlayed.isNotEmpty;
    if (!hasAnyData) {
      return;
    }

    emit(
      state.copyWith(
        status: HomeStatus.success,
        albums: albums,
        recentlyPlayed: recentlyPlayed,
        mostPlayed: mostPlayed,
        errorMessage: null,
      ),
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) {
      return;
    }
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    debugPrint('[HOME][$hh:$mm:$ss.$ms] $message');
  }

  String _errorSummary(String? errorMessage) {
    if (errorMessage == null) {
      return 'none';
    }
    final normalized = errorMessage.replaceAll('\n', ' ').trim();
    if (normalized.length <= 96) {
      return normalized;
    }
    return '${normalized.substring(0, 96)}...';
  }

  List<MusicTrack> _mergeTracks(
    List<MusicTrack> primary,
    List<MusicTrack> secondary,
  ) {
    final seen = {for (final t in primary) t.id};
    final merged = [...primary];
    for (final t in secondary) {
      if (seen.add(t.id)) merged.add(t);
      if (merged.length >= _homeTracksLimit) break;
    }
    return merged;
  }
}

class _HomeSectionResult<T> {
  const _HomeSectionResult({required this.data, this.errorMessage});

  final T data;
  final String? errorMessage;
}
