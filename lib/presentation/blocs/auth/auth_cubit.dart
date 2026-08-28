import 'dart:async';

import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/application/usecases/login_with_emby.dart';
import 'package:cross_platform_music_player/application/usecases/logout.dart';
import 'package:cross_platform_music_player/application/usecases/restore_session.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/dev_login_credentials.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginWithEmby loginWithEmby,
    required RestoreSession restoreSession,
    required Logout logout,
    required FetchPlaylists fetchPlaylists,
    AuthDevLoginCredentials? devLoginCredentials,
    Future<void> Function()? clearSessionData,
  }) : _loginWithEmby = loginWithEmby,
       _restoreSession = restoreSession,
       _logout = logout,
       _fetchPlaylists = fetchPlaylists,
       _devLoginCredentials = devLoginCredentials,
       _clearSessionData = clearSessionData,
       super(const AuthState.unknown()) {
    restore();
  }

  final LoginWithEmby _loginWithEmby;
  final RestoreSession _restoreSession;
  final Logout _logout;
  final FetchPlaylists _fetchPlaylists;
  final AuthDevLoginCredentials? _devLoginCredentials;
  final Future<void> Function()? _clearSessionData;

  Future<void> restore() async {
    try {
      final session = await _restoreSession();
      if (session == null) {
        await _loginWithDevCredentialsOrUnauthenticated();
        return;
      }

      emit(AuthState.authenticated(session));
      _prefetchPlaylists();
    } catch (_) {
      await _loginWithDevCredentialsOrUnauthenticated();
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
      _prefetchPlaylists();
    } catch (error) {
      emit(AuthState.failure('登录失败：$error'));
    }
  }

  void _prefetchPlaylists() {
    // 预热歌单首页缓存，首次打开歌单页可直接命中；失败不影响认证流程，
    // 页面打开时会走正常加载。
    unawaited(() async {
      try {
        await _fetchPlaylists(limit: FetchPlaylists.defaultPageSize);
      } catch (error, stackTrace) {
        debugPrint('AuthCubit.prefetchPlaylists 失败：$error\n$stackTrace');
      }
    }());
  }

  Future<void> logout() async {
    try {
      await _clearSessionData?.call();
    } catch (error, stackTrace) {
      debugPrint('AuthCubit.clearSessionData 失败：$error\n$stackTrace');
    }
    await _logout();
    emit(const AuthState.unauthenticated());
  }

  Future<void> _loginWithDevCredentialsOrUnauthenticated() async {
    final credentials = _devLoginCredentials;
    if (credentials == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    await login(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
    );
  }
}
