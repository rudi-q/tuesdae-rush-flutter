import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/analytics_service.dart';
import '../../audio/audio_manager.dart';
import '../../responsiveness/mobile_manager.dart';
import '../domain/game_state.dart';
import 'game_painter.dart';

class GameCanvas extends StatefulWidget {
  final GameState gameState;

  const GameCanvas({super.key, required this.gameState});

  @override
  GameCanvasState createState() => GameCanvasState();
}

class GameCanvasState extends State<GameCanvas> {
  ui.Image? backgroundImage;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/grass_texture.jpg');
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          backgroundImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Failed to load background image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main game graphics
        CustomPaint(
          size: Size.infinite,
          painter: GamePainter(widget.gameState, backgroundImage),
        ),

        // Touch areas for traffic lights
        ...widget.gameState.getTrafficLightTouchAreas().map((touchArea) {
          return Positioned(
            left: touchArea.bounds.left,
            top: touchArea.bounds.top,
            width: touchArea.bounds.width,
            height: touchArea.bounds.height,
            child: GestureDetector(
              onTap: () {
                widget.gameState.toggleTrafficLight(touchArea.direction);
                AudioManager().playTrafficLightSwitch();
                MobileManager().lightHaptic();
                AnalyticsService.logTrafficLightToggle(touchArea.direction.name);
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          );
        }),
      ],
    );
  }
}