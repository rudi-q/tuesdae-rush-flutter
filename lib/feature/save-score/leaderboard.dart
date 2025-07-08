import 'package:flutter/material.dart';

import 'score_service.dart' show ScoreService;

showLeaderboard(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Color(0xFF1E3264).withValues(alpha: 0.8),
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E3264),
                Color(0xFF2A4A73),
                Color(0xFF1E3264),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFFFD700),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with trophy design
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA000),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: Color(0xFF1E3264),
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRAFFIC MASTERS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3264),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Global Leaderboard',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E3264).withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Color(0xFF1E3264),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Leaderboard content
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: ScoreService().getLeaderboard(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFD700).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading rankings...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF5722).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.warning_amber,
                                  color: Color(0xFFFF5722),
                                  size: 48,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load leaderboard',
                                style: TextStyle(
                                  color: Color(0xFFFF5722),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Check your connection and try again',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final scores = snapshot.data ?? [];
                      if (scores.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50).withValues(alpha: 0.3),
                                      Color(0xFF81C784).withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.emoji_events_outlined,
                                  color: Color(0xFFFFD700),
                                  size: 64,
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'No Traffic Masters Yet!',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Be the first to control the chaos\nand claim the crown!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: scores.length,
                        itemBuilder: (context, index) {
                          final score = scores[index];
                          final rank = index + 1;

                          // Special styling for top 3
                          Color rankColor;
                          Color bgColor;
                          IconData rankIcon;

                          if (rank == 1) {
                            rankColor = Color(0xFFFFD700); // Gold
                            bgColor = Color(0xFFFFD700).withValues(alpha: 0.15);
                            rankIcon = Icons.emoji_events;
                          } else if (rank == 2) {
                            rankColor = Color(0xFFC0C0C0); // Silver
                            bgColor = Color(0xFFC0C0C0).withValues(alpha: 0.15);
                            rankIcon = Icons.workspace_premium;
                          } else if (rank == 3) {
                            rankColor = Color(0xFFCD7F32); // Bronze
                            bgColor = Color(0xFFCD7F32).withValues(alpha: 0.15);
                            rankIcon = Icons.military_tech;
                          } else {
                            rankColor = Color(0xFF64B5F6); // Blue for others
                            bgColor = Color(0xFF64B5F6).withValues(alpha: 0.1);
                            rankIcon = Icons.directions_car;
                          }

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  bgColor,
                                  bgColor.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: rankColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Rank indicator
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          rankColor,
                                          rankColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: rankColor.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          rankIcon,
                                          color: rank <= 3 ? Color(0xFF1E3264) : Colors.white,
                                          size: rank <= 3 ? 20 : 18,
                                        ),
                                        Text(
                                          '#$rank',
                                          style: TextStyle(
                                            color: rank <= 3 ? Color(0xFF1E3264) : Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 16),

                                  // Score info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.traffic,
                                              color: Color(0xFFFFD700),
                                              size: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '${score['best_score']} Points',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF4CAF50).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${(score['avg_success_rate'] ?? 0).toStringAsFixed(1)}% Success',
                                                style: TextStyle(
                                                  color: Color(0xFF4CAF50),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF2196F3).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${score['games_played']} Games',
                                                style: TextStyle(
                                                  color: Color(0xFF2196F3),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}