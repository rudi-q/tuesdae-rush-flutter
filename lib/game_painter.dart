import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_state.dart';

class GamePainter extends CustomPainter {
  final GameState gameState;
  late double centerX;
  late double centerY;

  GamePainter(this.gameState) {
    centerX = gameState.gameWidth / 2;
    centerY = gameState.gameHeight / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Update game dimensions
    gameState.updateDimensions(size.width, size.height);
    centerX = size.width / 2;
    centerY = size.height / 2;

    // Draw background
    _drawBackground(canvas, size);

    // Draw scenery (trees)
    _drawTrees(canvas, size);

    // Draw roads
    _drawRoads(canvas, size);

    // Draw intersection
    _drawIntersection(canvas, size);

    // Draw traffic lights
    _drawTrafficLights(canvas, size);

    // Draw cars
    for (Car car in gameState.cars) {
      _drawCar(canvas, car);
    }

    // Draw effects
    _drawCrashEffects(canvas);
    _drawParticles(canvas);
    _drawScorePopups(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1B5E20), // Dark green
          Color(0xFF2E7D32), // Medium green
          Color(0xFF388E3C), // Forest green
          Color(0xFF43A047), // Light green
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    //  If you want to use an actual image (uncomment below):
  /*  final ui.Image backgroundImage = Image.asset('assets/images/grass_texture.jpg');
    if (backgroundImage != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        image: backgroundImage,
        fit: BoxFit.cover,
      );
    }*/

    // Add subtle texture overlay
    _drawBackgroundTexture(canvas, size);
  }

  void _drawBackgroundTexture(Canvas canvas, Size size) {
    // Create subtle grass-like texture with small dots
    final texturePaint = Paint()
      ..color = Color(0xFF4CAF50).withValues(alpha: 0.3);

    math.Random random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 200; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = 0.5 + random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, texturePaint);
    }
  }

  void _drawTrees(Canvas canvas, Size size) {
    // Fixed tree positions to prevent flickering
    List<TreeData> trees = [
      // Top left area
      TreeData(50, 50, 18), TreeData(120, 40, 22), TreeData(90, 120, 20),
      TreeData(160, 100, 19), TreeData(200, 60, 24), TreeData(250, 130, 17),
      
      // Top right area (scaled to screen width)
      TreeData(size.width - 250, 70, 23), TreeData(size.width - 180, 45, 18),
      TreeData(size.width - 120, 90, 20), TreeData(size.width - 210, 140, 25),
      
      // Bottom left area
      TreeData(80, size.height - 180, 20), TreeData(150, size.height - 150, 24),
      TreeData(200, size.height - 120, 18), TreeData(120, size.height - 80, 19),
      
      // Bottom right area
      TreeData(size.width - 220, size.height - 160, 21), TreeData(size.width - 150, size.height - 130, 17),
      TreeData(size.width - 80, size.height - 180, 24), TreeData(size.width - 180, size.height - 80, 18),
    ];

    for (TreeData tree in trees) {
      _drawTree(canvas, tree.x, tree.y, tree.size);
    }

    // Draw bushes
    List<BushData> bushes = [
      BushData(centerX - 100, 80), BushData(centerX - 50, 70),
      BushData(centerX + 50, 85), BushData(centerX + 100, 75),
      BushData(centerX - 80, size.height - 80), BushData(centerX + 80, size.height - 80),
    ];

    for (BushData bush in bushes) {
      _drawBush(canvas, bush.x, bush.y);
    }
  }

  void _drawTree(Canvas canvas, double x, double y, double size) {
    // Tree trunk
    final trunkPaint = Paint()
      ..color = Color(0xFF654321); // Brown
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: size / 4, height: size / 2),
      trunkPaint,
    );

    // Tree foliage (multiple circles for natural look)
    final foliage1Paint = Paint()..color = Color(0xFF2E7D32); // Dark green
    canvas.drawCircle(Offset(x, y - size / 4), size / 2, foliage1Paint);

    final foliage2Paint = Paint()..color = Color(0xFF388E3C); // Medium green
    canvas.drawCircle(Offset(x - size / 6, y - size / 3), size * 0.4, foliage2Paint);

    final foliage3Paint = Paint()..color = Color(0xFF4CAF50); // Light green
    canvas.drawCircle(Offset(x + size / 6, y - size / 4), size * 0.35, foliage3Paint);
  }

  void _drawBush(Canvas canvas, double x, double y) {
    final bush1Paint = Paint()..color = Color(0xFF388E3C); // Medium green
    canvas.drawCircle(Offset(x, y), 10, bush1Paint);

    final bush2Paint = Paint()..color = Color(0xFF4CAF50); // Light green
    canvas.drawCircle(Offset(x - 5, y), 7.5, bush2Paint);

    final bush3Paint = Paint()..color = Color(0xFF2E7D32); // Dark green
    canvas.drawCircle(Offset(x + 4, y), 6, bush3Paint);
  }

  void _drawRoads(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Color(0xFF34495E); // Dark road color

    // Horizontal road
    canvas.drawRect(
      Rect.fromLTWH(0, centerY - gameState.roadWidth / 2, size.width, gameState.roadWidth),
      roadPaint,
    );

    // Vertical road
    canvas.drawRect(
      Rect.fromLTWH(centerX - gameState.roadWidth / 2, 0, gameState.roadWidth, size.height),
      roadPaint,
    );

    // Draw road markings
    _drawRoadMarkings(canvas, size);
  }

  void _drawRoadMarkings(Canvas canvas, Size size) {
    final edgeLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    final centerLinePaint = Paint()
      ..color = Color(0xFFF1C40F) // Yellow
      ..strokeWidth = 3;

    final laneDividerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Horizontal road edges
    canvas.drawLine(
      Offset(0, centerY - gameState.roadWidth / 2),
      Offset(size.width, centerY - gameState.roadWidth / 2),
      edgeLinePaint,
    );
    canvas.drawLine(
      Offset(0, centerY + gameState.roadWidth / 2),
      Offset(size.width, centerY + gameState.roadWidth / 2),
      edgeLinePaint,
    );

    // Vertical road edges
    canvas.drawLine(
      Offset(centerX - gameState.roadWidth / 2, 0),
      Offset(centerX - gameState.roadWidth / 2, size.height),
      edgeLinePaint,
    );
    canvas.drawLine(
      Offset(centerX + gameState.roadWidth / 2, 0),
      Offset(centerX + gameState.roadWidth / 2, size.height),
      edgeLinePaint,
    );

    // Horizontal road center line (dashed)
    for (double x = 0; x < size.width; x += 30) {
      if (x < centerX - gameState.intersectionSize / 2 || x > centerX + gameState.intersectionSize / 2) {
        canvas.drawLine(
          Offset(x, centerY),
          Offset(x + 15, centerY),
          centerLinePaint,
        );
      }
    }

    // Vertical road center line (dashed)
    for (double y = 0; y < size.height; y += 30) {
      if (y < centerY - gameState.intersectionSize / 2 || y > centerY + gameState.intersectionSize / 2) {
        canvas.drawLine(
          Offset(centerX, y),
          Offset(centerX, y + 15),
          centerLinePaint,
        );
      }
    }

    // Lane dividers (dashed)
    for (double x = 0; x < size.width; x += 25) {
      if (x < centerX - gameState.intersectionSize / 2 || x > centerX + gameState.intersectionSize / 2) {
        // Upper lane divider
        canvas.drawLine(
          Offset(x, centerY - gameState.roadWidth / 4),
          Offset(x + 12, centerY - gameState.roadWidth / 4),
          laneDividerPaint,
        );
        // Lower lane divider
        canvas.drawLine(
          Offset(x, centerY + gameState.roadWidth / 4),
          Offset(x + 12, centerY + gameState.roadWidth / 4),
          laneDividerPaint,
        );
      }
    }

    for (double y = 0; y < size.height; y += 25) {
      if (y < centerY - gameState.intersectionSize / 2 || y > centerY + gameState.intersectionSize / 2) {
        // Left lane divider
        canvas.drawLine(
          Offset(centerX - gameState.roadWidth / 4, y),
          Offset(centerX - gameState.roadWidth / 4, y + 12),
          laneDividerPaint,
        );
        // Right lane divider
        canvas.drawLine(
          Offset(centerX + gameState.roadWidth / 4, y),
          Offset(centerX + gameState.roadWidth / 4, y + 12),
          laneDividerPaint,
        );
      }
    }
  }

  void _drawIntersection(Canvas canvas, Size size) {
    final intersectionPaint = Paint()
      ..color = Color(0xFF34495E); // Match road color

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: gameState.intersectionSize,
        height: gameState.intersectionSize,
      ),
      intersectionPaint,
    );

    // Add crosswalk markings
    _drawCrosswalks(canvas);
  }

  void _drawCrosswalks(Canvas canvas) {
    final crosswalkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;

    // Crosswalk stripes - North side
    for (int i = 0; i < 6; i++) {
      double x = centerX - gameState.intersectionSize / 2 + 20 + i * 30;
      canvas.drawLine(
        Offset(x, centerY - gameState.intersectionSize / 2),
        Offset(x, centerY - gameState.intersectionSize / 2 + 15),
        crosswalkPaint,
      );
    }

    // Crosswalk stripes - South side
    for (int i = 0; i < 6; i++) {
      double x = centerX - gameState.intersectionSize / 2 + 20 + i * 30;
      canvas.drawLine(
        Offset(x, centerY + gameState.intersectionSize / 2 - 15),
        Offset(x, centerY + gameState.intersectionSize / 2),
        crosswalkPaint,
      );
    }

    // Crosswalk stripes - East side
    for (int i = 0; i < 6; i++) {
      double y = centerY - gameState.intersectionSize / 2 + 20 + i * 30;
      canvas.drawLine(
        Offset(centerX + gameState.intersectionSize / 2 - 15, y),
        Offset(centerX + gameState.intersectionSize / 2, y),
        crosswalkPaint,
      );
    }

    // Crosswalk stripes - West side
    for (int i = 0; i < 6; i++) {
      double y = centerY - gameState.intersectionSize / 2 + 20 + i * 30;
      canvas.drawLine(
        Offset(centerX - gameState.intersectionSize / 2, y),
        Offset(centerX - gameState.intersectionSize / 2 + 15, y),
        crosswalkPaint,
      );
    }
  }

  void _drawTrafficLights(Canvas canvas, Size size) {
    double lightDistance = 120;

    _drawTrafficLight(canvas, Offset(centerX, centerY - lightDistance), gameState.trafficLights[Direction.north]!);
    _drawTrafficLight(canvas, Offset(centerX, centerY + lightDistance), gameState.trafficLights[Direction.south]!);
    _drawTrafficLight(canvas, Offset(centerX + lightDistance, centerY), gameState.trafficLights[Direction.east]!);
    _drawTrafficLight(canvas, Offset(centerX - lightDistance, centerY), gameState.trafficLights[Direction.west]!);
  }

  void _drawTrafficLight(Canvas canvas, Offset position, LightState state) {
    double housingWidth = 36;
    double housingHeight = 90;

    // Light post
    final postPaint = Paint()
      ..color = Color(0xFF7F8C8D); // Gray post
    canvas.drawRect(
      Rect.fromCenter(center: Offset(position.dx, position.dy + housingHeight / 2 + 20), width: 4, height: 40),
      postPaint,
    );

    // Light housing
    final housingPaint = Paint()
      ..color = Color(0xFF2C3E50);
    final housingStrokePaint = Paint()
      ..color = Color(0xFF34495E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    RRect housing = RRect.fromRectAndRadius(
      Rect.fromCenter(center: position, width: housingWidth, height: housingHeight),
      Radius.circular(8),
    );
    canvas.drawRRect(housing, housingPaint);
    canvas.drawRRect(housing, housingStrokePaint);

    double lightSpacing = 22;

    // Red light (top)
    Color redColor = state == LightState.red ? Color(0xFFFF453A) : Color(0xFF8B4545);
    final redPaint = Paint()..color = redColor;
    canvas.drawCircle(Offset(position.dx, position.dy - lightSpacing), 8, redPaint);

    // Add glow effect for active red light
    if (state == LightState.red) {
      final glowPaint = Paint()
        ..color = Color(0xFFFF453A).withValues(alpha: 0.4);
      canvas.drawCircle(Offset(position.dx, position.dy - lightSpacing), 12, glowPaint);
    }

    // Yellow light (middle) - always dim
    final yellowPaint = Paint()..color = Color(0xFFF4D03F).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(position.dx, position.dy), 8, yellowPaint);

    // Green light (bottom)
    Color greenColor = state == LightState.green ? Color(0xFF2E7D32) : Color(0xFF458B45);
    final greenPaint = Paint()..color = greenColor;
    canvas.drawCircle(Offset(position.dx, position.dy + lightSpacing), 8, greenPaint);

    // Add glow effect for active green light
    if (state == LightState.green) {
      final glowPaint = Paint()
        ..color = Color(0xFF2E7D32).withValues(alpha: 0.4);
      canvas.drawCircle(Offset(position.dx, position.dy + lightSpacing), 12, glowPaint);
    }
  }

  void _drawCar(Canvas canvas, Car car) {
    canvas.save();

    // Translate to car position
    canvas.translate(car.x, car.y);

    // Rotate car based on movement direction
    canvas.rotate(car.getRotationAngle());

    double carWidth = car.getSize();
    double carHeight = car.getSize() * 1.4;

    // Special sizing for school bus
    if (car.type == CarType.schoolBus) {
      carHeight = 90;
      carWidth = 30;
    }

    // Car body
    final carPaint = Paint()
      ..color = car.color;
    final carStrokePaint = Paint()
      ..color = Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    RRect carBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: carWidth, height: carHeight),
      Radius.circular(4),
    );
    canvas.drawRRect(carBody, carPaint);
    canvas.drawRRect(carBody, carStrokePaint);

    // Front windshield
    final windshieldPaint = Paint()
      ..color = Color(0xFFC8DCFF).withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -carHeight / 4), width: carWidth * 0.8, height: carHeight / 3),
        Radius.circular(2),
      ),
      windshieldPaint,
    );

    // Rear windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, carHeight / 4), width: carWidth * 0.8, height: carHeight / 3),
        Radius.circular(2),
      ),
      windshieldPaint,
    );

    // Headlights (white - at front)
    final headlightPaint = Paint()..color = Color(0xFFFFFFC8);
    canvas.drawCircle(Offset(-carWidth / 3, -carHeight / 2 + 2), 2, headlightPaint);
    canvas.drawCircle(Offset(carWidth / 3, -carHeight / 2 + 2), 2, headlightPaint);

    // Taillights (red - at rear)
    final taillightPaint = Paint()..color = Color(0xFFFF3232);
    canvas.drawCircle(Offset(-carWidth / 3, carHeight / 2 - 2), 1.5, taillightPaint);
    canvas.drawCircle(Offset(carWidth / 3, carHeight / 2 - 2), 1.5, taillightPaint);

    // Draw special effects based on car type
    _drawCarSpecialEffects(canvas, car, carWidth, carHeight);

    canvas.restore();
  }

  void _drawCarSpecialEffects(Canvas canvas, Car car, double carWidth, double carHeight) {
    switch (car.type) {
      case CarType.ambulance:
        _drawAmbulanceEffects(canvas, carWidth, carHeight);
        break;
      case CarType.police:
        _drawPoliceEffects(canvas, carWidth, carHeight);
        break;
      case CarType.tractor:
        _drawTractorEffects(canvas, carWidth, carHeight);
        break;
      case CarType.schoolBus:
        _drawSchoolBusEffects(canvas, carWidth, carHeight);
        break;
      default:
        break;
    }

    // Draw crash effects if crashed
    if (car.crashed) {
      _drawCarCrashEffect(canvas);
    }
  }

  void _drawAmbulanceEffects(Canvas canvas, double carWidth, double carHeight) {
    double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Flashing lights
    double redAlpha = 0.8 + 0.2 * math.sin(time * 8);
    double blueAlpha = 0.8 + 0.2 * math.sin(time * 8 + math.pi);

    // Red light (left side)
    final redLightPaint = Paint()..color = Colors.red.withValues(alpha: redAlpha);
    canvas.drawCircle(Offset(-8, -16), 3, redLightPaint);

    // Blue light (right side)
    final blueLightPaint = Paint()..color = Colors.blue.withValues(alpha: blueAlpha);
    canvas.drawCircle(Offset(8, -16), 3, blueLightPaint);

    // Red cross symbol
    final crossPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;
    canvas.drawLine(Offset(-4, 0), Offset(4, 0), crossPaint);
    canvas.drawLine(Offset(0, -4), Offset(0, 4), crossPaint);

    // Light beams when flashing
    if (redAlpha > 0.9) {
      final beamPaint = Paint()..color = Colors.red.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(-8, -16), 15, beamPaint);
    }
    if (blueAlpha > 0.9) {
      final beamPaint = Paint()..color = Colors.blue.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(8, -16), 15, beamPaint);
    }
  }

  void _drawPoliceEffects(Canvas canvas, double carWidth, double carHeight) {
    double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Faster flashing lights
    double redAlpha = 0.9 + 0.1 * math.sin(time * 12);
    double blueAlpha = 0.9 + 0.1 * math.sin(time * 12 + math.pi);

    // Red light (left side)
    final redLightPaint = Paint()..color = Colors.red.withValues(alpha: redAlpha);
    canvas.drawCircle(Offset(-6, -16), 2.5, redLightPaint);

    // Blue light (right side)
    final blueLightPaint = Paint()..color = Colors.blue.withValues(alpha: blueAlpha);
    canvas.drawCircle(Offset(6, -16), 2.5, blueLightPaint);

    // Police badge (star)
    final badgePaint = Paint()..color = Color(0xFFFFD700).withValues(alpha: 0.6);
    canvas.drawCircle(Offset.zero, 3, badgePaint);

    // "POLICE" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'POLICE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 6,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 5));

    // Aggressive light beams
    if (redAlpha > 0.95) {
      final beamPaint = Paint()..color = Colors.red.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(-6, -16), 17.5, beamPaint);
    }
    if (blueAlpha > 0.95) {
      final beamPaint = Paint()..color = Colors.blue.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(6, -16), 17.5, beamPaint);
    }
  }

  void _drawTractorEffects(Canvas canvas, double carWidth, double carHeight) {
    // Tractor treads
    final treadPaint = Paint()
      ..color = Color(0xFF282828)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Left tread
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-6, 0), width: 4, height: 12),
        Radius.circular(1),
      ),
      treadPaint,
    );

    // Right tread
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(6, 0), width: 4, height: 12),
        Radius.circular(1),
      ),
      treadPaint,
    );

    // Exhaust pipe
    final exhaustPaint = Paint()..color = Color(0xFF141414);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -18), width: 6, height: 6),
        Radius.circular(2),
      ),
      exhaustPaint,
    );

    // Smoky exhaust
    double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    double smokeAlpha = 0.3 + 0.2 * math.sin(time * 2);
    
    final smokePaint = Paint()..color = Color(0xFF505050).withValues(alpha: smokeAlpha);
    canvas.drawCircle(Offset(0, -22), 4, smokePaint);
    canvas.drawCircle(Offset(3, -24), 3, smokePaint);
    canvas.drawCircle(Offset(0, -26), 2, smokePaint);

    // "SLOW" warning text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SLOW',
        style: TextStyle(
          color: Color(0xFFFFA500),
          fontSize: 6,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 5));
  }

  void _drawSchoolBusEffects(Canvas canvas, double carWidth, double carHeight) {
    double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    double busHalfLength = carHeight / 2;

    // Black stripes
    final stripePaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(-busHalfLength, -8, carHeight, 2), stripePaint);
    canvas.drawRect(Rect.fromLTWH(-busHalfLength, 8, carHeight, 2), stripePaint);

    // Stop sign arm (intermittent)
    if (math.sin(time * 4) > 0.5) {
      final stopSignPaint = Paint()..color = Colors.red;
      final stopSignStrokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(Rect.fromCenter(center: Offset(busHalfLength - 2, 0), width: 12, height: 8), stopSignPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(busHalfLength - 2, 0), width: 12, height: 8), stopSignStrokePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'STOP',
          style: TextStyle(color: Colors.white, fontSize: 4, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(busHalfLength - 8, -2));
    }

    // Flashing red lights
    double redAlpha = 0.8 + 0.2 * math.sin(time * 6);
    final flashingPaint = Paint()..color = Colors.red.withValues(alpha: redAlpha);

    canvas.drawCircle(Offset(-busHalfLength + 2, -6), 2, flashingPaint);
    canvas.drawCircle(Offset(-busHalfLength + 2, 6), 2, flashingPaint);
    canvas.drawCircle(Offset(busHalfLength - 2, -6), 2, flashingPaint);
    canvas.drawCircle(Offset(busHalfLength - 2, 6), 2, flashingPaint);

    // "SCHOOL BUS" text
    final schoolTextPainter = TextPainter(
      text: TextSpan(
        text: 'SCHOOL BUS',
        style: TextStyle(color: Colors.black, fontSize: 6, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    schoolTextPainter.layout();
    schoolTextPainter.paint(canvas, Offset(-schoolTextPainter.width / 2, -3));

    // "CAUTION" text
    final cautionTextPainter = TextPainter(
      text: TextSpan(
        text: 'CAUTION',
        style: TextStyle(color: Colors.red, fontSize: 4, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    cautionTextPainter.layout();
    cautionTextPainter.paint(canvas, Offset(-cautionTextPainter.width / 2, 6));

    // Light beams when flashing
    if (redAlpha > 0.9) {
      final beamPaint = Paint()..color = Colors.red.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(-busHalfLength + 2, 0), 12.5, beamPaint);
      canvas.drawCircle(Offset(busHalfLength - 2, 0), 12.5, beamPaint);
    }
  }

  void _drawCarCrashEffect(Canvas canvas) {
    // Small explosion effect for crashed cars
    for (int i = 0; i < 8; i++) {
      double angle = (i / 8) * 2 * math.pi;
      double sparkX = math.cos(angle) * 15;
      double sparkY = math.sin(angle) * 15;

      final sparkPaint = Paint()
        ..color = Color(0xFFFF9600)
        ..strokeWidth = 2;
      canvas.drawLine(Offset.zero, Offset(sparkX, sparkY), sparkPaint);

      final sparkDotPaint = Paint()..color = Color(0xFFFFC800);
      canvas.drawCircle(Offset(sparkX, sparkY), 1.5, sparkDotPaint);
    }
  }

  void _drawCrashEffects(Canvas canvas) {
    for (CrashEffect effect in gameState.crashEffects) {
      _drawExplosion(canvas, effect);
    }
  }

  void _drawExplosion(Canvas canvas, CrashEffect effect) {
    double progress = 1 - (effect.timer / 60.0);
    
    // Central explosion burst
    if (effect.timer > 30) {
      double burstAlpha = ((effect.timer - 30) / 30.0) * 0.6;
      final burstPaint1 = Paint()..color = Color(0xFFFF6400).withValues(alpha: burstAlpha);
      canvas.drawCircle(Offset(effect.x, effect.y), 15, burstPaint1);

      final burstPaint2 = Paint()..color = Color(0xFFFFC800).withValues(alpha: burstAlpha * 0.7);
      canvas.drawCircle(Offset(effect.x, effect.y), 10, burstPaint2);
    }

    // Explosion particles
    for (int i = 0; i < 12; i++) {
      double angle = (i / 12) * 2 * math.pi;
      double distance = progress * 20;
      double particleX = effect.x + math.cos(angle) * distance;
      double particleY = effect.y + math.sin(angle) * distance + progress * progress * 10; // Gravity

      double alpha = 1 - progress;
      final particlePaint = Paint()..color = Color(0xFFFF9600).withValues(alpha: alpha);
      canvas.drawCircle(Offset(particleX, particleY), 2, particlePaint);

      final innerParticlePaint = Paint()..color = Color(0xFFFFC800).withValues(alpha: alpha * 0.7);
      canvas.drawCircle(Offset(particleX, particleY), 1, innerParticlePaint);
    }
  }

  void _drawParticles(Canvas canvas) {
    for (Particle particle in gameState.particles) {
      double alpha = (particle.life / 45.0) * 0.8;
      final particlePaint = Paint()..color = particle.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(particle.x, particle.y), 2, particlePaint);

      // Add slight glow
      final glowPaint = Paint()..color = particle.color.withValues(alpha: alpha * 0.3);
      canvas.drawCircle(Offset(particle.x, particle.y), 4, glowPaint);
    }
  }

  void _drawScorePopups(Canvas canvas) {
    for (ScorePopup popup in gameState.scorePopups) {
      double alpha = (popup.timer / 90.0);
      
      // Enhanced text with glow for positive scores
      if (popup.text.contains('+')) {
        final glowPainter = TextPainter(
          text: TextSpan(
            text: popup.text,
            style: TextStyle(
              color: popup.color.withValues(alpha: alpha * 0.5),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: popup.color.withValues(alpha: alpha * 0.3),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        glowPainter.layout();
        glowPainter.paint(canvas, Offset(popup.x - glowPainter.width / 2, popup.y - glowPainter.height / 2));
      }

      // Main text
      final textPainter = TextPainter(
        text: TextSpan(
          text: popup.text,
          style: TextStyle(
            color: popup.color.withValues(alpha: alpha),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: alpha),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(popup.x - textPainter.width / 2, popup.y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TreeData {
  final double x;
  final double y;
  final double size;

  TreeData(this.x, this.y, this.size);
}

class BushData {
  final double x;
  final double y;

  BushData(this.x, this.y);
}