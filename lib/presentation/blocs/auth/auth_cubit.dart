import 'package:cross_platform_music_player/application/usecases/login_with_emby.dart';
import 'package:cross_platform_music_player/application/usecases/logout.dart';
import 'package:cross_platform_music_player/application/usecases/restore_session.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginWithEmby loginWithEmby,
    required RestoreSession restoreSession,
    required Logout logout,
  })  : _loginWithEmby = loginWithEmby,
        _restoreSession = restoreSession,
        _logout = logout,
        super(const AuthState.unknown()) {
    restore();
  }

  final LoginWithEmby _loginWithEmby;
  final RestoreSession _restoreSession;
  final Logout _logout;

  Future<void> restore() async {
    try {
      final session = await _restoreSession();
      if (session == null) {
        emit(const AuthState.unauthenticated());
        return;
      }

      emit(AuthState.authenticated(session));
    } catch (_) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    emit(AuthState.loading(session: state.session));

    try {
      final session = await _loginWithEmby(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      emit(AuthState.authenticated(session));
    } catch (error) {
      emit(AuthState.failure('登录失败：$error'));
    }
  }

  Future<void> logout() async {
    await _logout();
    emit(const AuthState.unauthenticated());
  }
}
