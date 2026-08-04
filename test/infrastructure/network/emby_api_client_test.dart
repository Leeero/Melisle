import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/infrastructure/network/emby_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbyApiClient.buildUniversalAudioUrl', () {
    final client = EmbyApiClient(Dio());

    test('在 https 服务器上使用 https 转码协议', () {
      const session = AuthSession(
        serverUrl: 'https://music.example.com/emby',
        userId: 'user-1',
        userName: 'lero',
        accessToken: 'token-1',
      );

      final url = client.buildUniversalAudioUrl(
        session,
        'track-1',
        AudioQuality.high,
      );

      expect(Uri.parse(url).queryParameters['TranscodingProtocol'], 'https');
    });

    test('在 http 服务器上保持 http 转码协议', () {
      const session = AuthSession(
        serverUrl: 'http://192.168.1.20:8096',
        userId: 'user-1',
        userName: 'lero',
        accessToken: 'token-1',
      );

      final url = client.buildUniversalAudioUrl(
        session,
        'track-1',
        AudioQuality.high,
      );

      expect(Uri.parse(url).queryParameters['TranscodingProtocol'], 'http');
    });
  });

  test('歌单歌曲使用用户媒体项接口查询', () async {
    final adapter = _RecordingHttpClientAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final client = EmbyApiClient(dio);
    const session = AuthSession(
      serverUrl: 'https://music.example.test',
      userId: 'user-1',
      userName: 'user-1',
      accessToken: 'token',
    );

    await client.fetchPlaylistTracks(
      session,
      'playlist-1',
      limit: 20,
      startIndex: 40,
    );

    expect(
      adapter.requestOptions?.path,
      'https://music.example.test/Users/user-1/Items',
    );
    expect(
      adapter.requestOptions?.queryParameters,
      containsPair('ParentId', 'playlist-1'),
    );
    expect(
      adapter.requestOptions?.queryParameters,
      containsPair('IncludeItemTypes', 'Audio'),
    );
    expect(adapter.requestOptions?.queryParameters, containsPair('Limit', 20));
    expect(
      adapter.requestOptions?.queryParameters,
      containsPair('StartIndex', 40),
    );
  });
}

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? requestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    return ResponseBody.fromString(
      jsonEncode({'Items': <Object>[]}),
      200,
      headers: const {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
