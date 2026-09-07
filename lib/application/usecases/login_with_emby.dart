import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class LoginWithEmby {
  const LoginWithEmby(this._repository);

  final MusicRepository _repository;

  Future<AuthSession> call({
    required String serverUrl,
    required String username,
    required String password,
    MusicBackendType? preferredBackendType,
  }) {
    if (preferredBackendType != null) {
      final repository = _repository;
      if (repository is! BackendSelectableLoginRepository) {
        throw UnsupportedError('当前音乐仓库不支持手动指定服务类型。');
      }
      return (repository as BackendSelectableLoginRepository).loginWithBackend(
        serverUrl: serverUrl,
        username: username,
        password: password,
        backendType: preferredBackendType,
      );
    }

    return _repository.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }
}
