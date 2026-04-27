import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSessionStore {
  AuthSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _serverUrlKey = 'music_server_url';
  static const _userIdKey = 'music_user_id';
  static const _userNameKey = 'music_user_name';
  static const _accessTokenKey = 'music_access_token';
  static const _backendTypeKey = 'music_backend_type';

  AuthSession? _memorySession;

  Future<void> save(AuthSession session) async {
    _memorySession = session;

    try {
      await Future.wait([
        _storage.write(key: _serverUrlKey, value: session.normalizedServerUrl),
        _storage.write(key: _userIdKey, value: session.userId),
        _storage.write(key: _userNameKey, value: session.userName),
        _storage.write(key: _accessTokenKey, value: session.accessToken),
        _storage.write(
          key: _backendTypeKey,
          value: session.backendType.storageKey,
        ),
      ]);
    } on PlatformException {
      // Ignore secure storage failures and keep the session in memory.
    }
  }

  Future<AuthSession?> read() async {
    if (_memorySession != null) {
      return _memorySession;
    }

    try {
      final values = await Future.wait([
        _storage.read(key: _serverUrlKey),
        _storage.read(key: _userIdKey),
        _storage.read(key: _userNameKey),
        _storage.read(key: _accessTokenKey),
        _storage.read(key: _backendTypeKey),
      ]);

      if (values[0] == null ||
          values[0]!.isEmpty ||
          values[1] == null ||
          values[1]!.isEmpty ||
          values[2] == null ||
          values[2]!.isEmpty ||
          values[3] == null ||
          values[3]!.isEmpty) {
        return null;
      }

      return _memorySession = AuthSession(
        serverUrl: values[0]!,
        userId: values[1]!,
        userName: values[2]!,
        accessToken: values[3]!,
        backendType: MusicBackendType.fromStorageKey(values[4]),
      );
    } on PlatformException {
      return _memorySession;
    }
  }

  Future<void> clear() async {
    _memorySession = null;

    try {
      await Future.wait([
        _storage.delete(key: _serverUrlKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userNameKey),
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _backendTypeKey),
      ]);
    } on PlatformException {
      // Ignore secure storage failures when clearing local debug state.
    }
  }
}
