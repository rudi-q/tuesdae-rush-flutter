import 'package:flutter/material.dart';
import '../domain/game_state.dart';

/// 🎮 **TUESDAE RUSH GAME CONFIGURATION**
/// 
/// Central source of truth for all game rules, constants, and tunable parameters.
/// This file makes it easy to balance gameplay, run A/B tests, and maintain consistency.
class GameConfig {
  // ============================================================================
  // 🎯 DIFFICULTY CONFIGURATION
  // ============================================================================
  
  /// Difficulty progression settings
  static const Map<Difficulty, DifficultyConfig> difficulties = {
    Difficulty.easy: DifficultyConfig(
      carSpawnIntervalFrames: 90,     // ~1.5 seconds at 60 FPS
      carSpeed: 1.5,
      scoreMultiplier: 1.0,
      color: Color(0xFF2ECC71),       // Green
      displayName: 'Easy',
    ),
    Difficulty.medium: DifficultyConfig(
      carSpawnIntervalFrames: 60,     // 1 second at 60 FPS
      carSpeed: 2.0,
      scoreMultiplier: 1.5,
      color: Color(0xFFF39C12),       // Orange
      displayName: 'Medium',
    ),
    Difficulty.hard: DifficultyConfig(
      carSpawnIntervalFrames: 45,     // 0.75 seconds at 60 FPS
      carSpeed: 2.5,
      scoreMultiplier: 2.0,
      color: Color(0xFFE74C3C),       // Red
      displayName: 'Hard',
    ),
    Difficulty.extreme: DifficultyConfig(
      carSpawnIntervalFrames: 35,     // ~0.58 seconds at 60 FPS
      carSpeed: 3.0,
      scoreMultiplier: 2.5,
      color: Color(0xFF8E44AD),       // Purple
      displayName: 'Extreme',
    ),
    Difficulty.insane: DifficultyConfig(
      carSpawnIntervalFrames: 25,     // ~0.42 seconds at 60 FPS
      carSpeed: 3.5,
      scoreMultiplier: 3.0,
      color: Color(0xFF2C3E50),       // Dark blue
      displayName: 'Insane',
    ),
  };

  // ============================================================================
  // 🚗 CAR SPAWNING CONFIGURATION
  // ============================================================================
  
  static const CarSpawningConfig carSpawning = CarSpawningConfig(
    /// Car type distribution (must sum to 1.0)
    typeDistribution: {
      CarType.ambulance: 0.15,    // 15% - Emergency vehicle
      CarType.police: 0.075,      // 7.5% - Aggressive emergency vehicle  
      CarType.impatient: 0.15,    // 15% - May run red lights
      CarType.tractor: 0.075,     // 7.5% - Super slow with exhaust
      CarType.schoolBus: 0.20,    // 20% - Extra long with flashing lights
      CarType.regular: 0.35,      // 35% - Standard behavior
    },
    
    /// Spawning pattern for balanced traffic flow
    directionPattern: [
      Direction.north, Direction.east, Direction.south, Direction.west,
      Direction.north, Direction.west, Direction.east, Direction.south,
      Direction.west, Direction.north, Direction.east, Direction.north,
      Direction.south, Direction.east, Direction.west, Direction.south,
    ],
    
    /// Random speed variation for natural feel
    speedVariation: SpeedVariationConfig(
      minFactor: 0.8,    // Cars can be 20% slower than base speed
      maxFactor: 1.2,    // Cars can be 20% faster than base speed
    ),
  );

  // ============================================================================
  // 🚙 CAR PROPERTIES CONFIGURATION  
  // ============================================================================
  
  static const Map<CarType, CarConfig> carProperties = {
    CarType.regular: CarConfig(
      size: 20.0,
      color: null, // Uses rotating color palette
      speedMultiplier: 1.0,
      ignoresTrafficLights: false,
      specialBehavior: CarBehavior.normal,
    ),
    CarType.ambulance: CarConfig(
      size: 24.0,
      color: Colors.white,
      speedMultiplier: 1.0,
      ignoresTrafficLights: true,
      specialBehavior: CarBehavior.emergency,
    ),
    CarType.police: CarConfig(
      size: 22.0,  
      color: Color(0xFF00008B), // Dark blue
      speedMultiplier: 1.0,
      ignoresTrafficLights: true,
      specialBehavior: CarBehavior.aggressive,
    ),
    CarType.tractor: CarConfig(
      size: 18.0,
      color: Color(0xFF228B22), // Forest green
      speedMultiplier: 0.3,     // Super slow
      ignoresTrafficLights: false,
      specialBehavior: CarBehavior.slow,
    ),
    CarType.schoolBus: CarConfig(
      size: 84.0,               // Extra long
      color: Color(0xFFFFFF00), // Yellow
      speedMultiplier: 1.0,
      ignoresTrafficLights: false,
      specialBehavior: CarBehavior.flashingLights,
    ),
    CarType.impatient: CarConfig(
      size: 20.0,
      color: null, // Uses impatient color palette
      speedMultiplier: 1.0,
      ignoresTrafficLights: false, // But may run reds occasionally
      specialBehavior: CarBehavior.impatient,
    ),
  };

  // ============================================================================
  // 🎨 COLOR PALETTES
  // ============================================================================
  
  static const ColorPalettes colors = ColorPalettes(
    regularCars: [
      Color(0xFF1ABC9C), Color(0xFF2ECC71), Color(0xFF3498DB),
      Color(0xFF9B59B6), Color(0xFF34495E), Color(0xFFF1C40F),
      Color(0xFFE67E22), Color(0xFFE74C3C), Color(0xFFECF0F1),
      Color(0xFF95A5A6), Color(0xFFD35400), Color(0xFFC0392B),
    ],
    impatientCars: [
      Color(0xFFE74C3C), Color(0xFFD35400),
      Color(0xFF2C3E50), Color(0xFF8E44AD),
    ],
  );

  // ============================================================================
  // ⚙️ GAME PHYSICS CONFIGURATION
  // ============================================================================
  
  static const GamePhysicsConfig physics = GamePhysicsConfig(
    /// Car stopping and collision behavior
    stopDistanceFromIntersection: 30.0,  // Pixels
    safeFollowingDistanceMultiplier: 1.5, // Multiple of larger car size
    offScreenBuffer: 50.0,               // Pixels beyond screen edge
    maxCarSearchDistance: 200.0,         // For finding car ahead
    
    /// Intersection and road layout
    defaultGameWidth: 800.0,
    defaultGameHeight: 600.0,
    defaultIntersectionSize: 200.0,
    defaultRoadWidth: 80.0,
    intersectionSizeMultiplier: 0.25,    // Fraction of min screen dimension
    roadWidthMultiplier: 0.1,            // Fraction of min screen dimension
    minimumIntersectionSize: 150.0,
    minimumRoadWidth: 60.0,
    
    /// Traffic light positioning
    trafficLightDistance: 120.0,         // From intersection center
    
    /// Lane positioning  
    laneOffset: 0.25,                    // Fraction of road width for lane centers
  );

  // ============================================================================
  // 💥 EFFECTS CONFIGURATION
  // ============================================================================
  
  static const EffectsConfig effects = EffectsConfig(
    /// Crash effects
    crashRemovalTimerFrames: 300,        // ~5 seconds at 60 FPS
    crashEffectDurationFrames: 60,       // 1 second
    crashScorePenalty: 5,
    
    /// Score popups
    scorePopupDurationFrames: 90,        // 1.5 seconds
    achievementPopupDurationFrames: 180, // 3 seconds
    popupFloatSpeed: 1.0,                // Pixels per frame upward
    
    /// Particle systems
    particleLifespanFrames: 45,          // 0.75 seconds
    particleGravity: 0.05,               // Downward acceleration per frame
    particlesPerSuccess: 8,              // Number of particles on car success
    particleSpeedMin: 1.0,
    particleSpeedMax: 2.5,
    
    /// Success celebration positioning
    successPopupOffset: 50.0,            // Pixels above center for achievements
  );

  // ============================================================================
  // 🏆 OBJECTIVES CONFIGURATION
  // ============================================================================
  
  static const ObjectivesConfig objectives = ObjectivesConfig(
    definitions: {
      'pass_20_cars': ObjectiveDefinition(
        title: 'Pass 20 Cars',
        description: 'Get 20 cars through safely',
        requirement: 20,
        bonus: 50,
        type: ObjectiveType.carsPassed,
      ),
      'zero_crashes': ObjectiveDefinition(
        title: 'Perfect Safety',
        description: 'No crashes with 10+ cars passed',
        requirement: 10,
        bonus: 100,
        type: ObjectiveType.perfectSafety,
      ),
      'pass_50_cars': ObjectiveDefinition(
        title: 'Pass 50 Cars',
        description: 'Reach 50 successful passages',
        requirement: 50,
        bonus: 150,
        type: ObjectiveType.carsPassed,
      ),
      'efficiency_85': ObjectiveDefinition(
        title: 'High Efficiency',
        description: '85% success rate with 20+ cars',
        requirement: 20,
        bonus: 200,
        type: ObjectiveType.efficiency,
        secondaryRequirement: 85, // Success rate percentage
      ),
      'pass_100_cars': ObjectiveDefinition(
        title: 'Century Mark',
        description: 'Pass 100 cars successfully',
        requirement: 100,
        bonus: 300,
        type: ObjectiveType.carsPassed,
      ),
      'no_traffic_jams': ObjectiveDefinition(
        title: 'Traffic Master',
        description: 'Keep waiting cars ≤3 with 30+ passed',
        requirement: 30,
        bonus: 250,
        type: ObjectiveType.trafficManagement,
        secondaryRequirement: 3, // Max waiting cars
      ),
    },
    
    /// Achievement visual styling
    achievementColor: Color(0xFF4CAF50), // Green for achievements
  );

  // ============================================================================
  // 📊 GAME OVER CONDITIONS
  // ============================================================================
  
  static const GameOverConfig gameOver = GameOverConfig(
    maxWaitingCars: 7,                   // Traffic jam limit
    minSuccessRate: 70,                  // Percentage
    minCrashesForPerformanceCheck: 5,    // Poor performance threshold
    
    /// Analytics milestone intervals
    analyticsCarsMilestone: 25,          // Log every N cars passed
    scoreMilestones: [100, 250, 500, 1000, 2000, 5000, 10000],
  );

  // ============================================================================
  // 🎮 TIMING CONFIGURATION
  // ============================================================================
  
  static const TimingConfig timing = TimingConfig(
    targetFPS: 60,
    frameTimeMs: 16,                     // 1000ms / 60 FPS
    frameTimeSeconds: 0.016667,          // 1/60 seconds
  );

  // ============================================================================
  // 🎵 VALIDATION HELPERS
  // ============================================================================
  
  /// Validates that car type distribution sums to 1.0
  static bool validateCarDistribution() {
    double sum = carSpawning.typeDistribution.values.fold(0.0, (a, b) => a + b);
    const tolerance = 0.001;
    return (sum - 1.0).abs() < tolerance;
  }
  
  /// Gets difficulty configuration safely
  static DifficultyConfig getDifficulty(Difficulty difficulty) {
    return difficulties[difficulty]!;
  }
  
  /// Gets car configuration safely
  static CarConfig getCarConfig(CarType carType) {
    return carProperties[carType]!;
  }
}

// ============================================================================
// 📋 CONFIGURATION DATA CLASSES
// ============================================================================

class DifficultyConfig {
  final int carSpawnIntervalFrames;
  final double carSpeed;
  final double scoreMultiplier;
  final Color color;
  final String displayName;
  
  const DifficultyConfig({
    required this.carSpawnIntervalFrames,
    required this.carSpeed,
    required this.scoreMultiplier,
    required this.color,
    required this.displayName,
  });
}

class CarSpawningConfig {
  final Map<CarType, double> typeDistribution;
  final List<Direction> directionPattern;
  final SpeedVariationConfig speedVariation;
  
  const CarSpawningConfig({
    required this.typeDistribution,
    required this.directionPattern,
    required this.speedVariation,
  });
}

class SpeedVariationConfig {
  final double minFactor;
  final double maxFactor;
  
  const SpeedVariationConfig({
    required this.minFactor,
    required this.maxFactor,
  });
}

class CarConfig {
  final double size;
  final Color? color;
  final double speedMultiplier;
  final bool ignoresTrafficLights;
  final CarBehavior specialBehavior;
  
  const CarConfig({
    required this.size,
    required this.color,
    required this.speedMultiplier,
    required this.ignoresTrafficLights,
    required this.specialBehavior,
  });
}

enum CarBehavior {
  normal,
  emergency,
  aggressive,
  slow,
  flashingLights,
  impatient,
}

class ColorPalettes {
  final List<Color> regularCars;
  final List<Color> impatientCars;
  
  const ColorPalettes({
    required this.regularCars,
    required this.impatientCars,
  });
}

class GamePhysicsConfig {
  final double stopDistanceFromIntersection;
  final double safeFollowingDistanceMultiplier;
  final double offScreenBuffer;
  final double maxCarSearchDistance;
  final double defaultGameWidth;
  final double defaultGameHeight;
  final double defaultIntersectionSize;
  final double defaultRoadWidth;
  final double intersectionSizeMultiplier;
  final double roadWidthMultiplier;
  final double minimumIntersectionSize;
  final double minimumRoadWidth;
  final double trafficLightDistance;
  final double laneOffset;
  
  const GamePhysicsConfig({
    required this.stopDistanceFromIntersection,
    required this.safeFollowingDistanceMultiplier,
    required this.offScreenBuffer,
    required this.maxCarSearchDistance,
    required this.defaultGameWidth,
    required this.defaultGameHeight,
    required this.defaultIntersectionSize,
    required this.defaultRoadWidth,
    required this.intersectionSizeMultiplier,
    required this.roadWidthMultiplier,
    required this.minimumIntersectionSize,
    required this.minimumRoadWidth,
    required this.trafficLightDistance,
    required this.laneOffset,
  });
}

class EffectsConfig {
  final int crashRemovalTimerFrames;
  final int crashEffectDurationFrames;
  final int crashScorePenalty;
  final int scorePopupDurationFrames;
  final int achievementPopupDurationFrames;
  final double popupFloatSpeed;
  final int particleLifespanFrames;
  final double particleGravity;
  final int particlesPerSuccess;
  final double particleSpeedMin;
  final double particleSpeedMax;
  final double successPopupOffset;
  
  const EffectsConfig({
    required this.crashRemovalTimerFrames,
    required this.crashEffectDurationFrames,
    required this.crashScorePenalty,
    required this.scorePopupDurationFrames,
    required this.achievementPopupDurationFrames,
    required this.popupFloatSpeed,
    required this.particleLifespanFrames,
    required this.particleGravity,
    required this.particlesPerSuccess,
    required this.particleSpeedMin,
    required this.particleSpeedMax,
    required this.successPopupOffset,
  });
}

class ObjectivesConfig {
  final Map<String, ObjectiveDefinition> definitions;
  final Color achievementColor;
  
  const ObjectivesConfig({
    required this.definitions,
    required this.achievementColor,
  });
}

class ObjectiveDefinition {
  final String title;
  final String description;
  final int requirement;
  final int bonus;
  final ObjectiveType type;
  final int? secondaryRequirement;
  
  const ObjectiveDefinition({
    required this.title,
    required this.description,
    required this.requirement,
    required this.bonus,
    required this.type,
    this.secondaryRequirement,
  });
}

enum ObjectiveType {
  carsPassed,
  perfectSafety,
  efficiency,
  trafficManagement,
}

class GameOverConfig {
  final int maxWaitingCars;
  final int minSuccessRate;
  final int minCrashesForPerformanceCheck;
  final int analyticsCarsMilestone;
  final List<int> scoreMilestones;
  
  const GameOverConfig({
    required this.maxWaitingCars,
    required this.minSuccessRate,
    required this.minCrashesForPerformanceCheck,
    required this.analyticsCarsMilestone,
    required this.scoreMilestones,
  });
}

class TimingConfig {
  final int targetFPS;
  final int frameTimeMs;
  final double frameTimeSeconds;
  
  const TimingConfig({
    required this.targetFPS,
    required this.frameTimeMs,
    required this.frameTimeSeconds,
  });
}
