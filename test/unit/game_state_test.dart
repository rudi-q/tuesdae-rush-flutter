import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuesdae_rush/game_state.dart';
import 'package:tuesdae_rush/audio_manager.dart';

void main() {
  group('GameState Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initialize();
    });

    tearDown(() {
      gameState.cars.clear();
      gameState.scorePopups.clear();
      gameState.crashEffects.clear();
      gameState.particles.clear();
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(gameState.score, equals(0));
        expect(gameState.totalCarsSpawned, equals(0));
        expect(gameState.totalCarsPassed, equals(0));
        expect(gameState.totalCarsCrashed, equals(0));
        expect(gameState.isPaused, equals(false));
        expect(gameState.isGameOver, equals(false));
        expect(gameState.gameStarted, equals(false));
        expect(gameState.cars.length, equals(0));
        expect(gameState.currentDifficulty, equals(Difficulty.medium));
      });

      test('should initialize traffic lights correctly', () {
        expect(gameState.trafficLights.length, equals(4));
        expect(gameState.trafficLights[Direction.north], equals(LightState.green));
        expect(gameState.trafficLights[Direction.south], equals(LightState.green));
        expect(gameState.trafficLights[Direction.east], equals(LightState.red));
        expect(gameState.trafficLights[Direction.west], equals(LightState.red));
      });

      test('should initialize objectives correctly', () {
        expect(gameState.objectives.length, equals(6));
        expect(gameState.objectivesCompleted.length, equals(6));
        
        for (String key in gameState.objectives.keys) {
          expect(gameState.objectives[key], equals(false));
          expect(gameState.objectivesCompleted[key], equals(false));
        }
      });
    });

    group('Game Dimensions', () {
      test('should update dimensions correctly', () {
        gameState.updateDimensions(1200, 800);
        
        expect(gameState.gameWidth, equals(1200));
        expect(gameState.gameHeight, equals(800));
        expect(gameState.intersectionSize, greaterThan(150));
        expect(gameState.roadWidth, greaterThan(60));
      });

      test('should maintain minimum intersection and road sizes', () {
        gameState.updateDimensions(100, 100);
        
        expect(gameState.intersectionSize, equals(150));
        expect(gameState.roadWidth, equals(60));
      });

      test('should update touch areas when dimensions change', () {
        gameState.updateDimensions(800, 600);
        List<TrafficLightTouchArea> touchAreas = gameState.getTrafficLightTouchAreas();
        
        expect(touchAreas.length, equals(4));
        
        for (var area in touchAreas) {
          expect(area.bounds.width, greaterThanOrEqualTo(80));
          expect(area.bounds.height, greaterThanOrEqualTo(80));
        }
      });
    });

    group('Traffic Light Control', () {
      test('should toggle traffic light state', () {
        LightState initialState = gameState.trafficLights[Direction.north]!;
        gameState.toggleTrafficLight(Direction.north);
        
        expect(gameState.trafficLights[Direction.north], 
               equals(initialState == LightState.red ? LightState.green : LightState.red));
      });

      test('should toggle all directions correctly', () {
        for (Direction direction in Direction.values) {
          LightState initialState = gameState.trafficLights[direction]!;
          gameState.toggleTrafficLight(direction);
          
          expect(gameState.trafficLights[direction], 
                 equals(initialState == LightState.red ? LightState.green : LightState.red));
        }
      });
    });

    group('Difficulty Management', () {
      test('should change difficulty correctly', () {
        gameState.changeDifficulty(Difficulty.hard);
        expect(gameState.currentDifficulty, equals(Difficulty.hard));
      });

      test('should return correct difficulty color', () {
        gameState.changeDifficulty(Difficulty.easy);
        expect(gameState.getDifficultyColor(), equals(Color(0xFF2ECC71)));
        
        gameState.changeDifficulty(Difficulty.hard);
        expect(gameState.getDifficultyColor(), equals(Color(0xFFE74C3C)));
      });

      test('should return correct difficulty multiplier', () {
        gameState.changeDifficulty(Difficulty.easy);
        expect(gameState.getDifficultyMultiplier(), equals(1.0));
        
        gameState.changeDifficulty(Difficulty.insane);
        expect(gameState.getDifficultyMultiplier(), equals(3.0));
      });

      test('should update existing cars speed when difficulty changes', () {
        // Add a car
        Car testCar = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        gameState.cars.add(testCar);
        
        gameState.changeDifficulty(Difficulty.hard);
        expect(testCar.speed, equals(gameState.difficultySettings[Difficulty.hard]!.carSpeed));
      });
    });

    group('Game State Management', () {
      test('should toggle pause state', () {
        expect(gameState.isPaused, equals(false));
        gameState.togglePause();
        expect(gameState.isPaused, equals(true));
        gameState.togglePause();
        expect(gameState.isPaused, equals(false));
      });

      test('should start game correctly', () {
        expect(gameState.gameStarted, equals(false));
        gameState.startGame();
        expect(gameState.gameStarted, equals(true));
      });

      test('should restart game correctly', () {
        // Set up game state
        gameState.score = 100;
        gameState.totalCarsSpawned = 10;
        gameState.totalCarsPassed = 8;
        gameState.totalCarsCrashed = 2;
        gameState.isGameOver = true;
        gameState.cars.add(Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        ));
        
        gameState.restart();
        
        expect(gameState.score, equals(0));
        expect(gameState.totalCarsSpawned, equals(0));
        expect(gameState.totalCarsPassed, equals(0));
        expect(gameState.totalCarsCrashed, equals(0));
        expect(gameState.isGameOver, equals(false));
        expect(gameState.gameStarted, equals(true));
        expect(gameState.cars.length, equals(0));
        expect(gameState.scorePopups.length, equals(0));
        expect(gameState.crashEffects.length, equals(0));
        expect(gameState.particles.length, equals(0));
      });
    });

    group('Statistics', () {
      test('should calculate success rate correctly', () {
        expect(gameState.getSuccessRate(), equals(100)); // No cars spawned yet
        
        gameState.totalCarsSpawned = 10;
        gameState.totalCarsPassed = 8;
        expect(gameState.getSuccessRate(), equals(80));
        
        gameState.totalCarsSpawned = 0;
        expect(gameState.getSuccessRate(), equals(100));
      });

      test('should count waiting cars correctly', () {
        // Add a stopped car waiting at red light
        Car waitingCar = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        waitingCar.stopped = true;
        waitingCar.hasPassedIntersection = false;
        gameState.cars.add(waitingCar);
        
        // Set light to red for this direction
        gameState.trafficLights[Direction.north] = LightState.red;
        
        expect(gameState.getWaitingCarsCount(), equals(1));
        
        // Change light to green
        gameState.trafficLights[Direction.north] = LightState.green;
        expect(gameState.getWaitingCarsCount(), equals(0));
      });

      test('should not count crashed cars as waiting', () {
        Car crashedCar = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        crashedCar.stopped = true;
        crashedCar.crashed = true;
        crashedCar.hasPassedIntersection = false;
        gameState.cars.add(crashedCar);
        
        gameState.trafficLights[Direction.north] = LightState.red;
        expect(gameState.getWaitingCarsCount(), equals(0));
      });
    });

    group('Car Spawning', () {
      test('should spawn cars when game is running', () {
        gameState.gameStarted = true;
        gameState.carSpawnTimer = 0;
        gameState.nextSpawnTime = 0;
        
        int initialCars = gameState.cars.length;
        gameState.update();
        
        // Should have spawned a car or updated spawn timer
        expect(gameState.carSpawnTimer, greaterThan(0));
      });
    });

    group('Game Update Loop', () {
      test('should not update when paused', () {
        gameState.gameStarted = true;
        gameState.isPaused = true;
        
        int initialScore = gameState.score;
        gameState.update();
        
        expect(gameState.score, equals(initialScore));
      });

      test('should not update when game over', () {
        gameState.gameStarted = true;
        gameState.isGameOver = true;
        
        int initialScore = gameState.score;
        gameState.update();
        
        expect(gameState.score, equals(initialScore));
      });

      test('should not update when game not started', () {
        gameState.gameStarted = false;
        
        int initialScore = gameState.score;
        gameState.update();
        
        expect(gameState.score, equals(initialScore));
      });
    });

    group('Objectives', () {
      test('should track objectives progress', () {
        expect(gameState.objectives.containsKey('pass_20_cars'), equals(true));
        expect(gameState.objectives.containsKey('zero_crashes'), equals(true));
        expect(gameState.objectives.containsKey('efficiency_85'), equals(true));
      });
    });

    group('Game Over Detection', () {
      test('should detect game over state', () {
        expect(gameState.isGameOver, equals(false));
        
        // Game over can be triggered by update loop
        gameState.gameStarted = true;
        gameState.update();
        
        // Should not be game over initially
        expect(gameState.isGameOver, equals(false));
      });
    });
  });
}

// Extension to make private methods testable
extension GameStateTestHelpers on GameState {
  // Remove private method calls - test public methods instead
}
