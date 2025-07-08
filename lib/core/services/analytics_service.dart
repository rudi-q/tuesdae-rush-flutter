import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  
  static FirebaseAnalytics? get analytics {
    if (_analytics == null) {
      try {
        // Check if Firebase is initialized
        if (Firebase.apps.isNotEmpty) {
          _analytics = FirebaseAnalytics.instance;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Firebase Analytics not available: $e');
        }
      }
    }
    return _analytics;
  }
  
  // Helper method to safely log events
  static Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      final analyticsInstance = analytics;
      if (analyticsInstance != null) {
        await analyticsInstance.logEvent(name: name, parameters: parameters);
      } else if (kDebugMode) {
        print('Analytics not available - would log: $name with params: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log analytics event $name: $e');
      }
    }
  }

  // Game Events
  static Future<void> logGameStart() async {
    await _logEvent('game_start');
  }
  
  static Future<void> logGameOver(String reason, int score, int carsPassed, int carsCrashed, double successRate) async {
    await _logEvent('game_over', {
      'reason': reason,
      'score': score,
      'cars_passed': carsPassed,
      'cars_crashed': carsCrashed,
      'success_rate': successRate,
    });
  }
  
  static Future<void> logGamePause() async {
    await _logEvent('game_pause');
  }
  
  static Future<void> logGameResume() async {
    await _logEvent('game_resume');
  }
  
  static Future<void> logGameRestart() async {
    await _logEvent('game_restart');
  }
  
  // Player Actions
  static Future<void> logDifficultyChange(String difficulty) async {
    await _logEvent('difficulty_change', {
      'difficulty': difficulty,
    });
  }
  
  static Future<void> logTrafficLightToggle(String direction) async {
    await _logEvent('traffic_light_toggle', {
      'direction': direction,
    });
  }
  
  // Game Progress
  static Future<void> logObjectiveCompleted(String objective) async {
    await _logEvent('objective_completed', {
      'objective': objective,
    });
  }
  
  static Future<void> logScoreMilestone(int score) async {
    await _logEvent('score_milestone', {
      'score': score,
    });
  }
  
  static Future<void> logCarsPassed(int count) async {
    await _logEvent('cars_passed_milestone', {
      'cars_count': count,
    });
  }
  
  // Settings
  static Future<void> logAudioToggle(bool enabled) async {
    await _logEvent('audio_toggle', {
      'enabled': enabled,
    });
  }
  
  static Future<void> logThemeToggle(bool isDarkMode) async {
    await _logEvent('theme_toggle', {
      'is_dark_mode': isDarkMode,
    });
  }
  
  static Future<void> logFullscreenToggle(bool isFullscreen) async {
    await _logEvent('fullscreen_toggle', {
      'is_fullscreen': isFullscreen,
    });
  }
  
  // Performance Metrics
  static Future<void> logGameSession(int duration, int score, int carsPassed, String difficulty) async {
    await _logEvent('game_session', {
      'duration_seconds': duration,
      'final_score': score,
      'cars_passed': carsPassed,
      'difficulty': difficulty,
    });
  }
  
  // Custom Events for Traffic Management
  static Future<void> logTrafficJam(int waitingCars) async {
    await _logEvent('traffic_jam', {
      'waiting_cars': waitingCars,
    });
  }
  
  static Future<void> logCarCrash(String crashType) async {
    await _logEvent('car_crash', {
      'crash_type': crashType,
    });
  }
  
  static Future<void> logEfficiencyAchievement(double efficiency) async {
    await _logEvent('efficiency_achievement', {
      'efficiency_percentage': efficiency,
    });
  }
}
