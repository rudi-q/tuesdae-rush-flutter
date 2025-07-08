import 'package:flutter/material.dart';
import 'package:tuesdae_rush/feature/profile/domain/entities/user_profile.dart';
import 'package:tuesdae_rush/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:tuesdae_rush/feature/profile/infrastructure/datasources/supabase_user_profile_datasource.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E3264),
      appBar: AppBar(
        backgroundColor: Color(0xFF2A4A73),
        elevation: 0,
        title: Text(
          userProfile.displayName ?? 'Player Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3264), Color(0xFF2A4A73)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              SizedBox(height: 24),
              _buildStats(),
              SizedBox(height: 24),
              _buildRecentGames(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A4A73), Color(0xFF1E3264)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFFFFD700),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF4CAF50),
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            userProfile.displayName ?? 'Unknown Player',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          if (userProfile.email != null)
            Text(
              userProfile.email!,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFFD700),
              ),
            ),
          if (userProfile.createdAt != null)
            Text(
              'Playing since ${_formatDate(userProfile.createdAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = userProfile.stats;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A4A73), Color(0xFF1E3264)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Color(0xFFFFD700),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Game Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildStatRow('🎮 Total Games', stats.totalGames.toString()),
          _buildStatRow('📈 Total Score', stats.totalScore.toString()),
          _buildStatRow('🏆 Best Score', stats.bestScore.toString()),
          _buildStatRow('📊 Average Success Rate', '${stats.averageSuccessRate.toStringAsFixed(1)}%'),
          _buildStatRow('⭐ Favorite Difficulty', stats.favoriteDeffiDifficulty),
          _buildStatRow('🚗 Cars Passed', stats.totalCarsPassed.toString()),
          _buildStatRow('💥 Cars Crashed', stats.totalCarsCrashed.toString()),
          _buildStatRow('🔥 Current Streak', stats.currentStreak.toString()),
          _buildStatRow('🏅 Longest Streak', stats.longestStreak.toString()),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  fontSize: 14,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGames() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A4A73), Color(0xFF1E3264)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Color(0xFFFFD700),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Recent Games',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          FutureBuilder<List<GameScore>>(
            future: _loadRecentGames(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load recent games',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final recentGames = snapshot.data ?? [];
              
              if (recentGames.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.games,
                          size: 48,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No games played yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: recentGames.take(5).map((game) => _buildGameRow(game)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildGameRow(GameScore game) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Difficulty indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getDifficultyColor(game.difficultyLevel),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          
          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: ${game.score}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDateTime(game.createdAt),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      game.difficultyLevel.toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(game.difficultyLevel),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '🚗 ${game.carsPassed}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${game.successRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<List<GameScore>> _loadRecentGames() async {
    try {
      final dataSource = SupabaseUserProfileDataSource();
      return await dataSource.getRecentGameScores(userProfile.userId, limit: 5);
    } catch (e) {
      return [];
    }
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Color(0xFF4CAF50); // Green
      case 'medium':
        return Color(0xFFFF9800); // Orange
      case 'hard':
        return Color(0xFFFF5722); // Red
      case 'extreme':
        return Color(0xFF9C27B0); // Purple
      case 'insane':
        return Color(0xFFE91E63); // Pink
      default:
        return Colors.grey;
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
