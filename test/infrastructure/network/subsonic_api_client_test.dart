import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/infrastructure/network/subsonic_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('并发分页只回源一次完整歌单', () async {
    final responseCompleter = Completer<void>();
    final requestStarted = Completer<void>();
    final adapter = _PlaylistHttpClientAdapter(
      responseCompleter.future,
      requestStarted,
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final client = SubsonicApiClient(dio);
    const session = AuthSession(
      serverUrl: 'https://music.example.test',
      userId: 'user-1',
      userName: 'user-1',
      accessToken: 'password',
    );

    final firstPage = client.fetchPlaylistTracks(
      session,
      'playlist-1',
      limit: 20,
    );
    final secondPage = client.fetchPlaylistTracks(
      session,
      'playlist-1',
      limit: 20,
      startIndex: 20,
    );

    await requestStarted.future;
    expect(adapter.fetchCount, 1);

    responseCompleter.complete();
    final pages = await Future.wait([firstPage, secondPage]);

    expect(pages[0].map((track) => track.id), ['track-0', 'track-1']);
    expect(pages[1], isEmpty);
    expect(adapter.fetchCount, 1);
  });
}

class _PlaylistHttpClientAdapter implements HttpClientAdapter {
  _PlaylistHttpClientAdapter(this.responseReady, this.requestStarted);

  final Future<void> responseReady;
  final Completer<void> requestStarted;
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount += 1;
    if (!requestStarted.isCompleted) requestStarted.complete();
    await responseReady;
    return ResponseBody.fromString(
      jsonEncode({
        'subsonic-response': {
          'status': 'ok',
          'playlist': {
            'entry': [
              {
                'id': 'track-0',
                'title': '歌曲 0',
                'artist': '艺术家',
                'album': '专辑',
                'duration': 180,
              },
              {
                'id': 'track-1',
                'title': '歌曲 1',
                'artist': '艺术家',
                'album': '专辑',
                'duration': 200,
              },
            ],
          },
        },
      }),
      200,
      headers: const {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
