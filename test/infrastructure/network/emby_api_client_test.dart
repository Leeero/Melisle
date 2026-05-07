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
}
