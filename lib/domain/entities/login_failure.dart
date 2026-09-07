enum LoginFailureReason {
  serverUnreachable,
  invalidCredentials,
  unsupportedServer,
  unknown,
}

final class LoginFailure implements Exception {
  const LoginFailure(this.reason);

  final LoginFailureReason reason;

  @override
  String toString() => 'LoginFailure(${reason.name})';
}
