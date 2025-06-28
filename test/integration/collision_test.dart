import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuesdae_rush/game_state.dart';

void main() {
  group('Collision Integration Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initialize();
      gameState.updateDimensions(800, 600);
    });

    tearDown(() {
      gameState.cars.clear();
      gameState.scorePopups.clear();
      gameState.crashEffects.clear();
    });

    group('Perpendicular Collisions', () {
      test('should detect collision between perpendicular cars', () {
        // Create car from north
        Car northCar = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        northCar.x = 400;
        northCar.y = 300;
        
        // Create car from east
        Car eastCar = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        eastCar.x = 400;
        eastCar.y = 300;
        
        gameState.cars.add(northCar);
        gameState.cars.add(eastCar);
        
        gameState.update();
        
        expect(northCar.crashed, equals(true));
        expect(eastCar.crashed, equals(true));
        expect(gameState.totalCarsCrashed, equals(2));
        expect(gameState.crashEffects.length, equals(1));
        expect(gameState.score, lessThan(0)); // Score penalty
      });

      test('should not detect collision between parallel cars', () {
        // Create two cars from same direction
        Car car1 = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        car1.x = 380;
        car1.y = 300;
        
        Car car2 = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        car2.x = 420;
        car2.y = 300;
        
        gameState.cars.add(car1);
        gameState.cars.add(car2);
        
        gameState.update();
        
        expect(car1.crashed, equals(false));
        expect(car2.crashed, equals(false));
        expect(gameState.totalCarsCrashed, equals(0));
      });
    });

    group('Emergency Vehicle Collision Rules', () {
      test('emergency vehicles should not crash with each other', () {
        // Create ambulance
        Car ambulance = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.ambulance,
          color: Colors.white,
        );
        ambulance.x = 400;
        ambulance.y = 300;
        
        // Create police car
        Car police = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.police,
          color: Colors.blue,
        );
        police.x = 400;
        police.y = 300;
        
        gameState.cars.add(ambulance);
        gameState.cars.add(police);
        
        gameState.update();
        
        expect(ambulance.crashed, equals(false));
        expect(police.crashed, equals(false));
        expect(gameState.totalCarsCrashed, equals(0));
      });

      test('ambulance should crash with regular car', () {
        // Create ambulance
        Car ambulance = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.ambulance,
          color: Colors.white,
        );
        ambulance.x = 400;
        ambulance.y = 300;
        
        // Create regular car
        Car regular = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        regular.x = 400;
        regular.y = 300;
        
        gameState.cars.add(ambulance);
        gameState.cars.add(regular);
        
        gameState.update();
        
        expect(ambulance.crashed, equals(true));
        expect(regular.crashed, equals(true));
        expect(gameState.totalCarsCrashed, equals(2));
      });

      test('police should crash with regular car', () {
        // Create police car
        Car police = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.police,
          color: Colors.blue,
        );
        police.x = 400;
        police.y = 300;
        
        // Create regular car
        Car regular = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        regular.x = 400;
        regular.y = 300;
        
        gameState.cars.add(police);
        gameState.cars.add(regular);
        
        gameState.update();
        
        expect(police.crashed, equals(true));
        expect(regular.crashed, equals(true));
        expect(gameState.totalCarsCrashed, equals(2));
      });
    });

    group('Police Rear-End Collision', () {
      test('police should rear-end stopped car at red light', () {
        // Create stopped regular car at red light
        Car stoppedCar = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        stoppedCar.x = 400;
        stoppedCar.y = 280;
        stoppedCar.stopped = true;
        stoppedCar.hasPassedIntersection = false;
        
        // Set red light
        gameState.trafficLights[Direction.north] = LightState.red;
        
        // Create police car behind
        Car police = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.police,
          color: Colors.blue,
        );
        police.x = 400;
        police.y = 260;
        
        gameState.cars.add(stoppedCar);
        gameState.cars.add(police);
        
        gameState.update();
        
        expect(stoppedCar.crashed, equals(true));
        expect(police.crashed, equals(true));
        expect(gameState.totalCarsCrashed, equals(2));
      });

      test('police should not rear-end car that has passed intersection', () {
        // Create car that has passed intersection
        Car passedCar = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        passedCar.x = 400;
        passedCar.y = 280;
        passedCar.stopped = true;
        passedCar.hasPassedIntersection = true; // Key difference
        
        // Create police car behind
        Car police = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.police,
          color: Colors.blue,
        );
        police.x = 400;
        police.y = 260;
        
        gameState.cars.add(passedCar);
        gameState.cars.add(police);
        
        gameState.update();
        
        expect(passedCar.crashed, equals(false));
        expect(police.crashed, equals(false));
        expect(gameState.totalCarsCrashed, equals(0));
      });

      test('police should not rear-end car at green light', () {
        // Create stopped regular car at green light
        Car stoppedCar = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        stoppedCar.x = 400;
        stoppedCar.y = 280;
        stoppedCar.stopped = true;
        stoppedCar.hasPassedIntersection = false;
        
        // Set green light
        gameState.trafficLights[Direction.north] = LightState.green;
        
        // Create police car behind
        Car police = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.police,
          color: Colors.blue,
        );
        police.x = 400;
        police.y = 260;
        
        gameState.cars.add(stoppedCar);
        gameState.cars.add(police);
        
        gameState.update();
        
        expect(stoppedCar.crashed, equals(false));
        expect(police.crashed, equals(false));
        expect(gameState.totalCarsCrashed, equals(0));
      });
    });

    group('Collision Distance Calculation', () {
      test('should detect collision within collision threshold', () {
        Car car1 = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        car1.x = 400;
        car1.y = 300;
        
        Car car2 = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        // Place car2 just within collision distance
        double collisionThreshold = (car1.getSize() + car2.getSize()) / 2;
        car2.x = 400 + collisionThreshold - 1;
        car2.y = 300;
        
        gameState.cars.add(car1);
        gameState.cars.add(car2);
        
        gameState.update();
        
        expect(car1.crashed, equals(true));
        expect(car2.crashed, equals(true));
      });

      test('should not detect collision outside collision threshold', () {
        Car car1 = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        car1.x = 400;
        car1.y = 300;
        
        Car car2 = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        // Place car2 just outside collision distance
        double collisionThreshold = (car1.getSize() + car2.getSize()) / 2;
        car2.x = 400 + collisionThreshold + 1;
        car2.y = 300;
        
        gameState.cars.add(car1);
        gameState.cars.add(car2);
        
        gameState.update();
        
        expect(car1.crashed, equals(false));
        expect(car2.crashed, equals(false));
      });
    });

    group('Collision Effects', () {
      test('should create crash effect when collision occurs', () {
        Car car1 = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        car1.x = 400;
        car1.y = 300;
        
        Car car2 = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        car2.x = 400;
        car2.y = 300;
        
        gameState.cars.add(car1);
        gameState.cars.add(car2);
        
        int initialCrashEffects = gameState.crashEffects.length;
        gameState.update();
        
        expect(gameState.crashEffects.length, equals(initialCrashEffects + 1));
        
        CrashEffect effect = gameState.crashEffects.last;
        expect(effect.x, equals(400)); // Average of both car positions
        expect(effect.y, equals(300));
        expect(effect.timer, equals(60));
      });

      test('should create score popup for collision penalty', () {
        Car car1 = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        car1.x = 400;
        car1.y = 300;
        
        Car car2 = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        car2.x = 400;
        car2.y = 300;
        
        gameState.cars.add(car1);
        gameState.cars.add(car2);
        
        int initialPopups = gameState.scorePopups.length;
        gameState.update();
        
        expect(gameState.scorePopups.length, equals(initialPopups + 1));
        
        ScorePopup popup = gameState.scorePopups.last;
        expect(popup.text, equals('-5'));
        expect(popup.color, equals(Color(0xFFFF6464)));
      });

      test('should set crashed cars properties correctly', () {
        Car car1 = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        car1.x = 400;
        car1.y = 300;
        
        Car car2 = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        car2.x = 400;
        car2.y = 300;
        
        gameState.cars.add(car1);
        gameState.cars.add(car2);
        
        gameState.update();
        
        // Check both cars are marked as crashed
        expect(car1.crashed, equals(true));
        expect(car2.crashed, equals(true));
        
        // Check both cars are stopped
        expect(car1.stopped, equals(true));
        expect(car2.stopped, equals(true));
        
        // Check speed is set to 0
        expect(car1.speed, equals(0));
        expect(car2.speed, equals(0));
        
        // Check color changed to red
        expect(car1.color, equals(Colors.red));
        expect(car2.color, equals(Colors.red));
        
        // Check removal timer is set
        expect(car1.removalTimer, equals(300));
        expect(car2.removalTimer, equals(300));
      });
    });

    group('Multiple Collision Scenarios', () {
      test('should handle multiple simultaneous collisions', () {
        // Create collision 1
        Car car1a = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.blue,
        );
        car1a.x = 300;
        car1a.y = 300;
        
        Car car1b = Car(
          from: Direction.east,
          to: Direction.west,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.red,
        );
        car1b.x = 300;
        car1b.y = 300;
        
        // Create collision 2
        Car car2a = Car(
          from: Direction.north,
          to: Direction.south,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.green,
        );
        car2a.x = 500;
        car2a.y = 300;
        
        Car car2b = Car(
          from: Direction.west,
          to: Direction.east,
          speed: 2.0,
          type: CarType.regular,
          color: Colors.yellow,
        );
        car2b.x = 500;
        car2b.y = 300;
        
        gameState.cars.addAll([car1a, car1b, car2a, car2b]);
        
        gameState.update();
        
        expect(gameState.totalCarsCrashed, equals(4));
        expect(gameState.crashEffects.length, equals(2));
        expect(gameState.scorePopups.length, equals(2));
      });
    });
  });
}

// Extension to make private methods testable
extension GameStateCollisionTestHelpers on GameState {
  // Remove private method calls - test through public update method
}
