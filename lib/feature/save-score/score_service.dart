import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/util/helper.dart';
import '../auth/auth_service.dart';

class ScoreService {
  static final _instance = ScoreService._internal();
  factory ScoreService() => _instance;
  ScoreService._internal();

  // Save score to Supabase
  Future<void> saveScore({
    required int score,
    required String difficulty,
    required int carsPassed,
    required double successRate,
    required Map<String, dynamic> objectives,
  }) async {
    if (!AuthService().isAuthenticated) {
      // Cache locally if not authenticated
      await _saveScoreLocally(
        score,
        difficulty,
        carsPassed,
        successRate,
        objectives,
      );
      return;
    }

    try {
      await Supabase.instance.client.from('game_scores').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'score': score,
        'difficulty_level': difficulty,
        'cars_passed': carsPassed,
        'success_rate': successRate,
        'objectives_completed': objectives,
      });

      // Also save locally as backup
      await _saveScoreLocally(
        score,
        difficulty,
        carsPassed,
        successRate,
        objectives,
      );
    } catch (e) {
      // Fallback to local storage if online save fails
      await _saveScoreLocally(
        score,
        difficulty,
        carsPassed,
        successRate,
        objectives,
      );
      rethrow;
    }
  }

  // Get user's best scores from Supabase
  Future<List<Map<String, dynamic>>> getUserScores() async {
    if (!AuthService().isAuthenticated) {
      return await _getLocalScores();
    }

    try {
      final response = await Supabase.instance.client
          .from('game_scores')
          .select()
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .order('score', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback to local scores if online fetch fails
      return await _getLocalScores();
    }
  }

  // Get leaderboard (top scores across all users)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    if (!AuthService().isAuthenticated) {
      return [];
    }

    try {
      final response = await Supabase.instance.client
          .from('leaderboard')
          .select()
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Sync local scores to Supabase when user authenticates
  Future<void> syncLocalScores() async {
    if (!AuthService().isAuthenticated) return;

    try {
      final localScores = await _getLocalScores();
      for (final score in localScores) {
        await Supabase.instance.client.from('game_scores').insert({
          'user_id': Supabase.instance.client.auth.currentUser!.id,
          'score': score['score'],
          'difficulty_level': score['difficulty_level'],
          'cars_passed': score['cars_passed'],
          'success_rate': score['success_rate'],
          'objectives_completed': score['objectives_completed'],
        });
      }

      // Clear local scores after successful sync
      await _clearLocalScores();
    } catch (e) {
      // Keep local scores if sync fails
      devPrint('Failed to sync local scores: $e');
    }
  }

  // Save score locally using SharedPreferences
  Future<void> _saveScoreLocally(
    int score,
    String difficulty,
    int carsPassed,
    double successRate,
    Map<String, dynamic> objectives,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final localScores = await _getLocalScores();

    final newScore = {
      'score': score,
      'difficulty_level': difficulty,
      'cars_passed': carsPassed,
      'success_rate': successRate,
      'objectives_completed': objectives,
      'created_at': DateTime.now().toIso8601String(),
    };

    localScores.add(newScore);

    // Keep only top 10 local scores
    localScores.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );
    if (localScores.length > 10) {
      localScores.removeRange(10, localScores.length);
    }

    await prefs.setString('local_scores', jsonEncode(localScores));
  }

  // Get local scores from SharedPreferences
  Future<List<Map<String, dynamic>>> _getLocalScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString('local_scores');

    if (scoresJson == null) return [];

    try {
      final scoresList = jsonDecode(scoresJson) as List;
      return scoresList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Clear local scores
  Future<void> _clearLocalScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_scores');
  }

  // Get user's personal best score
  Future<int> getPersonalBest() async {
    final scores = await getUserScores();
    if (scores.isEmpty) return 0;

    return scores.first['score'] as int;
  }
}
