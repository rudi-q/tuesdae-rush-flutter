
// ============================================================================
// 📋 CONFIGURATION DATA CLASSES
// ============================================================================

import 'dart:ui';

import '../domain/types.dart';

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
