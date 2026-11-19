class ApiAuthSession {
  const ApiAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.profile,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> profile;

  factory ApiAuthSession.fromJson(Map<String, dynamic> json) => ApiAuthSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    profile: Map<String, dynamic>.from(json['user'] as Map),
  );
}
