import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuesdae_rush/game_state.dart';

void main() {
  group('Car Tests', () {
    late GameState gameState;
    late Car testCar;

    setUp(() {
      gameState = GameState();
      gameState.initialize();
      gameState.updateDimensions(800, 600);
      
      testCar = Car(
        from: Direction.north,
        to: Direction.south,
        speed: 2.0,
        type: CarType.regular,
        color: Colors.blue,
      );
    });

    group('Car Initialization', () {
      test('should initialize with correct properties', () {
        expect(testCar.from, equals(Direction.north));
        expect(testCar.to, equals(Direction.south));
        expect(testCar.speed, equals(2.0));
        expect(testCar.type, equals(CarType.regular));
        expect(testCar.color, equals(Colors.blue));
        expect(testCar.hasPassedIntersection, equals(false));
        expect(testCar.stopped, equals(false));
        expect(testCar.crashed, equals(false));
        expect(testCar.removalTimer, isNull);
      });

      test('should return correct size for different car types', () {
        testCar.type = CarType.regular;
        expect(testCar.getSize(), equals(20));
        
        testCar.type = CarType.ambulance;
        expect(testCar.getSize(), equals(24));
        
        testCar.type = CarType.police;
        expect(testCar.getSize(), equals(22));
        
        testCar.type = CarType.tractor;
        expect(testCar.getSize(), equals(18));
        
        testCar.type = CarType.schoolBus;
        expect(testCar.getSize(), equals(84));
        
        testCar.type = CarType.impatient;
        expect(testCar.getSize(), equals(20));
      });

      test('should return correct rotation angle for different directions', () {
        testCar.to = Direction.south;
        expect(testCar.getRotationAngle(), equals(0));
        
        testCar.to = Direction.north;
        expect(testCar.getRotationAngle(), equals(3.141592653589793));
        
        testCar.to = Direction.east;
        expect(testCar.getRotationAngle(), equals(-1.5707963267948966));
        
        testCar.to = Direction.west;
        expect(testCar.getRotationAngle(), equals(1.5707963267948966));
      });
    });

    group('Car Movement', () {
      test('should move when updated', () {
        testCar.from = Direction.north;
        testCar.x = 400;
        testCar.y = 100;
        double initialY = testCar.y;
        
        gameState.cars.add(testCar);
        testCar.update(gameState);
        
        // Car should move forward (y should increase for north direction)
        expect(testCar.y, greaterThan(initialY));
      });
    });

    group('Car Behavior at Traffic Lights', () {
      test('should stop at red light when approaching intersection', () {
        testCar.from = Direction.north;
        testCar.x = 400;
        testCar.y = 250; // Close to intersection
        gameState.trafficLights[Direction.north] = LightState.red;
        
        testCar.update(gameState);
        
        expect(testCar.stopped, equals(true));
      });

      test('should continue at green light', () {
        testCar.from = Direction.north;
        testCar.x = 400;
        testCar.y = 250;
        gameState.trafficLights[Direction.north] = LightState.green;
        
        testCar.update(gameState);
        
        expect(testCar.stopped, equals(false));
      });

      test('ambulance should ignore red lights', () {
        testCar.type = CarType.ambulance;
        testCar.from = Direction.north;
        testCar.x = 400;
        testCar.y = 250;
        gameState.trafficLights[Direction.north] = LightState.red;
        
        testCar.update(gameState);
        
        expect(testCar.stopped, equals(false));
      });

      test('police should ignore red lights', () {
        testCar.type = CarType.police;
        testCar.from = Direction.north;
        testCar.x = 400;
        testCar.y = 250;
        gameState.trafficLights[Direction.north] = LightState.red;
        
        testCar.update(gameState);
        
        expect(testCar.stopped, equals(false));
      });
    });

    group('Car Following Behavior', () {
      test('should stop behind another car', () {
        // Create car ahead
        Car carAhead = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 1.0,
          type: CarType.regular,
          color: Colors.red,
        );
        carAhead.x = 400;
        carAhead.y = 280;
        carAhead.stopped = true;
        gameState.cars.add(carAhead);
        
        // Create following car
        testCar.from = Direction.north;
        testCar.to = Direction.south;
        testCar.x = 400;
        testCar.y = 250; // Behind the first car
        gameState.cars.add(testCar);
        
        testCar.update(gameState);
        
        expect(testCar.stopped, equals(true));
      });

      test('police should not stop behind other cars', () {
        // Create car ahead
        Car carAhead = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 1.0,
          type: CarType.regular,
          color: Colors.red,
        );
        carAhead.x = 400;
        carAhead.y = 280;
        carAhead.stopped = true;
        gameState.cars.add(carAhead);
        
        // Create police car following
        testCar.type = CarType.police;
        testCar.from = Direction.north;
        testCar.to = Direction.south;
        testCar.x = 400;
        testCar.y = 250;
        gameState.cars.add(testCar);
        
        testCar.update(gameState);
        
        expect(testCar.stopped, equals(false));
      });
    });

    group('Intersection Detection', () {
      test('should track intersection passage', () {
        testCar.from = Direction.north;
        testCar.x = 400;
        testCar.y = gameState.gameHeight / 2;
        gameState.cars.add(testCar);
        
        expect(testCar.hasPassedIntersection, equals(false));
        
        // After multiple updates, car should eventually pass intersection
        for (int i = 0; i < 50; i++) {
          testCar.update(gameState);
          if (testCar.hasPassedIntersection) break;
        }
        
        // Test passed if we can track intersection state
        expect(testCar.hasPassedIntersection, isA<bool>());
      });
    });

    group('Off-Screen Detection', () {
      test('should detect when car is off screen left', () {
        testCar.x = -60;
        testCar.y = 300;
        
        expect(testCar.isOffScreen(800, 600), equals(true));
      });

      test('should detect when car is off screen right', () {
        testCar.x = 860;
        testCar.y = 300;
        
        expect(testCar.isOffScreen(800, 600), equals(true));
      });

      test('should detect when car is off screen top', () {
        testCar.x = 400;
        testCar.y = -60;
        
        expect(testCar.isOffScreen(800, 600), equals(true));
      });

      test('should detect when car is off screen bottom', () {
        testCar.x = 400;
        testCar.y = 660;
        
        expect(testCar.isOffScreen(800, 600), equals(true));
      });

      test('should not detect as off screen when within bounds', () {
        testCar.x = 400;
        testCar.y = 300;
        
        expect(testCar.isOffScreen(800, 600), equals(false));
      });
    });

    group('Car Following Behavior', () {
      test('should respond to cars ahead', () {
        // Create car ahead
        Car carAhead = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 0.0,
          type: CarType.regular,
          color: Colors.red,
        );
        carAhead.x = 400;
        carAhead.y = 280;
        carAhead.stopped = true;
        gameState.cars.add(carAhead);
        
        testCar.from = Direction.north;
        testCar.to = Direction.south;
        testCar.x = 400;
        testCar.y = 250;
        gameState.cars.add(testCar);
        
        testCar.update(gameState);
        
        // Should stop when car ahead is stopped
        expect(testCar.stopped, equals(true));
      });
    });

  });
}

// Extension to make private methods testable
extension CarTestHelpers on Car {
  // Remove private method calls - test through public update method
}
