import 'package:flutter/material.dart';
import 'package:tuesdae_rush/feature/profile/domain/entities/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userProfile.displayName ?? 'Player Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildStats(),
            SizedBox(height: 24),
            _buildRecentGames(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueGrey.shade200,
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.blueGrey.shade600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            userProfile.displayName ?? 'Unknown Player',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = userProfile.stats;

    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          _buildStatRow('Total Games', stats.totalGames.toString()),
          _buildStatRow('Total Score', stats.totalScore.toString()),
          _buildStatRow('Best Score', stats.bestScore.toString()),
          _buildStatRow('Average Success Rate', '${stats.averageSuccessRate.toStringAsFixed(1)}%'),
          _buildStatRow('Favorite Difficulty', stats.favoriteDeffiDifficulty),
          _buildStatRow('Cars Passed', stats.totalCarsPassed.toString()),
          _buildStatRow('Cars Crashed', stats.totalCarsCrashed.toString()),
          _buildStatRow('Current Streak', stats.currentStreak.toString()),
          _buildStatRow('Longest Streak', stats.longestStreak.toString()),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames() {
    // Placeholder for recent games, to be replaced with actual data
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text('Recent Games will be displayed here'),
      ),
    );
  }
}
