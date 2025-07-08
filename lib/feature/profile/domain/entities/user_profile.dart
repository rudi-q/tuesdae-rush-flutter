class UserProfile {
  final String userId;
  final String? email;
  final String? displayName;
  final DateTime? createdAt;
  final UserGameStats stats;

  const UserProfile({
    required this.userId,
    this.email,
    this.displayName,
    this.createdAt,
    required this.stats,
  });

  UserProfile copyWith({
    String? userId,
    String? email,
    String? displayName,
    DateTime? createdAt,
    UserGameStats? stats,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }
}

class UserGameStats {
  final int totalGames;
  final int totalScore;
  final int bestScore;
  final double averageSuccessRate;
  final int totalCarsPassed;
  final int totalCarsCrashed;
  final Map<String, int> bestScoresByDifficulty;
  final Map<String, int> gamesByDifficulty;
  final DateTime? lastPlayedAt;
  final int currentStreak;
  final int longestStreak;

  const UserGameStats({
    required this.totalGames,
    required this.totalScore,
    required this.bestScore,
    required this.averageSuccessRate,
    required this.totalCarsPassed,
    required this.totalCarsCrashed,
    required this.bestScoresByDifficulty,
    required this.gamesByDifficulty,
    this.lastPlayedAt,
    required this.currentStreak,
    required this.longestStreak,
  });

  double get averageScore => totalGames > 0 ? totalScore / totalGames : 0.0;

  double get crashRate =>
      totalCarsPassed > 0
          ? (totalCarsCrashed / (totalCarsPassed + totalCarsCrashed)) * 100
          : 0.0;

  String get favoriteDeffiDifficulty {
    if (gamesByDifficulty.isEmpty) return 'None';
    return gamesByDifficulty.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  UserGameStats copyWith({
    int? totalGames,
    int? totalScore,
    int? bestScore,
    double? averageSuccessRate,
    int? totalCarsPassed,
    int? totalCarsCrashed,
    Map<String, int>? bestScoresByDifficulty,
    Map<String, int>? gamesByDifficulty,
    DateTime? lastPlayedAt,
    int? currentStreak,
    int? longestStreak,
  }) {
    return UserGameStats(
      totalGames: totalGames ?? this.totalGames,
      totalScore: totalScore ?? this.totalScore,
      bestScore: bestScore ?? this.bestScore,
      averageSuccessRate: averageSuccessRate ?? this.averageSuccessRate,
      totalCarsPassed: totalCarsPassed ?? this.totalCarsPassed,
      totalCarsCrashed: totalCarsCrashed ?? this.totalCarsCrashed,
      bestScoresByDifficulty:
          bestScoresByDifficulty ?? this.bestScoresByDifficulty,
      gamesByDifficulty: gamesByDifficulty ?? this.gamesByDifficulty,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}
