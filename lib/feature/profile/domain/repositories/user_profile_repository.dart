import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId);
  
  /// Get user profile by email
  Future<UserProfile?> getUserProfileByEmail(String email);
  
  /// Update user profile information
  Future<void> updateUserProfile(UserProfile profile);
  
  /// Get user's recent game scores
  Future<List<GameScore>> getRecentGameScores(String userId, {int limit = 10});
  
  /// Get user's game statistics
  Future<UserGameStats> getUserGameStats(String userId);
  
  /// Get user's rank in global leaderboard
  Future<int?> getUserRank(String userId);
}

class GameScore {
  final String id;
  final String userId;
  final int score;
  final String difficultyLevel;
  final int carsPassed;
  final double successRate;
  final Map<String, dynamic> objectivesCompleted;
  final DateTime createdAt;

  const GameScore({
    required this.id,
    required this.userId,
    required this.score,
    required this.difficultyLevel,
    required this.carsPassed,
    required this.successRate,
    required this.objectivesCompleted,
    required this.createdAt,
  });

  GameScore copyWith({
    String? id,
    String? userId,
    int? score,
    String? difficultyLevel,
    int? carsPassed,
    double? successRate,
    Map<String, dynamic>? objectivesCompleted,
    DateTime? createdAt,
  }) {
    return GameScore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      carsPassed: carsPassed ?? this.carsPassed,
      successRate: successRate ?? this.successRate,
      objectivesCompleted: objectivesCompleted ?? this.objectivesCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
