import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/util/helper.dart';
import '../../audio/audio_manager.dart';
import '../../responsiveness/mobile_manager.dart';
import '../../save-score/score_service.dart';
import '../config/game_config.dart';

// GameTimer class to replace expensive DateTime.now() calls
class GameTimer {
  static int _frameCount = 0;
  static double get time => _frameCount * GameConfig.timing.frameTimeSeconds;
  static void update() => _frameCount++;
  static void reset() => _frameCount = 0;
}


enum Direction { north, south, east, west }

enum LightState { red, green }

enum CarType { regular, ambulance, police, tractor, schoolBus, impatient }

enum Difficulty { easy, medium, hard, extreme, insane }

class GameState {
  // Game dimensions (using GameConfig defaults)
  double gameWidth = GameConfig.physics.defaultGameWidth;
  double gameHeight = GameConfig.physics.defaultGameHeight;
  double intersectionSize = GameConfig.physics.defaultIntersectionSize;
  double roadWidth = GameConfig.physics.defaultRoadWidth;

  // Game objects
  List<Car> cars = [];
  Map<Direction, LightState> trafficLights = {};
  List<ScorePopup> scorePopups = [];
  List<CrashEffect> crashEffects = [];
  List<Particle> particles = [];

  // Game state
  int score = 0;
  int totalCarsSpawned = 0;
  int totalCarsPassed = 0;
  int totalCarsCrashed = 0;
  bool isPaused = false;
  bool isGameOver = false;
  bool gameStarted = false;
  String gameOverReason = '';

  // Audio tracking
  bool _ambulanceSirenPlaying = false;
  bool _policeSirenPlaying = false;

  // Spawning
  int carSpawnTimer = 0;
  int nextSpawnTime = 0;

  // Difficulty system (now uses GameConfig)
  Difficulty currentDifficulty = Difficulty.medium;

  // Objectives
  Map<String, bool> objectives = {
    'pass_20_cars': false,
    'zero_crashes': false,
    'pass_50_cars': false,
    'efficiency_85': false,
    'pass_100_cars': false,
    'no_traffic_jams': false,
  };

  Map<String, bool> objectivesCompleted = {
    'pass_20_cars': false,
    'zero_crashes': false,
    'pass_50_cars': false,
    'efficiency_85': false,
    'pass_100_cars': false,
    'no_traffic_jams': false,
  };

  // Traffic light touch areas
  List<TrafficLightTouchArea> _touchAreas = [];

  void initialize() {
    // Initialize traffic lights (all start red for safety)
    trafficLights = {
      Direction.north: LightState.red,
      Direction.south: LightState.red,
      Direction.east: LightState.red,
      Direction.west: LightState.red,
    };

    // Start with one direction green
    trafficLights[Direction.north] = LightState.green;
    trafficLights[Direction.south] = LightState.green;
  }

  void updateDimensions(double width, double height) {
    gameWidth = width;
    gameHeight = height;

    // Recalculate intersection size and road width based on new canvas dimensions
    double minDimension = math.min(gameWidth, gameHeight);
    intersectionSize = math.max(minDimension * GameConfig.physics.intersectionSizeMultiplier, GameConfig.physics.minimumIntersectionSize);
    roadWidth = math.max(minDimension * GameConfig.physics.roadWidthMultiplier, GameConfig.physics.minimumRoadWidth);

    _updateTrafficLightTouchAreas();
  }

  void _updateTrafficLightTouchAreas() {
    double lightDistance = GameConfig.physics.trafficLightDistance;
    double centerX = gameWidth / 2;
    double centerY = gameHeight / 2;
    // Dynamic touch areas based on device type and screen size
    double touchSize = MobileManager().getTouchTargetSize(
      gameWidth,
      gameHeight,
    );

    _touchAreas = [
      TrafficLightTouchArea(
        direction: Direction.north,
        bounds: Rect.fromCenter(
          center: Offset(centerX, centerY - lightDistance),
          width: touchSize,
          height: touchSize,
        ),
      ),
      TrafficLightTouchArea(
        direction: Direction.south,
        bounds: Rect.fromCenter(
          center: Offset(centerX, centerY + lightDistance),
          width: touchSize,
          height: touchSize,
        ),
      ),
      TrafficLightTouchArea(
        direction: Direction.east,
        bounds: Rect.fromCenter(
          center: Offset(centerX + lightDistance, centerY),
          width: touchSize,
          height: touchSize,
        ),
      ),
      TrafficLightTouchArea(
        direction: Direction.west,
        bounds: Rect.fromCenter(
          center: Offset(centerX - lightDistance, centerY),
          width: touchSize,
          height: touchSize,
        ),
      ),
    ];
  }

  List<TrafficLightTouchArea> getTrafficLightTouchAreas() {
    return _touchAreas;
  }

  void update() {
    if (isPaused || isGameOver || !gameStarted) return;
    
    // Update frame-based timer
    GameTimer.update();

    // Update cars
    for (int i = cars.length - 1; i >= 0; i--) {
      cars[i].update(this);

      // Handle crashed car removal timer
      if (cars[i].crashed && cars[i].removalTimer != null) {
        cars[i].removalTimer = cars[i].removalTimer! - 1;
        if (cars[i].removalTimer! <= 0) {
          cars.removeAt(i);
          continue;
        }
      }

      // Remove cars that have left the screen
      if (cars[i].isOffScreen(gameWidth, gameHeight)) {
        if (cars[i].hasPassedIntersection) {
          int points = getDifficultyMultiplier().round();
          int oldScore = score;
          score += points;
          totalCarsPassed++;

          // Track score milestones
          _checkScoreMilestones(oldScore, score);

          // Track cars passed milestones
          if (totalCarsPassed % GameConfig.gameOver.analyticsCarsMilestone == 0) {
            AnalyticsService.logCarsPassed(totalCarsPassed);
          }

          // Play car passed sound and haptic
          AudioManager().playCarPassed();
          MobileManager().mediumHaptic();

          // Add score popup
          scorePopups.add(
            ScorePopup(
              x: cars[i].x,
              y: cars[i].y,
              text: '+$points',
              timer: GameConfig.effects.scorePopupDurationFrames,
              color: Color(0xFF00FF00),
            ),
          );

          // Add success particles
          _createSuccessParticles(cars[i].x, cars[i].y);
        }
        cars.removeAt(i);
      }
    }

    // Spawn cars
    carSpawnTimer++;
    if (nextSpawnTime == 0) {
      int baseInterval = GameConfig.getDifficulty(currentDifficulty).carSpawnIntervalFrames;
      double randomVariation = baseInterval * 0.5;
      nextSpawnTime =
          (baseInterval + (math.Random().nextDouble() - 0.5) * randomVariation)
              .round();
    }

    if (carSpawnTimer >= nextSpawnTime) {
      _spawnCar();
      carSpawnTimer = 0;
      nextSpawnTime = 0;
    }

    // Check collisions
    _checkCollisions();

    // Update effects
    _updateScorePopups();
    _updateCrashEffects();
    _updateParticles();

    // Check objectives
    _checkObjectives();

    // Update sirens
    _updateSirens();

    // Check game over conditions
    _checkGameOverConditions();
  }

  void _spawnCar() {
    Direction fromDirection = GameConfig.carSpawning.directionPattern[
        totalCarsSpawned % GameConfig.carSpawning.directionPattern.length];
    Direction toDirection = _getOppositeDirection(fromDirection);

    Car? car = _createCar(fromDirection, toDirection);
    if (car != null) {
      cars.add(car);
      totalCarsSpawned++;
    }
  }

  Direction _getOppositeDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }

  Car? _createCar(Direction from, Direction to) {
    CarType carType = _determineCarType();

    // Apply speed variation and car-specific multipliers
    double speedRange = GameConfig.carSpawning.speedVariation.maxFactor - 
                       GameConfig.carSpawning.speedVariation.minFactor;
    double speedRandomFactor = GameConfig.carSpawning.speedVariation.minFactor + 
                              math.Random().nextDouble() * speedRange;
    double carSpeed = GameConfig.getDifficulty(currentDifficulty).carSpeed * speedRandomFactor;
    
    // Apply car-specific speed multiplier
    carSpeed *= GameConfig.getCarConfig(carType).speedMultiplier;

    Car car = Car(
      from: from,
      to: to,
      speed: carSpeed,
      type: carType,
      color: _getCarColor(carType, totalCarsSpawned),
    );

    // Set starting position
    _setCarStartingPosition(car);

    return car;
  }

  CarType _determineCarType() {
    double random = math.Random().nextDouble();
    double cumulative = 0.0;
    
    for (final entry in GameConfig.carSpawning.typeDistribution.entries) {
      cumulative += entry.value;
      if (random < cumulative) {
        return entry.key;
      }
    }
    
    // Fallback to regular (should never reach here if distribution sums to 1.0)
    return CarType.regular;
  }

  Color _getCarColor(CarType carType, int carIndex) {
    final carConfig = GameConfig.getCarConfig(carType);
    
    // If the car has a specific color, use it
    if (carConfig.color != null) {
      return carConfig.color!;
    }
    
    // Otherwise, use the appropriate color palette
    switch (carType) {
      case CarType.impatient:
        return GameConfig.colors.impatientCars[carIndex % GameConfig.colors.impatientCars.length];
      default:
        return GameConfig.colors.regularCars[carIndex % GameConfig.colors.regularCars.length];
    }
  }

  void _setCarStartingPosition(Car car) {
    double laneOffset = roadWidth * GameConfig.physics.laneOffset;
    switch (car.from) {
      case Direction.north:
        car.x = gameWidth / 2 - laneOffset;
        car.y = -car.getSize();
        break;
      case Direction.south:
        car.x = gameWidth / 2 + laneOffset;
        car.y = gameHeight + car.getSize();
        break;
      case Direction.east:
        car.x = gameWidth + car.getSize();
        car.y = gameHeight / 2 - laneOffset;
        break;
      case Direction.west:
        car.x = -car.getSize();
        car.y = gameHeight / 2 + laneOffset;
        break;
    }
  }

  void _checkCollisions() {
    for (int i = 0; i < cars.length; i++) {
      for (int j = i + 1; j < cars.length; j++) {
        Car car1 = cars[i];
        Car car2 = cars[j];

        if (car1.crashed || car2.crashed) continue;

        // Emergency vehicles (police and ambulance) cannot crash with each other
        bool car1Emergency =
            (car1.type == CarType.police || car1.type == CarType.ambulance);
        bool car2Emergency =
            (car2.type == CarType.police || car2.type == CarType.ambulance);
        if (car1Emergency && car2Emergency) continue;

        // Use squared distance to avoid expensive sqrt() calculation
        double deltaX = car1.x - car2.x;
        double deltaY = car1.y - car2.y;
        double distanceSquared = deltaX * deltaX + deltaY * deltaY;

        double car1Radius = car1.getSize() / 2;
        double car2Radius = car2.getSize() / 2;
        double collisionThreshold = car1Radius + car2Radius;
        double thresholdSquared = collisionThreshold * collisionThreshold;

        if (distanceSquared < thresholdSquared) {
          bool car1Vertical =
              (car1.from == Direction.north || car1.from == Direction.south);
          bool car2Vertical =
              (car2.from == Direction.north || car2.from == Direction.south);
          bool perpendicularCollision = (car1Vertical != car2Vertical);

          // Police rear-end collision logic
          bool policeRearEnd = false;
          if ((car1.type == CarType.police || car2.type == CarType.police) &&
              (car1.from == car2.from && car1.to == car2.to)) {
            Car targetCar = car1.type == CarType.police ? car2 : car1;
            if (targetCar.stopped &&
                !targetCar.hasPassedIntersection &&
                trafficLights[targetCar.from] == LightState.red) {
              policeRearEnd = true;
            }
          }

          if (perpendicularCollision || policeRearEnd) {
            _handleCollision(car1, car2);
          }
        }
      }
    }
  }

  void _handleCollision(Car car1, Car car2) {
    car1.crashed = true;
    car2.crashed = true;
    car1.color = Colors.red;
    car2.color = Colors.red;
    car1.stopped = true;
    car2.stopped = true;
    car1.speed = 0;
    car2.speed = 0;
    car1.removalTimer = GameConfig.effects.crashRemovalTimerFrames;
    car2.removalTimer = GameConfig.effects.crashRemovalTimerFrames;

    totalCarsCrashed += 2;

    double crashX = (car1.x + car2.x) / 2;
    double crashY = (car1.y + car2.y) / 2;

    crashEffects.add(CrashEffect(x: crashX, y: crashY, timer: GameConfig.effects.crashEffectDurationFrames));
    score = math.max(0, score - GameConfig.effects.crashScorePenalty);

    // Play crash sound and haptic
    AudioManager().playCrash();
    MobileManager().errorHaptic();

    scorePopups.add(
      ScorePopup(
        x: crashX,
        y: crashY,
        text: '-${GameConfig.effects.crashScorePenalty}',
        timer: GameConfig.effects.scorePopupDurationFrames,
        color: Color(0xFFFF6464),
      ),
    );
  }

  void _updateScorePopups() {
    for (int i = scorePopups.length - 1; i >= 0; i--) {
      scorePopups[i].timer--;
      scorePopups[i].y -= GameConfig.effects.popupFloatSpeed;

      if (scorePopups[i].timer <= 0) {
        scorePopups.removeAt(i);
      }
    }
  }

  void _updateCrashEffects() {
    for (int i = crashEffects.length - 1; i >= 0; i--) {
      crashEffects[i].timer--;

      if (crashEffects[i].timer <= 0) {
        crashEffects.removeAt(i);
      }
    }
  }

  void _updateParticles() {
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update();

      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }
  }

  void _createSuccessParticles(double x, double y) {
    for (int i = 0; i < GameConfig.effects.particlesPerSuccess; i++) {
      double angle = (i / GameConfig.effects.particlesPerSuccess) * 2 * math.pi;
      double speed = GameConfig.effects.particleSpeedMin + math.Random().nextDouble() * GameConfig.effects.particleSpeedMax;
      particles.add(
        Particle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - GameConfig.effects.particleGravity,
          life: GameConfig.effects.particleLifespanFrames,
          color: Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _updateSirens() {
    bool hasAmbulance = cars.any(
      (car) => car.type == CarType.ambulance && !car.crashed,
    );
    bool hasPolice = cars.any(
      (car) => car.type == CarType.police && !car.crashed,
    );

    // Manage ambulance siren
    if (hasAmbulance && !_ambulanceSirenPlaying) {
      AudioManager().playAmbulanceSiren();
      _ambulanceSirenPlaying = true;
    } else if (!hasAmbulance && _ambulanceSirenPlaying) {
      AudioManager().stopSirens();
      _ambulanceSirenPlaying = false;
    }

    // Manage police siren (only if no ambulance)
    if (hasPolice && !hasAmbulance && !_policeSirenPlaying) {
      AudioManager().playPoliceSiren();
      _policeSirenPlaying = true;
    } else if ((!hasPolice || hasAmbulance) && _policeSirenPlaying) {
      AudioManager().stopSirens();
      _policeSirenPlaying = false;
    }
  }

  void _checkObjectives() {
    int successRate = getSuccessRate();
    int waitingCars = getWaitingCarsCount();

    // Check each objective using GameConfig definitions
    for (String objectiveId in GameConfig.objectives.definitions.keys) {
      if (!objectivesCompleted[objectiveId]!) {
        ObjectiveDefinition def = GameConfig.objectives.definitions[objectiveId]!;
        bool requirementMet = false;
        
        switch (def.type) {
          case ObjectiveType.carsPassed:
            requirementMet = totalCarsPassed >= def.requirement;
            break;
          case ObjectiveType.perfectSafety:
            requirementMet = totalCarsPassed >= def.requirement && totalCarsCrashed == 0;
            break;
          case ObjectiveType.efficiency:
            requirementMet = totalCarsPassed >= def.requirement && 
                           successRate >= (def.secondaryRequirement ?? 0);
            break;
          case ObjectiveType.trafficManagement:
            requirementMet = totalCarsPassed >= def.requirement && 
                           waitingCars <= (def.secondaryRequirement ?? 0);
            break;
        }
        
        if (requirementMet) {
          objectives[objectiveId] = true;
          objectivesCompleted[objectiveId] = true;
          _awardObjectiveBonus(def.title, def.bonus);
        }
      }
    }
  }

  void _awardObjectiveBonus(String objectiveName, int bonus) {
    score += bonus;

    // Track objective completion analytics
    AnalyticsService.logObjectiveCompleted(objectiveName);

    // Play special achievement sound and haptic
    AudioManager().playPerfectFlow();
    MobileManager().successHaptic();

    scorePopups.add(
      ScorePopup(
        x: gameWidth / 2,
        y: gameHeight / 2 - GameConfig.effects.successPopupOffset,
        text: '$objectiveName: +$bonus',
        timer: GameConfig.effects.achievementPopupDurationFrames,
        color: GameConfig.objectives.achievementColor,
      ),
    );
  }

  void _checkGameOverConditions() {
    if (isGameOver) return;

    int waitingCars = getWaitingCarsCount();
    int successRate = getSuccessRate();

    if (waitingCars >= GameConfig.gameOver.maxWaitingCars) {
      isGameOver = true;
      gameOverReason = 'Too many cars waiting! ($waitingCars cars)';
      _trackGameOverAnalytics('traffic_jam');
      _saveGameScore();
      return;
    }

    if (successRate < GameConfig.gameOver.minSuccessRate && 
        totalCarsCrashed > GameConfig.gameOver.minCrashesForPerformanceCheck) {
      isGameOver = true;
      gameOverReason =
          'Poor performance! ($successRate% success, $totalCarsCrashed crashes)';
      _trackGameOverAnalytics('poor_performance');
      _saveGameScore();
      return;
    }
  }

  void toggleTrafficLight(Direction direction) {
    trafficLights[direction] =
        trafficLights[direction] == LightState.red
            ? LightState.green
            : LightState.red;
  }

  void changeDifficulty(Difficulty newDifficulty) {
    if (currentDifficulty != newDifficulty) {
      currentDifficulty = newDifficulty;

      // Update existing cars' speed
      for (Car car in cars) {
        if (!car.crashed) {
          car.speed = GameConfig.difficulties[newDifficulty]!.carSpeed;
        }
      }
    }
  }

  void togglePause() {
    isPaused = !isPaused;
  }

  void restart() {
    cars.clear();
    scorePopups.clear();
    crashEffects.clear();
    particles.clear();
    score = 0;
    totalCarsSpawned = 0;
    totalCarsPassed = 0;
    totalCarsCrashed = 0;
    carSpawnTimer = 0;
    nextSpawnTime = 0;
    isPaused = false;
    isGameOver = false;
    gameStarted = true; // Keep game running after restart
    gameOverReason = '';

    // Stop all sirens
    AudioManager().stopAllSounds();
    _ambulanceSirenPlaying = false;
    _policeSirenPlaying = false;

    objectives = {
      'pass_20_cars': false,
      'zero_crashes': false,
      'pass_50_cars': false,
      'efficiency_85': false,
      'pass_100_cars': false,
      'no_traffic_jams': false,
    };

    objectivesCompleted = {
      'pass_20_cars': false,
      'zero_crashes': false,
      'pass_50_cars': false,
      'efficiency_85': false,
      'pass_100_cars': false,
      'no_traffic_jams': false,
    };

    initialize();
  }

  void startGame() {
    gameStarted = true;
  }

  int getWaitingCarsCount() {
    int waitingCount = 0;
    for (Car car in cars) {
      if (car.stopped && !car.crashed && !car.hasPassedIntersection) {
        if (trafficLights[car.from] == LightState.red) {
          waitingCount++;
        }
      }
    }
    return waitingCount;
  }

  int getSuccessRate() {
    return totalCarsSpawned > 0
        ? ((totalCarsPassed / totalCarsSpawned) * 100).round()
        : 100;
  }

  Color getDifficultyColor() {
    return GameConfig.difficulties[currentDifficulty]!.color;
  }

  double getDifficultyMultiplier() {
    return GameConfig.difficulties[currentDifficulty]!.scoreMultiplier;
  }

  // Analytics helper methods
  void _checkScoreMilestones(int oldScore, int newScore) {
    List<int> milestones = GameConfig.gameOver.scoreMilestones;

    for (int milestone in milestones) {
      if (oldScore < milestone && newScore >= milestone) {
        AnalyticsService.logScoreMilestone(milestone);
      }
    }
  }

  void _trackGameOverAnalytics(String reason) {
    AnalyticsService.logGameOver(
      reason,
      score,
      totalCarsPassed,
      totalCarsCrashed,
      getSuccessRate().toDouble(),
    );
  }

  // Save score to Supabase when game ends
  void _saveGameScore() {
    // Save asynchronously without blocking the UI
    ScoreService()
        .saveScore(
          score: score,
          difficulty: currentDifficulty.name,
          carsPassed: totalCarsPassed,
          successRate: getSuccessRate().toDouble(),
          objectives: Map<String, dynamic>.from(objectives),
        )
        .catchError((error) {
          // Handle errors silently in background
          devPrint('Failed to save score: $error');
        });
  }
}

class Car {
  Direction from;
  Direction to;
  double x = 0;
  double y = 0;
  double speed;
  CarType type;
  Color color;
  bool hasPassedIntersection = false;
  bool stopped = false;
  bool crashed = false;
  int? removalTimer;

  Car({
    required this.from,
    required this.to,
    required this.speed,
    required this.type,
    required this.color,
  });

  void update(GameState gameState) {
    // Early returns to avoid unnecessary calculations
    if (crashed && removalTimer != null) return; // Don't update crashed cars waiting for removal
    
    double intersectionEdge = _getIntersectionEdge(gameState);
    bool shouldStop = false;

    // Check if car should stop at red light
    if (!hasPassedIntersection &&
        type != CarType.ambulance &&
        type != CarType.police &&
        gameState.trafficLights[from] == LightState.red) {
      double distanceToIntersection = _getDistanceToIntersection(
        gameState,
        intersectionEdge,
      );
      if (distanceToIntersection <= GameConfig.physics.stopDistanceFromIntersection) {
        shouldStop = true;
      }
    }

    // Check if car should stop behind another car
    if (!shouldStop && !crashed && type != CarType.police) {
      Car? carAhead = _getCarAhead(gameState);
      if (carAhead != null) {
        // Use squared distance to avoid expensive sqrt()
        double deltaX = x - carAhead.x;
        double deltaY = y - carAhead.y;
        double distanceSquared = deltaX * deltaX + deltaY * deltaY;
        double largerSize = math.max(getSize(), carAhead.getSize());
        double safeDistance = largerSize * GameConfig.physics.safeFollowingDistanceMultiplier;
        double safeDistanceSquared = safeDistance * safeDistance;
        if (distanceSquared < safeDistanceSquared) {
          shouldStop = true;
        }
      }
    }

    stopped = shouldStop;

    if (!shouldStop) {
      if (!hasPassedIntersection) {
        _moveCar();
        if (_hasReachedIntersection(gameState, intersectionEdge)) {
          hasPassedIntersection = true;
        }
      } else {
        _moveCarToExit();
      }
    }
  }

  void _moveCar() {
    switch (from) {
      case Direction.north:
        y += speed;
        break;
      case Direction.south:
        y -= speed;
        break;
      case Direction.east:
        x -= speed;
        break;
      case Direction.west:
        x += speed;
        break;
    }
  }

  void _moveCarToExit() {
    switch (to) {
      case Direction.north:
        y -= speed;
        break;
      case Direction.south:
        y += speed;
        break;
      case Direction.east:
        x += speed;
        break;
      case Direction.west:
        x -= speed;
        break;
    }
  }

  double _getIntersectionEdge(GameState gameState) {
    switch (from) {
      case Direction.north:
        return gameState.gameHeight / 2 - gameState.intersectionSize / 2;
      case Direction.south:
        return gameState.gameHeight / 2 + gameState.intersectionSize / 2;
      case Direction.east:
        return gameState.gameWidth / 2 + gameState.intersectionSize / 2;
      case Direction.west:
        return gameState.gameWidth / 2 - gameState.intersectionSize / 2;
    }
  }

  double _getDistanceToIntersection(
    GameState gameState,
    double intersectionEdge,
  ) {
    switch (from) {
      case Direction.north:
        return intersectionEdge - y;
      case Direction.south:
        return y - intersectionEdge;
      case Direction.east:
        return x - intersectionEdge;
      case Direction.west:
        return intersectionEdge - x;
    }
  }

  bool _hasReachedIntersection(GameState gameState, double intersectionEdge) {
    switch (from) {
      case Direction.north:
        return y >= intersectionEdge;
      case Direction.south:
        return y <= intersectionEdge;
      case Direction.east:
        return x <= intersectionEdge;
      case Direction.west:
        return x >= intersectionEdge;
    }
  }

  Car? _getCarAhead(GameState gameState) {
    Car? closestCar;
    double closestDistance = double.infinity;

    for (Car otherCar in gameState.cars) {
      if (otherCar == this || otherCar.crashed) continue;

      if (otherCar.from == from && otherCar.to == to) {
        bool isAhead = false;
        double distance = 0;

        switch (from) {
          case Direction.north:
            isAhead = otherCar.y > y;
            distance = otherCar.y - y;
            break;
          case Direction.south:
            isAhead = otherCar.y < y;
            distance = y - otherCar.y;
            break;
          case Direction.east:
            isAhead = otherCar.x < x;
            distance = x - otherCar.x;
            break;
          case Direction.west:
            isAhead = otherCar.x > x;
            distance = otherCar.x - x;
            break;
        }

        if (isAhead &&
            distance > 0 &&
            distance < GameConfig.physics.maxCarSearchDistance &&
            distance < closestDistance) {
          closestCar = otherCar;
          closestDistance = distance;
        }
      }
    }

    return closestCar;
  }

  bool isOffScreen(double gameWidth, double gameHeight) {
    double buffer = GameConfig.physics.offScreenBuffer;
    return x < -buffer || x > gameWidth + buffer || y < -buffer || y > gameHeight + buffer;
  }

  double getSize() {
    return GameConfig.carProperties[type]!.size;
  }

  double getRotationAngle() {
    switch (to) {
      case Direction.south:
        return 0;
      case Direction.north:
        return math.pi;
      case Direction.east:
        return -math.pi / 2;
      case Direction.west:
        return math.pi / 2;
    }
  }
}

class ScorePopup {
  double x;
  double y;
  String text;
  int timer;
  Color color;

  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    required this.timer,
    required this.color,
  });
}

class CrashEffect {
  double x;
  double y;
  int timer;

  CrashEffect({required this.x, required this.y, required this.timer});
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  int life;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  });

  void update() {
    x += vx;
    y += vy;
    vy += GameConfig.effects.particleGravity; // Gravity
    life--;
  }
}

class TrafficLightTouchArea {
  Direction direction;
  Rect bounds;

  TrafficLightTouchArea({required this.direction, required this.bounds});
}
