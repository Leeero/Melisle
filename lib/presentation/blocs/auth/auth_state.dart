import 'package:cross_platform_music_player/domain/entities/auth_session.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  const AuthState.loading({this.session})
      : status = AuthStatus.loading,
        errorMessage = null;

  const AuthState.authenticated(AuthSession this.session)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        session = null,
        errorMessage = null;

  const AuthState.failure(String this.errorMessage)
      : status = AuthStatus.failure,
        session = null;

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
}
