import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'analytics_service.dart';
import 'audio_manager.dart';
import 'mobile_manager.dart';
import 'score_service.dart';

enum Direction { north, south, east, west }
enum LightState { red, green }
enum CarType { regular, ambulance, police, tractor, schoolBus, impatient }
enum Difficulty { easy, medium, hard, extreme, insane }

class GameState {
  // Game dimensions
  double gameWidth = 800;
  double gameHeight = 600;
  double intersectionSize = 200;
  double roadWidth = 80;

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

  // Difficulty system
  Difficulty currentDifficulty = Difficulty.medium;
  Map<Difficulty, DifficultySettings> difficultySettings = {
    Difficulty.easy: DifficultySettings(90, 1.5, 1.0, Color(0xFF2ECC71)),
    Difficulty.medium: DifficultySettings(60, 2.0, 1.5, Color(0xFFF39C12)),
    Difficulty.hard: DifficultySettings(45, 2.5, 2.0, Color(0xFFE74C3C)),
    Difficulty.extreme: DifficultySettings(35, 3.0, 2.5, Color(0xFF8E44AD)),
    Difficulty.insane: DifficultySettings(25, 3.5, 3.0, Color(0xFF2C3E50)),
  };

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
    intersectionSize = math.max(minDimension * 0.25, 150);
    roadWidth = math.max(minDimension * 0.1, 60);

    _updateTrafficLightTouchAreas();
  }

  void _updateTrafficLightTouchAreas() {
    double lightDistance = 120;
    double centerX = gameWidth / 2;
    double centerY = gameHeight / 2;
    // Dynamic touch areas based on device type and screen size
    double touchSize = MobileManager().getTouchTargetSize(gameWidth, gameHeight);

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
          if (totalCarsPassed % 25 == 0) {
            AnalyticsService.logCarsPassed(totalCarsPassed);
          }
          
        // Play car passed sound and haptic
          AudioManager().playCarPassed();
          MobileManager().mediumHaptic();
          
          // Add score popup
          scorePopups.add(ScorePopup(
            x: cars[i].x,
            y: cars[i].y,
            text: '+$points',
            timer: 90,
            color: Color(0xFF00FF00),
          ));

          // Add success particles
          _createSuccessParticles(cars[i].x, cars[i].y);
        }
        cars.removeAt(i);
      }
    }

    // Spawn cars
    carSpawnTimer++;
    if (nextSpawnTime == 0) {
      int baseInterval = difficultySettings[currentDifficulty]!.carSpawnInterval;
      double randomVariation = baseInterval * 0.5;
      nextSpawnTime = (baseInterval + (math.Random().nextDouble() - 0.5) * randomVariation).round();
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
    List<Direction> spawnPattern = [
      Direction.north, Direction.east,
      Direction.south, Direction.west,
      Direction.north, Direction.west,
      Direction.east, Direction.south,
      Direction.west, Direction.north,
      Direction.east, Direction.north,
      Direction.south, Direction.east,
      Direction.west, Direction.south,
    ];

    Direction fromDirection = spawnPattern[totalCarsSpawned % spawnPattern.length];
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
    
    double speedRandomFactor = 0.8 + math.Random().nextDouble() * 0.4;
    double carSpeed = difficultySettings[currentDifficulty]!.carSpeed * speedRandomFactor;
    
    if (carType == CarType.tractor) {
      carSpeed *= 0.3; // Super slow
    }

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
    
    if (random < 0.15) return CarType.ambulance;
    if (random < 0.225) return CarType.police;
    if (random < 0.375) return CarType.impatient;
    if (random < 0.45) return CarType.tractor;
    if (random < 0.65) return CarType.schoolBus;
    return CarType.regular;
  }

  Color _getCarColor(CarType carType, int carIndex) {
    List<Color> carColors = [
      Color(0xFF1ABC9C), Color(0xFF2ECC71), Color(0xFF3498DB), Color(0xFF9B59B6),
      Color(0xFF34495E), Color(0xFFF1C40F), Color(0xFFE67E22), Color(0xFFE74C3C),
      Color(0xFFECF0F1), Color(0xFF95A5A6), Color(0xFFD35400), Color(0xFFC0392B),
    ];

    switch (carType) {
      case CarType.ambulance:
        return Colors.white;
      case CarType.police:
        return Color(0xFF00008B);
      case CarType.tractor:
        return Color(0xFF228B22);
      case CarType.schoolBus:
        return Color(0xFFFFFF00);
      case CarType.impatient:
        List<Color> impatientColors = [
          Color(0xFFE74C3C), Color(0xFFD35400), Color(0xFF2C3E50), Color(0xFF8E44AD)
        ];
        return impatientColors[carIndex % impatientColors.length];
      default:
        return carColors[carIndex % carColors.length];
    }
  }

  void _setCarStartingPosition(Car car) {
    switch (car.from) {
      case Direction.north:
        car.x = gameWidth / 2 - roadWidth / 4;
        car.y = -car.getSize();
        break;
      case Direction.south:
        car.x = gameWidth / 2 + roadWidth / 4;
        car.y = gameHeight + car.getSize();
        break;
      case Direction.east:
        car.x = gameWidth + car.getSize();
        car.y = gameHeight / 2 - roadWidth / 4;
        break;
      case Direction.west:
        car.x = -car.getSize();
        car.y = gameHeight / 2 + roadWidth / 4;
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
        bool car1Emergency = (car1.type == CarType.police || car1.type == CarType.ambulance);
        bool car2Emergency = (car2.type == CarType.police || car2.type == CarType.ambulance);
        if (car1Emergency && car2Emergency) continue;

        double distance = math.sqrt(
          math.pow(car1.x - car2.x, 2) + math.pow(car1.y - car2.y, 2)
        );

        double car1Radius = car1.getSize() / 2;
        double car2Radius = car2.getSize() / 2;
        double collisionThreshold = car1Radius + car2Radius;

        if (distance < collisionThreshold) {
          bool car1Vertical = (car1.from == Direction.north || car1.from == Direction.south);
          bool car2Vertical = (car2.from == Direction.north || car2.from == Direction.south);
          bool perpendicularCollision = (car1Vertical != car2Vertical);

          // Police rear-end collision logic
          bool policeRearEnd = false;
          if ((car1.type == CarType.police || car2.type == CarType.police) &&
              (car1.from == car2.from && car1.to == car2.to)) {
            Car targetCar = car1.type == CarType.police ? car2 : car1;
            if (targetCar.stopped && !targetCar.hasPassedIntersection &&
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
    car1.removalTimer = 300;
    car2.removalTimer = 300;

    totalCarsCrashed += 2;

    double crashX = (car1.x + car2.x) / 2;
    double crashY = (car1.y + car2.y) / 2;

    crashEffects.add(CrashEffect(x: crashX, y: crashY, timer: 60));
    score = math.max(0, score - 5);
    
    // Play crash sound and haptic
    AudioManager().playCrash();
    MobileManager().errorHaptic();

    scorePopups.add(ScorePopup(
      x: crashX,
      y: crashY,
      text: '-5',
      timer: 90,
      color: Color(0xFFFF6464),
    ));
  }

  void _updateScorePopups() {
    for (int i = scorePopups.length - 1; i >= 0; i--) {
      scorePopups[i].timer--;
      scorePopups[i].y -= 1;
      
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
    for (int i = 0; i < 8; i++) {
      double angle = (i / 8) * 2 * math.pi;
      double speed = 1 + math.Random().nextDouble() * 1.5;
      particles.add(Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 0.5,
        life: 45,
        color: Color(0xFF2E7D32),
      ));
    }
  }
  
  void _updateSirens() {
    bool hasAmbulance = cars.any((car) => car.type == CarType.ambulance && !car.crashed);
    bool hasPolice = cars.any((car) => car.type == CarType.police && !car.crashed);
    
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

    if (totalCarsPassed >= 20 && !objectivesCompleted['pass_20_cars']!) {
      objectives['pass_20_cars'] = true;
      objectivesCompleted['pass_20_cars'] = true;
      _awardObjectiveBonus('Pass 20 Cars', 50);
    }

    if (totalCarsPassed >= 10 && totalCarsCrashed == 0 && !objectivesCompleted['zero_crashes']!) {
      objectives['zero_crashes'] = true;
      objectivesCompleted['zero_crashes'] = true;
      _awardObjectiveBonus('Perfect Safety', 100);
    }

    if (totalCarsPassed >= 50 && !objectivesCompleted['pass_50_cars']!) {
      objectives['pass_50_cars'] = true;
      objectivesCompleted['pass_50_cars'] = true;
      _awardObjectiveBonus('Pass 50 Cars', 150);
    }

    if (totalCarsPassed >= 20 && successRate >= 85 && !objectivesCompleted['efficiency_85']!) {
      objectives['efficiency_85'] = true;
      objectivesCompleted['efficiency_85'] = true;
      _awardObjectiveBonus('High Efficiency', 200);
    }

    if (totalCarsPassed >= 100 && !objectivesCompleted['pass_100_cars']!) {
      objectives['pass_100_cars'] = true;
      objectivesCompleted['pass_100_cars'] = true;
      _awardObjectiveBonus('Century Mark', 300);
    }

    if (totalCarsPassed >= 30 && waitingCars <= 3 && !objectivesCompleted['no_traffic_jams']!) {
      objectives['no_traffic_jams'] = true;
      objectivesCompleted['no_traffic_jams'] = true;
      _awardObjectiveBonus('Traffic Master', 250);
    }
  }

  void _awardObjectiveBonus(String objectiveName, int bonus) {
    score += bonus;

    // Track objective completion analytics
    AnalyticsService.logObjectiveCompleted(objectiveName);
    
    // Play special achievement sound and haptic
    AudioManager().playPerfectFlow();
    MobileManager().successHaptic();
    
    scorePopups.add(ScorePopup(
      x: gameWidth / 2,
      y: gameHeight / 2 - 50,
      text: '$objectiveName: +$bonus',
      timer: 180,
      color: Color(0xFF4CAF50), // Green for achievements to distinguish from regular scores
    ));
  }

  void _checkGameOverConditions() {
    if (isGameOver) return;

    int waitingCars = getWaitingCarsCount();
    int successRate = getSuccessRate();

    if (waitingCars >= 7) {
      isGameOver = true;
      gameOverReason = 'Too many cars waiting! ($waitingCars cars)';
      _trackGameOverAnalytics('traffic_jam');
      _saveGameScore();
      return;
    }

    if (successRate < 70 && totalCarsCrashed > 5) {
      isGameOver = true;
      gameOverReason = 'Poor performance! ($successRate% success, $totalCarsCrashed crashes)';
      _trackGameOverAnalytics('poor_performance');
      _saveGameScore();
      return;
    }
  }

  void toggleTrafficLight(Direction direction) {
    trafficLights[direction] = trafficLights[direction] == LightState.red
        ? LightState.green
        : LightState.red;
  }

  void changeDifficulty(Difficulty newDifficulty) {
    if (currentDifficulty != newDifficulty) {
      currentDifficulty = newDifficulty;
      
      // Update existing cars' speed
      for (Car car in cars) {
        if (!car.crashed) {
          car.speed = difficultySettings[newDifficulty]!.carSpeed;
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
    gameStarted = true;  // Keep game running after restart
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
    return totalCarsSpawned > 0 ? ((totalCarsPassed / totalCarsSpawned) * 100).round() : 100;
  }

  Color getDifficultyColor() {
    return difficultySettings[currentDifficulty]!.color;
  }

  double getDifficultyMultiplier() {
    return difficultySettings[currentDifficulty]!.scoreMultiplier;
  }

  // Analytics helper methods
  void _checkScoreMilestones(int oldScore, int newScore) {
    List<int> milestones = [100, 250, 500, 1000, 2000, 5000, 10000];
    
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
    ScoreService().saveScore(
      score: score,
      difficulty: currentDifficulty.name,
      carsPassed: totalCarsPassed,
      successRate: getSuccessRate().toDouble(),
      objectives: Map<String, dynamic>.from(objectives),
    ).catchError((error) {
      // Handle errors silently in background
      print('Failed to save score: $error');
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
    double intersectionEdge = _getIntersectionEdge(gameState);
    bool shouldStop = false;

    // Check if car should stop at red light
    if (!hasPassedIntersection && type != CarType.ambulance && type != CarType.police &&
        gameState.trafficLights[from] == LightState.red) {
      double distanceToIntersection = _getDistanceToIntersection(gameState, intersectionEdge);
      if (distanceToIntersection <= 30) {
        shouldStop = true;
      }
    }

    // Check if car should stop behind another car
    if (!shouldStop && !crashed && type != CarType.police) {
      Car? carAhead = _getCarAhead(gameState);
      if (carAhead != null) {
        double distance = math.sqrt(math.pow(x - carAhead.x, 2) + math.pow(y - carAhead.y, 2));
        double largerSize = math.max(getSize(), carAhead.getSize());
        double safeDistance = largerSize * 1.5;
        if (distance < safeDistance) {
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

  double _getDistanceToIntersection(GameState gameState, double intersectionEdge) {
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

        if (isAhead && distance > 0 && distance < 200 && distance < closestDistance) {
          closestCar = otherCar;
          closestDistance = distance;
        }
      }
    }

    return closestCar;
  }

  bool isOffScreen(double gameWidth, double gameHeight) {
    return x < -50 || x > gameWidth + 50 || y < -50 || y > gameHeight + 50;
  }

  double getSize() {
    switch (type) {
      case CarType.ambulance:
        return 24;
      case CarType.police:
        return 22;
      case CarType.tractor:
        return 18;
      case CarType.schoolBus:
        return 84;
      case CarType.impatient:
      case CarType.regular:
        return 20;
    }
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

class DifficultySettings {
  final int carSpawnInterval;
  final double carSpeed;
  final double scoreMultiplier;
  final Color color;

  DifficultySettings(this.carSpawnInterval, this.carSpeed, this.scoreMultiplier, this.color);
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

  CrashEffect({
    required this.x,
    required this.y,
    required this.timer,
  });
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
    vy += 0.05; // Gravity
    life--;
  }
}

class TrafficLightTouchArea {
  Direction direction;
  Rect bounds;

  TrafficLightTouchArea({
    required this.direction,
    required this.bounds,
  });
}