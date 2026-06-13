class RememberedSession {
  final bool enabled;
  final String? email;
  final DateTime? loginAt;
  final int? sessionVersion;

  const RememberedSession({
    required this.enabled,
    this.email,
    this.loginAt,
    this.sessionVersion,
  });

  const RememberedSession.disabled({String? email})
    : enabled = false,
      email = email,
      loginAt = null,
      sessionVersion = null;

  bool isExpired(Duration maxAge, {DateTime? now}) {
    final loginTime = loginAt;
    if (!enabled || loginTime == null) {
      return true;
    }

    return (now ?? DateTime.now()).difference(loginTime) > maxAge;
  }
}
