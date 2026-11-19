class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.level,
    required this.points,
    required this.totalWeightKg,
    required this.rewards,
    required this.nextLevelPoints,
    this.avatarUrl,
    this.memberCode = '',
    this.role = 'user',
    this.levelProgressOverride,
  });

  final String name;
  final String email;
  final String level;
  final int points;
  final double totalWeightKg;
  final int rewards;
  final int nextLevelPoints;
  final String? avatarUrl;
  final String memberCode;
  final String role;
  final double? levelProgressOverride;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] is Map
        ? Map<String, dynamic>.from(json['stats'] as Map)
        : const <String, dynamic>{};
    return UserProfile(
      name: json['name'] as String? ?? 'Pengguna',
      email: json['email'] as String? ?? '',
      level: json['level'] as String? ?? 'Pemula',
      points: (json['points'] as num?)?.toInt() ?? 0,
      totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0,
      rewards: (stats['rewardsRedeemed'] as num?)?.toInt() ?? 0,
      nextLevelPoints: (json['nextLevelPoints'] as num?)?.toInt() ?? 100,
      avatarUrl: json['avatarUrl'] as String?,
      memberCode: json['memberCode'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      levelProgressOverride: (json['levelProgress'] as num?)?.toDouble(),
    );
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'TT';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  double get levelProgress =>
      levelProgressOverride ??
      (nextLevelPoints <= 0 ? 0 : (points / nextLevelPoints).clamp(0.0, 1.0));
}
