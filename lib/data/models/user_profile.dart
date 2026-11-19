class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.level,
    required this.points,
    required this.totalWeightKg,
    required this.rewards,
    required this.nextLevelPoints,
  });

  final String name;
  final String email;
  final String level;
  final int points;
  final double totalWeightKg;
  final int rewards;
  final int nextLevelPoints;

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  double get levelProgress {
    if (nextLevelPoints <= 0) return 0;
    return (points / nextLevelPoints).clamp(0.0, 1.0);
  }
}
