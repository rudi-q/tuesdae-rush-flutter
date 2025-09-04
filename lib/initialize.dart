import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/firebase_options.dart';
import 'core/services/supabase_config.dart';
import 'feature/gameplay/config/game_config.dart';
import 'feature/gameplay/domain/game_state.dart';

Future<void> initializeApp() async {
  // Validate GameConfig before initializing anything else
  _validateGameConfig();
  
  // Initialize Firebase with proper error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
      print('Continuing without Firebase for development');
    }
  }

  // Initialize Supabase with proper error handling
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    if (kDebugMode) {
      print('Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Supabase initialization failed: $e');
      print('Continuing without Supabase for development');
    }
  }
}

/// Validates GameConfig to ensure all configurations are valid
void _validateGameConfig() {
  if (kDebugMode) {
    print('Validating GameConfig...');
  }
  
  // Validate car type distribution
  if (!GameConfig.validateCarDistribution()) {
    throw AssertionError(
      'GameConfig validation failed: Car type distribution does not sum to 1.0. '
      'Check GameConfig.carSpawning.typeDistribution values.',
    );
  }
  
  // Validate difficulty configurations exist
  for (Difficulty difficulty in Difficulty.values) {
    try {
      GameConfig.getDifficulty(difficulty);
    } catch (e) {
      throw AssertionError(
        'GameConfig validation failed: Missing difficulty configuration for $difficulty',
      );
    }
  }
  
  // Validate car configurations exist
  for (CarType carType in CarType.values) {
    try {
      GameConfig.getCarConfig(carType);
    } catch (e) {
      throw AssertionError(
        'GameConfig validation failed: Missing car configuration for $carType',
      );
    }
  }
  
  // Validate objectives configuration
  if (GameConfig.objectives.definitions.isEmpty) {
    throw AssertionError(
      'GameConfig validation failed: No objectives defined',
    );
  }
  
  // Validate positive values for critical game mechanics
  if (GameConfig.gameOver.maxWaitingCars <= 0) {
    throw AssertionError(
      'GameConfig validation failed: maxWaitingCars must be positive',
    );
  }
  
  if (GameConfig.gameOver.minSuccessRate < 0 || GameConfig.gameOver.minSuccessRate > 100) {
    throw AssertionError(
      'GameConfig validation failed: minSuccessRate must be between 0 and 100',
    );
  }
  
  if (GameConfig.timing.frameTimeSeconds <= 0) {
    throw AssertionError(
      'GameConfig validation failed: frameTimeSeconds must be positive',
    );
  }
  
  // Validate physics constants
  if (GameConfig.physics.stopDistanceFromIntersection <= 0 ||
      GameConfig.physics.safeFollowingDistanceMultiplier <= 0 ||
      GameConfig.physics.offScreenBuffer <= 0) {
    throw AssertionError(
      'GameConfig validation failed: Physics constants must be positive',
    );
  }
  
  if (kDebugMode) {
    print('GameConfig validation passed! ✓');
  }
}
