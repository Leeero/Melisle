import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class RestoreSession {
  const RestoreSession(this._repository);

  final MusicRepository _repository;

  Future<AuthSession?> call() {
    return _repository.restoreSession();
  }
}
