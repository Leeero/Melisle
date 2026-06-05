import 'package:cross_platform_music_player/presentation/blocs/auth/dev_login_credentials.dart';
import 'package:flutter/foundation.dart';

final class DevLoginEnvironment {
  const DevLoginEnvironment._();

  static AuthDevLoginCredentials? credentials() {
    if (!kDebugMode) return null;

    const enabled = bool.fromEnvironment('MELISLE_DEV_LOGIN_ENABLED');
    if (!enabled) return null;

    const serverUrl = String.fromEnvironment('MELISLE_DEV_LOGIN_SERVER_URL');
    const username = String.fromEnvironment('MELISLE_DEV_LOGIN_USERNAME');
    const password = String.fromEnvironment('MELISLE_DEV_LOGIN_PASSWORD');

    final normalizedServerUrl = serverUrl.trim();
    final normalizedUsername = username.trim();
    if (normalizedServerUrl.isEmpty ||
        normalizedUsername.isEmpty ||
        password.isEmpty) {
      return null;
    }

    return AuthDevLoginCredentials(
      serverUrl: normalizedServerUrl,
      username: normalizedUsername,
      password: password,
    );
  }
}
