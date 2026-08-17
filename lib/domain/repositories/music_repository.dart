import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/artist_sort_option.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/genre.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/paginated_result.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/entities/track_sort_option.dart';

/// 后端无关的音乐仓库契约。
///
/// 任何新的后端适配器（Emby / Subsonic / WebDAV）都必须实现这个接口。
/// 不应往这里增加任何 backend-specific 的方法。
abstract class MusicRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12});

  Future<PaginatedResult<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  });

  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  });

  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  });

  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  });

  Future<List<MusicTrack>> fetchAlbumTracks(String albumId);

  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  });

  /// 根据指定音质返回可直播的流媒体 URL。
  ///
  /// `quality == AudioQuality.auto` 时应尽量透传原文件。
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  });

  /// 设置条目的收藏状态。支持歌曲 / 专辑 / 艺术家 / 歌单。
  Future<void> setFavorite(String itemId, bool value);

  /// 拉取某首歌的同步歌词。
  ///
  /// 没有歌词或服务端不支持时返回 null。
  Future<List<LyricLine>?> fetchLyrics(String trackId);

  /// 汇报一次播放会话的开始。
  ///
  /// [playSessionId] 由上层 PlayerCubit 维护，贯穿整首歌的 start / progress / stopped。
  Future<void> reportPlaybackStart(String trackId, String playSessionId);

  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  });

  Future<void> reportPlaybackStopped(
    String trackId,
    String playSessionId,
    Duration position,
  );

  Future<List<MusicAlbum>> fetchRandomAlbums({int limit = 6});

  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30});

  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30});

  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  });

  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId);

  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  });

  /// 获取可用的音乐风格列表。
  Future<List<Genre>> fetchGenres();

  /// 跨类型搜索（歌曲 / 专辑 / 艺术家 / 歌单）。
  Future<SearchResults> search(String query);
}

/// Optional capability implemented only by protocols that support server-side
/// track sorting. Callers must not synthesize unsupported options locally.
abstract interface class TrackSortingRepository {
  Future<Set<TrackSortOption>> fetchSupportedTrackSortOptions();

  Future<PaginatedResult<MusicTrack>> fetchSortedTracks({
    required TrackSortOption sortOption,
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  });
}

/// Optional capability implemented only by protocols that support server-side
/// artist sorting. Callers must not synthesize unsupported options locally.
abstract interface class ArtistSortingRepository {
  Future<Set<ArtistSortOption>> fetchSupportedArtistSortOptions();

  Future<List<MusicArtist>> fetchSortedArtists({
    required ArtistSortOption sortOption,
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
    String? genreId,
  });
}
