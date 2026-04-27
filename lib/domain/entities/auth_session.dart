enum MusicBackendType {
  emby,
  navidrome;

  String get storageKey {
    switch (this) {
      case MusicBackendType.emby:
        return 'emby';
      case MusicBackendType.navidrome:
        return 'navidrome';
    }
  }

  static MusicBackendType fromStorageKey(String? key) {
    switch (key) {
      case 'navidrome':
        return MusicBackendType.navidrome;
      case 'emby':
      default:
        return MusicBackendType.emby;
    }
  }
}

class AuthSession {
  const AuthSession({
    required this.serverUrl,
    required this.userId,
    required this.userName,
    required this.accessToken,
    this.backendType = MusicBackendType.emby,
  });

  final String serverUrl;
  final String userId;
  final String userName;

  /// Emby 下为 access token；Navidrome 下为用于生成 Subsonic token 的原始登录密钥。
  final String accessToken;
  final MusicBackendType backendType;

  String get normalizedServerUrl {
    if (serverUrl.endsWith('/')) {
      return serverUrl.substring(0, serverUrl.length - 1);
    }

    return serverUrl;
  }

  Map<String, String> toJson() {
    return {
      'serverUrl': normalizedServerUrl,
      'userId': userId,
      'userName': userName,
      'accessToken': accessToken,
      'backendType': backendType.storageKey,
    };
  }

  factory AuthSession.fromJson(Map<String, String> json) {
    return AuthSession(
      serverUrl: json['serverUrl'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      accessToken: json['accessToken'] ?? '',
      backendType: MusicBackendType.fromStorageKey(json['backendType']),
    );
  }
}
