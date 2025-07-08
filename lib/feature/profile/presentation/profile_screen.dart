import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tuesdae_rush/feature/profile/data/supabase_user_profile_datasource.dart';
import 'package:tuesdae_rush/feature/profile/domain/entities/user_profile.dart';
import 'package:tuesdae_rush/feature/profile/domain/repositories/user_profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileScreen({super.key, required this.userProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile currentProfile;
  bool isEditingName = false;
  bool isEditingPseudonym = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pseudonymController = TextEditingController();
  
  /// Check if the current user is viewing their own profile
  /// Returns true only if:
  /// - User is authenticated (currentUser != null)
  /// - Profile has a valid userId (not empty - indicates authentic user profile)
  /// - Current user ID matches the profile's user ID
  /// 
  /// This prevents edit functionality from being shown when viewing profiles via shared links
  bool get _isOwnProfile {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return currentUser != null && 
           currentProfile.userId.isNotEmpty && 
           currentProfile.userId == currentUser.id;
  }

  @override
  void initState() {
    super.initState();
    currentProfile = widget.userProfile;
    _nameController.text = currentProfile.displayName ?? '';
    _pseudonymController.text = currentProfile.pseudonym ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pseudonymController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E3264),
      appBar: AppBar(
        backgroundColor: Color(0xFF2A4A73),
        elevation: 0,
        title: Text(
          currentProfile.pseudonym != null
              ? '@${currentProfile.pseudonym}'
              : (currentProfile.displayName ?? 'Anonymous Player'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              border: Border.all(color: Color(0xFFFFD700), width: 3),
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
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          SizedBox(height: 16),
          // Show pseudonym prominently - editable
          if (currentProfile.pseudonym != null)
            Column(
              children: [
                if (isEditingPseudonym && _isOwnProfile)
                  Row(
                    children: [
                      Text(
                        '@',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _pseudonymController,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter username',
                            hintStyle: TextStyle(
                              color: Color(0xFFFFD700).withValues(alpha: 0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFFFFD700)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Color(0xFFFFD700).withValues(alpha: 0.6),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFFFFD700)),
                            ),
                          ),
                          maxLength: 30,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '@${currentProfile.pseudonym}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (_isOwnProfile)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isEditingPseudonym = true;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFD700).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ),
                    ],
                  ),
                SizedBox(height: 8),
              ],
            ),

          // Pseudonym save/cancel buttons
          if (isEditingPseudonym && _isOwnProfile)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditingPseudonym = false;
                        _pseudonymController.text =
                            currentProfile.pseudonym ?? '';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Save button
                  GestureDetector(
                    onTap: _savePseudonym,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Editable display name section
          if (isEditingName && _isOwnProfile)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your display name',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFFFD700)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                    maxLength: 20,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentProfile.displayName?.isEmpty == false
                      ? currentProfile.displayName!
                      : 'Anonymous Player',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                if (_isOwnProfile)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditingName = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.edit, size: 16, color: Color(0xFFFFD700)),
                    ),
                  ),
              ],
            ),

          if (isEditingName && _isOwnProfile)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditingName = false;
                        _nameController.text = currentProfile.displayName ?? '';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Save button
                  GestureDetector(
                    onTap: _saveDisplayName,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 8),
          if (currentProfile.email != null)
            Text(
              currentProfile.email!,
              style: TextStyle(fontSize: 14, color: Color(0xFFFFD700)),
            ),
          if (currentProfile.createdAt != null)
            Text(
              'Playing since ${_formatDate(currentProfile.createdAt!)}',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = currentProfile.stats;

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
              Icon(Icons.bar_chart, color: Color(0xFFFFD700), size: 24),
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
          _buildStatRow(
            '📊 Average Success Rate',
            '${stats.averageSuccessRate.toStringAsFixed(1)}%',
          ),
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
                style: TextStyle(color: Colors.white, fontSize: 14),
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
              Icon(Icons.history, color: Color(0xFFFFD700), size: 24),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD700),
                      ),
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
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load recent games',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
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
                        Icon(Icons.games, size: 48, color: Colors.white54),
                        SizedBox(height: 8),
                        Text(
                          'No games played yet',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children:
                    recentGames
                        .take(5)
                        .map((game) => _buildGameRow(game))
                        .toList(),
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
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${game.successRate.toStringAsFixed(1)}%',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 12),
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

  Future<void> _savePseudonym() async {
    // Security check: only allow authenticated users to edit their own profile
    if (!_isOwnProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unauthorized: You can only edit your own profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newPseudonym = _pseudonymController.text.trim();

    if (newPseudonym.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPseudonym.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username must be at least 3 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPseudonym.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username must be 30 characters or less'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for valid characters (alphanumeric and underscore)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newPseudonym)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Username can only contain letters, numbers, and underscores',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final dataSource = SupabaseUserProfileDataSource();
      await dataSource.updatePseudonym(currentProfile.userId, newPseudonym);

      if (mounted) {
        setState(() {
          currentProfile = currentProfile.copyWith(pseudonym: newPseudonym);
          isEditingPseudonym = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Username updated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update username: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDisplayName() async {
    // Security check: only allow authenticated users to edit their own profile
    if (!_isOwnProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unauthorized: You can only edit your own profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Display name cannot be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newName.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Display name must be 20 characters or less'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final dataSource = SupabaseUserProfileDataSource();
      await dataSource.saveDisplayName(currentProfile.userId, newName);

      if (mounted) {
        setState(() {
          currentProfile = currentProfile.copyWith(displayName: newName);
          isEditingName = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Display name updated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update display name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<GameScore>> _loadRecentGames() async {
    try {
      final dataSource = SupabaseUserProfileDataSource();
      return await dataSource.getRecentGameScores(
        currentProfile.userId,
        limit: 5,
      );
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
