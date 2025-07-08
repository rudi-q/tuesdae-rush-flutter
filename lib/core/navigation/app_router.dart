import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/analytics_service.dart';
import '../../feature/auth/auth_service.dart';
import '../../feature/gameplay/presentation/game.dart';
import '../../feature/profile/data/supabase_user_profile_datasource.dart';
import '../../feature/profile/domain/entities/user_profile.dart';
import '../../feature/profile/presentation/profile_screen.dart';

class AppRouter {
  static GoRouter get router {
    final analytics = AnalyticsService.analytics;

    return GoRouter(
      initialLocation: '/',
      observers:
          analytics != null
              ? [FirebaseAnalyticsObserver(analytics: analytics)]
              : [],
      routes: [
        // Game route (home)
        GoRoute(
          path: '/',
          name: 'game',
          builder: (context, state) => const TuesdaeRushGame(),
        ),

        // Profile route
        GoRoute(
          path: '/player/:pseudonym',
          name: 'profile',
          builder: (context, state) {
            final pseudonym = state.pathParameters['pseudonym']!;
            return ProfileScreenWrapper(pseudonym: pseudonym);
          },
        ),
      ],

      // Error page
      errorBuilder:
          (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Page not found: ${state.matchedLocation}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

/// Wrapper widget that handles loading profile data
class ProfileScreenWrapper extends StatelessWidget {
  final String pseudonym;

  const ProfileScreenWrapper({super.key, required this.pseudonym});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _loadUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Loading Profile...')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading @$pseudonym\'s profile...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load profile'),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        final userProfile = snapshot.data;
        if (userProfile == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Profile Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('User "@$pseudonym" not found'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        return ProfileScreen(userProfile: userProfile);
      },
    );
  }

  Future<UserProfile?> _loadUserProfile() async {
    // Check if user is authenticated
    if (!AuthService().isAuthenticated) {
      throw Exception('You must be signed in to view profiles');
    }

    final dataSource = SupabaseUserProfileDataSource();

    // Get user profile by pseudonym
    try {
      return await dataSource.getUserProfileByPseudonym(pseudonym);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}
