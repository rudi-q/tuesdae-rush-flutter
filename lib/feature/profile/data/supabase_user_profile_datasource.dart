import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/util/helper.dart';
import '../domain/entities/user_profile.dart';
import '../domain/repositories/user_profile_repository.dart';

class SupabaseUserProfileDataSource implements UserProfileRepository {
  final SupabaseClient client;

  SupabaseUserProfileDataSource() : client = Supabase.instance.client;

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Get user from auth.users (this requires service role access or RPC function)
      // For now, let's get the current user if it matches the requested userId
      final currentUser = client.auth.currentUser;
      if (currentUser == null || currentUser.id != userId) {
        return null; // For security, only return profile for current user
      }

      // Get pseudonym from user_pseudonyms table
      final pseudonymResult =
          await client
              .from('user_pseudonyms')
              .select('username')
              .eq('user_id', userId)
              .maybeSingle();

      final stats = await getUserGameStats(userId);

      return UserProfile(
        userId: userId,
        email: currentUser.email,
        displayName: currentUser.userMetadata?['display_name'] as String?,
        pseudonym: pseudonymResult?['username'] as String?,
        createdAt: DateTime.tryParse(currentUser.createdAt),
        stats: stats,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    try {
      // For security, only return profile if it matches current user's email
      final currentUser = client.auth.currentUser;
      if (currentUser == null || currentUser.email != email) {
        return null;
      }

      return getUserProfile(currentUser.id);
    } catch (e) {
      return null;
    }
  }

  Future<UserProfile?> getUserProfileByPseudonym(String pseudonym) async {
    try {
      // Get user id using the pseudonym
      final pseudonymResult =
          await client
              .from('user_pseudonyms')
              .select('user_id')
              .eq('username', pseudonym)
              .maybeSingle();

      if (pseudonymResult == null) {
        return null; // Pseudonym not found
      }

      final userId = pseudonymResult['user_id'] as String;

      // Fetch public game stats
      final stats = await getUserGameStats(userId);

      // Return profile without exposing sensitive data
      return UserProfile(
        userId: '', // Hide real user ID
        email: null, // Don't expose email
        displayName: pseudonym, // Use pseudonym as display name
        pseudonym: pseudonym,
        createdAt: null, // Optional: don't expose creation date
        stats: stats,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      // Update user metadata in auth
      await client.auth.updateUser(
        UserAttributes(data: {'display_name': profile.displayName}),
      );
    } catch (e) {
      // Handle update errors
    }
  }

  @override
  Future<List<GameScore>> getRecentGameScores(
    String userId, {
    int limit = 10,
  }) async {
    try {
      devPrint('🔍 getRecentGameScores: Fetching games for user: $userId');
      final response = await client
          .from('game_scores')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      devPrint(
        '🔍 getRecentGameScores: Response length: ${(response as List).length}',
      );

      return (response as List)
          .map(
            (e) => GameScore(
              id: e['id'].toString(),
              userId: e['user_id'],
              score: e['score'],
              difficultyLevel: e['difficulty_level'],
              carsPassed: e['cars_passed'],
              successRate: (e['success_rate'] as num).toDouble(),
              objectivesCompleted: e['objectives_completed'] ?? {},
              createdAt: DateTime.tryParse(e['created_at']) ?? DateTime.now(),
            ),
          )
          .toList();
    } catch (e) {
      devPrint('❌ getRecentGameScores Error: $e');
      return [];
    }
  }

  @override
  Future<UserGameStats> getUserGameStats(String userId) async {
    try {
      devPrint('📊 getUserGameStats: Fetching stats for user: $userId');
      // Get all game scores for this user
      final response = await client
          .from('game_scores')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      devPrint(
        '📊 getUserGameStats: Response length: ${(response as List).length}',
      );

      if (response.isEmpty) {
        return const UserGameStats(
          totalGames: 0,
          totalScore: 0,
          bestScore: 0,
          averageSuccessRate: 0.0,
          totalCarsPassed: 0,
          totalCarsCrashed: 0,
          bestScoresByDifficulty: {},
          gamesByDifficulty: {},
          currentStreak: 0,
          longestStreak: 0,
        );
      }

      final scores = response as List;

      // Calculate stats
      final totalGames = scores.length;
      final totalScore = scores.fold<int>(
        0,
        (sum, score) => sum + (score['score'] as int),
      );
      final bestScore = scores.fold<int>(
        0,
        (best, score) =>
            (score['score'] as int) > best ? (score['score'] as int) : best,
      );
      final totalCarsPassed = scores.fold<int>(
        0,
        (sum, score) => sum + (score['cars_passed'] as int),
      );
      final averageSuccessRate =
          scores.isNotEmpty
              ? scores.fold<double>(
                    0.0,
                    (sum, score) =>
                        sum + (score['success_rate'] as num).toDouble(),
                  ) /
                  scores.length
              : 0.0;

      // Calculate difficulty stats
      final Map<String, int> bestScoresByDifficulty = {};
      final Map<String, int> gamesByDifficulty = {};

      for (final score in scores) {
        final difficulty = score['difficulty_level'] as String;
        final scoreValue = score['score'] as int;

        gamesByDifficulty[difficulty] =
            (gamesByDifficulty[difficulty] ?? 0) + 1;
        bestScoresByDifficulty[difficulty] =
            scoreValue > (bestScoresByDifficulty[difficulty] ?? 0)
                ? scoreValue
                : (bestScoresByDifficulty[difficulty] ?? 0);
      }

      final lastPlayedAt =
          scores.isNotEmpty
              ? DateTime.tryParse(scores.first['created_at'])
              : null;

      return UserGameStats(
        totalGames: totalGames,
        totalScore: totalScore,
        bestScore: bestScore,
        averageSuccessRate: averageSuccessRate,
        totalCarsPassed: totalCarsPassed,
        totalCarsCrashed: 0, // Not tracked in current schema
        bestScoresByDifficulty: bestScoresByDifficulty,
        gamesByDifficulty: gamesByDifficulty,
        lastPlayedAt: lastPlayedAt,
        currentStreak: 0, // Would need more complex calculation
        longestStreak: 0, // Would need more complex calculation
      );
    } catch (e) {
      // Handle errors gracefully
      return const UserGameStats(
        totalGames: 0,
        totalScore: 0,
        bestScore: 0,
        averageSuccessRate: 0.0,
        totalCarsPassed: 0,
        totalCarsCrashed: 0,
        bestScoresByDifficulty: {},
        gamesByDifficulty: {},
        currentStreak: 0,
        longestStreak: 0,
      );
    }
  }

  @override
  Future<int?> getUserRank(String userId) async {
    try {
      final response = await client.rpc(
        'get_user_rank',
        params: {'user_uuid': userId},
      );
      return response as int?;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveDisplayName(String userId, String displayName) async {
    try {
      await client.auth.updateUser(
        UserAttributes(data: {'display_name': displayName}),
      );
    } catch (e) {
      throw Exception('Failed to save display name: $e');
    }
  }

  Future<void> updatePseudonym(String userId, String newPseudonym) async {
    try {
      await client
          .from('user_pseudonyms')
          .update({
            'username': newPseudonym,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Check if the update was successful
      // If no rows were affected, the user might not have a pseudonym record yet
      // In that case, create one
      final existingRecord =
          await client
              .from('user_pseudonyms')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

      if (existingRecord == null) {
        await client.from('user_pseudonyms').insert({
          'user_id': userId,
          'username': newPseudonym,
        });
      }
    } catch (e) {
      if (e.toString().contains('unique constraint') ||
          e.toString().contains('duplicate')) {
        throw Exception(
          'Username already taken. Please choose a different one.',
        );
      }
      throw Exception('Failed to update username: $e');
    }
  }
}
