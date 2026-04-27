import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class LoginWithEmby {
  const LoginWithEmby(this._repository);

  final MusicRepository _repository;

  Future<AuthSession> call({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    return _repository.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }
}
