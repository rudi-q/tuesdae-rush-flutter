import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_painter.dart';
import 'game_state.dart';

void main() {
  runApp(TuesdaeRushApp());
}

class TuesdaeRushApp extends StatelessWidget {
  const TuesdaeRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuesdae Rush',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Segoe UI',
      ),
      home: TuesdaeRushGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TuesdaeRushGame extends StatefulWidget {
  const TuesdaeRushGame({super.key});

  @override
  TuesdaeRushGameState createState() => TuesdaeRushGameState();
}

class TuesdaeRushGameState extends State<TuesdaeRushGame>
    with TickerProviderStateMixin {

  late AnimationController _gameLoopController;
  late GameState gameState;
  bool isDarkMode = true;
  bool isFullscreen = false;

  @override
  void initState() {
    super.initState();

    gameState = GameState();

    // 60 FPS game loop
    _gameLoopController = AnimationController(
      duration: Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    )..repeat();

    _gameLoopController.addListener(_gameLoop);

    // Initialize game
    gameState.initialize();
  }

  void _gameLoop() {
    if (mounted && !gameState.isPaused && !gameState.isGameOver) {
      setState(() {
        gameState.update();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF031926) : Color(0xFF77ACA2),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: _handleKeyPress,
        child: Stack(
          children: [
            // Game Canvas
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  gameState.updateDimensions(constraints.maxWidth, constraints.maxHeight);
                  return GameCanvas(gameState: gameState);
                },
              ),
            ),

            // UI Overlays
            if (!isFullscreen) _buildHeader(),
            _buildScorePanel(),
            _buildObjectivesPanel(),
            _buildControlsPanel(),
            if (!isFullscreen) _buildInstructions(),
            _buildBottomControls(),

            // Game Over Overlay
            if (gameState.isGameOver) _buildGameOverOverlay(),

            // Pause Overlay
            if (gameState.isPaused) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF77ACA2).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Tuesdae Rush',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF77ACA2).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Just another Tuesdae traffic scene',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePanel() {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${gameState.score}',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Difficulty: ${gameState.currentDifficulty.name}',
              style: TextStyle(color: gameState.getDifficultyColor(), fontSize: 14),
            ),
            Text(
              'Score Multiplier: x${gameState.getDifficultyMultiplier()}',
              style: TextStyle(color: Color(0xFFFFFF96), fontSize: 12),
            ),
            Text(
              'Cars Passed: ${gameState.totalCarsPassed}',
              style: TextStyle(color: Color(0xFFC8FFC8), fontSize: 12),
            ),
            Text(
              'Cars Spawned: ${gameState.totalCarsSpawned}',
              style: TextStyle(color: Color(0xFFC8FFC8), fontSize: 12),
            ),
            Text(
              'Cars Crashed: ${gameState.totalCarsCrashed}',
              style: TextStyle(color: Color(0xFFFF9696), fontSize: 12),
            ),
            Text(
              'Cars Waiting: ${gameState.getWaitingCarsCount()}',
              style: TextStyle(color: Color(0xFFFFC864), fontSize: 12),
            ),
            Text(
              'Success Rate: ${gameState.getSuccessRate()}%',
              style: TextStyle(color: Colors.yellow, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivesPanel() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objectives',
              style: TextStyle(color: Color(0xFFFFC107), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...gameState.objectives.entries.map((entry) {
              bool completed = gameState.objectivesCompleted[entry.key] ?? false;
              return Text(
                '${completed ? "✓" : "•"} ${_getObjectiveText(entry.key, entry.value)}',
                style: TextStyle(
                  color: completed ? Color(0xFF4CAF50) : Colors.grey,
                  fontSize: 12,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getObjectiveText(String key, bool completed) {
    switch (key) {
      case 'pass_20_cars':
        return 'Pass 20 cars ${gameState.totalCarsPassed < 20 ? "(${gameState.totalCarsPassed}/20)" : ""}';
      case 'zero_crashes':
        return 'Perfect safety (10+ cars) ${gameState.totalCarsPassed < 10 ? "(${gameState.totalCarsPassed}/10)" : ""}';
      case 'pass_50_cars':
        return 'Pass 50 cars ${gameState.totalCarsPassed < 50 ? "(${gameState.totalCarsPassed}/50)" : ""}';
      case 'efficiency_85':
        return '85% efficiency (20+ cars) ${gameState.totalCarsPassed < 20 ? "(${gameState.totalCarsPassed}/20)" : "(${gameState.getSuccessRate()}/85)"}';
      case 'pass_100_cars':
        return 'Pass 100 cars ${gameState.totalCarsPassed < 100 ? "(${gameState.totalCarsPassed}/100)" : ""}';
      case 'no_traffic_jams':
        return 'Traffic master (30+ cars) ${gameState.totalCarsPassed < 30 ? "(${gameState.totalCarsPassed}/30)" : ""}';
      default:
        return key;
    }
  }

  Widget _buildControlsPanel() {
    return Positioned(
      bottom: 10,
      left: 10,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: TextStyle(color: Color(0xFFFFC107), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text('Arrow Keys: Traffic Lights', style: TextStyle(color: Colors.white, fontSize: 10)),
            Text('Space bar: Pause/Resume', style: TextStyle(color: Colors.white, fontSize: 10)),
            Text('1-5 Keys: Change Difficulty', style: TextStyle(color: Colors.white, fontSize: 10)),
            Text('R Key: Restart (Game Over)', style: TextStyle(color: Colors.white, fontSize: 10)),
            Text('Tap: Toggle Lights', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Tap traffic lights to control traffic flow • Arrow keys (↑↓←→) to toggle lights | 1/2/3/4/5 to change difficulty | ESC to pause',
            style: TextStyle(color: Colors.white, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: isDarkMode ? '🌙' : '☀️',
            onTap: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
          SizedBox(width: 10),
          _buildControlButton(
            icon: isFullscreen ? '⛷' : '⛶',
            onTap: () {
              setState(() {
                isFullscreen = !isFullscreen;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required String icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Text(
          icon,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Color(0xFF1E3264).withValues(alpha: 0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                gameState.gameOverReason,
                style: TextStyle(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Text(
                'Press R to restart',
                style: TextStyle(color: Color(0xFFFFFF64), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.7),
        child: Center(
          child: Text(
            'PAUSED',
            style: TextStyle(
              color: Colors.black,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Up':
          gameState.toggleTrafficLight(Direction.north);
          break;
        case 'Arrow Down':
          gameState.toggleTrafficLight(Direction.south);
          break;
        case 'Arrow Right':
          gameState.toggleTrafficLight(Direction.east);
          break;
        case 'Arrow Left':
          gameState.toggleTrafficLight(Direction.west);
          break;
        case '1':
          gameState.changeDifficulty(Difficulty.easy);
          break;
        case '2':
          gameState.changeDifficulty(Difficulty.medium);
          break;
        case '3':
          gameState.changeDifficulty(Difficulty.hard);
          break;
        case '4':
          gameState.changeDifficulty(Difficulty.extreme);
          break;
        case '5':
          gameState.changeDifficulty(Difficulty.insane);
          break;
        case 'Space':
        case 'Escape':
          setState(() {
            gameState.togglePause();
          });
          break;
        case 'r':
        case 'R':
          if (gameState.isGameOver) {
            setState(() {
              gameState.restart();
            });
          }
          break;
      }
    }
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    super.dispose();
  }
}

class GameCanvas extends StatelessWidget {
  final GameState gameState;

  const GameCanvas({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main game graphics
        CustomPaint(
          size: Size.infinite,
          painter: GamePainter(gameState),
        ),

        // Touch areas for traffic lights
        ...gameState.getTrafficLightTouchAreas().map((touchArea) {
          return Positioned(
            left: touchArea.bounds.left,
            top: touchArea.bounds.top,
            width: touchArea.bounds.width,
            height: touchArea.bounds.height,
            child: GestureDetector(
              onTap: () => gameState.toggleTrafficLight(touchArea.direction),
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