import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/analytics_service.dart';
import '../../feature/auth/auth_service.dart';
import '../../feature/gameplay/presentation/game.dart';
import '../../feature/profile/domain/entities/user_profile.dart';
import '../../feature/profile/data/supabase_user_profile_datasource.dart';
import '../../feature/profile/presentation/profile_screen.dart';

class AppRouter {
  static GoRouter get router {
    final analytics = AnalyticsService.analytics;
    
    return GoRouter(
      initialLocation: '/',
      observers: analytics != null ? [
        FirebaseAnalyticsObserver(analytics: analytics),
      ] : [],
      routes: [
      // Game route (home)
      GoRoute(
        path: '/',
        name: 'game',
        builder: (context, state) => const TuesdaeRushGame(),
      ),
      
      // Profile route
      GoRoute(
        path: '/player/:username',
        name: 'profile',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return ProfileScreenWrapper(username: username);
        },
      ),
  ],
  
  // Error page
    errorBuilder: (context, state) => Scaffold(
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
    ));
  }
}

/// Wrapper widget that handles loading profile data
class ProfileScreenWrapper extends StatelessWidget {
  final String username;

  const ProfileScreenWrapper({super.key, required this.username});

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
                  Text('Loading $username\'s profile...'),
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
                  Text('User "$username" not found'),
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
    
    // Try to get by email first (since we might not have a username field)
    // This is a simplified approach - you might want to enhance this based on your needs
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && currentUser.email == username) {
        return await dataSource.getUserProfile(currentUser.id);
      }
      
      // If username doesn't match current user's email, try searching by email
      return await dataSource.getUserProfileByEmail(username);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}
