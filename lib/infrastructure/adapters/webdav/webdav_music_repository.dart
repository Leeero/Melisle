import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/entities/lyric_line.dart';
import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

/// WebDAV / NAS 适配器骨架。
///
/// 后续实现会用 `package:webdav_client`（或 `dio` 手写 PROPFIND）浏览远程目录，
/// 通过解析目录结构 + 读取 ID3/FLAC 标签来构造 [MusicTrack]/[MusicAlbum]。
///
/// 目前所有方法抛 [UnimplementedError]，用于占位。该类暂不接入 [AppBootstrap]。
class WebDavMusicRepository implements MusicRepository {
  WebDavMusicRepository();

  Never _todo(String method) =>
      throw UnimplementedError('WebDavMusicRepository.$method 尚未实现');

  @override
  Future<AuthSession?> restoreSession() async => _todo('restoreSession');

  @override
  Future<AuthSession> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async => _todo('login');

  @override
  Future<void> logout() async => _todo('logout');

  @override
  Future<List<MusicAlbum>> fetchLatestAlbums({int limit = 12}) async =>
      _todo('fetchLatestAlbums');

  @override
  Future<List<MusicTrack>> fetchTracks({
    int limit = 100,
    int startIndex = 0,
    String? searchQuery,
  }) async => _todo('fetchTracks');

  @override
  Future<List<MusicAlbum>> fetchAlbums({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => _todo('fetchAlbums');

  @override
  Future<List<MusicArtist>> fetchArtists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => _todo('fetchArtists');

  @override
  Future<List<MusicPlaylist>> fetchPlaylists({
    int limit = 60,
    int startIndex = 0,
    String? searchQuery,
  }) async => _todo('fetchPlaylists');

  @override
  Future<List<MusicTrack>> fetchAlbumTracks(String albumId) async =>
      _todo('fetchAlbumTracks');

  @override
  Future<List<MusicTrack>> fetchPlaylistTracks(
    String playlistId, {
    int? limit,
    int startIndex = 0,
  }) async => _todo('fetchPlaylistTracks');

  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async => _todo('getStreamUrl');

  @override
  Future<void> setFavorite(String itemId, bool value) async =>
      _todo('setFavorite');

  @override
  Future<List<LyricLine>?> fetchLyrics(String trackId) async =>
      _todo('fetchLyrics');

  @override
  Future<void> reportPlaybackStart(
    String trackId,
    String playSessionId,
  ) async => _todo('reportPlaybackStart');

  @override
  Future<void> reportPlaybackProgress(
    String trackId,
    String playSessionId,
    Duration position, {
    bool isPaused = false,
  }) async => _todo('reportPlaybackProgress');

  @override
  Future<void> reportPlaybackStopped(
    String trackId,
    String playSessionId,
    Duration position,
  ) async => _todo('reportPlaybackStopped');

  @override
  Future<List<MusicTrack>> fetchRecentlyPlayed({int limit = 30}) async =>
      _todo('fetchRecentlyPlayed');

  @override
  Future<List<MusicTrack>> fetchMostPlayed({int limit = 30}) async =>
      _todo('fetchMostPlayed');

  @override
  Future<List<MusicTrack>> fetchFavoriteTracks({
    int limit = 100,
    int startIndex = 0,
  }) async => _todo('fetchFavoriteTracks');

  @override
  Future<List<MusicAlbum>> fetchArtistAlbums(String artistId) async =>
      _todo('fetchArtistAlbums');

  @override
  Future<List<MusicTrack>> fetchArtistTopTracks(
    String artistId, {
    int limit = 20,
  }) async => _todo('fetchArtistTopTracks');

  @override
  Future<SearchResults> search(String query) async => _todo('search');
}
