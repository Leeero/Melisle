import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';

class Logout {
  const Logout(this._repository);

  final MusicRepository _repository;

  Future<void> call() {
    return _repository.logout();
  }
}
