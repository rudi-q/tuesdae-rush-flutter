library;

/// 🎮 **SHARED GAME TYPES**
/// 
/// Central location for all shared enums and types used across the gameplay domain.
/// This prevents import cycles between game_config.dart and game_state.dart.

// ============================================================================
// 🧭 DIRECTION AND NAVIGATION TYPES
// ============================================================================

/// Cardinal directions for car movement and traffic lights
enum Direction { 
  north, 
  south, 
  east, 
  west 
}

/// Traffic light states
enum LightState { 
  red, 
  green 
}

// ============================================================================
// 🚗 CAR TYPES AND BEHAVIORS  
// ============================================================================

/// Types of cars in the game with different behaviors
enum CarType { 
  regular,      // Standard cars
  ambulance,    // Emergency vehicle - ignores lights
  police,       // Emergency vehicle - aggressive behavior
  tractor,      // Slow-moving vehicle
  schoolBus,    // Extra long vehicle
  impatient     // May run red lights occasionally
}

/// Special behaviors that cars can exhibit
enum CarBehavior {
  normal,           // Standard driving behavior
  emergency,        // Ignores traffic lights, has siren
  aggressive,       // Police behavior - may rear-end stopped cars
  slow,             // Moves slower than normal
  flashingLights,   // Has visual indicators (school bus)
  impatient,        // Occasionally runs red lights
}

// ============================================================================
// 🎯 DIFFICULTY AND PROGRESSION TYPES
// ============================================================================

/// Game difficulty levels affecting spawn rates and speeds
enum Difficulty { 
  easy,     // Slower spawn rates, easier gameplay
  medium,   // Balanced gameplay
  hard,     // Faster spawn rates, higher speeds  
  extreme,  // Very challenging
  insane    // Maximum difficulty
}

// ============================================================================  
// 🏆 OBJECTIVES AND ACHIEVEMENTS TYPES
// ============================================================================

/// Types of objectives players can complete
enum ObjectiveType {
  carsPassed,         // Pass X number of cars
  perfectSafety,      // No crashes with X cars passed
  efficiency,         // Achieve X% success rate
  trafficManagement,  // Keep waiting cars below threshold
}
