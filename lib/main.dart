import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_manager.dart';
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
      title: 'Tuesdae Rush - Traffic Control Game',
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
  late AudioManager audioManager;
  bool isFullscreen = false;
  bool showInstructions = true;
  List<String> recentObjectives = [];

  @override
  void initState() {
    super.initState();

    gameState = GameState();
    audioManager = AudioManager();

    // 60 FPS game loop
    _gameLoopController = AnimationController(
      duration: Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    )..repeat();

    _gameLoopController.addListener(_gameLoop);

    // Initialize game and audio
    gameState.initialize();
    audioManager.initialize();
  }

  void _gameLoop() {
    if (mounted && !gameState.isPaused && !gameState.isGameOver && gameState.gameStarted) {
      setState(() {
        gameState.update();
        _checkForNewObjectives();
      });
    }
  }

  void _checkForNewObjectives() {
    // Check for newly completed objectives and add to recent list
    gameState.objectives.entries.forEach((entry) {
      if (entry.value && gameState.objectivesCompleted[entry.key] == true) {
        String objectiveName = _getObjectiveText(entry.key, entry.value).split(' (')[0]; // Remove progress text
        if (!recentObjectives.contains(objectiveName)) {
          recentObjectives.add(objectiveName);
          // Remove after 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                recentObjectives.remove(objectiveName);
              });
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF031926),
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: _handleKeyPress,
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
            // Hide objectives panel on mobile devices
            if (!_isMobile(context)) _buildObjectivesPanel(),
            // Hide controls panel on mobile devices
            if (!_isMobile(context)) _buildControlsPanel(),
            if (showInstructions) _buildInstructions(),
            _buildBottomControls(),
            
            // Mobile help button (bottom left)
            if (_isMobile(context)) _buildMobileHelpButton(),
            
            // Mobile objective notifications
            if (_isMobile(context)) _buildMobileObjectiveNotifications(),

            // Game Over Overlay
            if (gameState.isGameOver) _buildGameOverOverlay(),

            // Pause Overlay
            if (gameState.isPaused) _buildPauseOverlay(),

            // Start Screen Overlay
            if (!gameState.gameStarted) _buildStartScreen(),
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
            Text('S Key: Toggle Audio', style: TextStyle(color: Colors.white, fontSize: 10)),
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
            'Control traffic lights to prevent crashes and traffic jams',
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
          // Only show help button on desktop (not mobile)
          if (!_isMobile(context)) ...[
            _buildControlButton(
              icon: '❓',
              onTap: () {
                setState(() {
                  showInstructions = !showInstructions;
                });
              },
            ),
            SizedBox(width: 10),
          ],
          _buildControlButton(
            icon: isFullscreen ? '⛷' : '⛶',
            onTap: () {
              setState(() {
                isFullscreen = !isFullscreen;
              });
            },
          ),
          SizedBox(width: 10),
          _buildControlButton(
            icon: audioManager.soundEnabled ? '🔊' : '🔇',
            onTap: () {
              setState(() {
                audioManager.setSoundEnabled(!audioManager.soundEnabled);
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
                'Score: ${gameState.score}',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
              SizedBox(height: 10),
              Text(
                gameState.gameOverReason,
                style: TextStyle(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              // Mobile-friendly restart button
              GestureDetector(
                onTap: () {
                  setState(() {
                    gameState.restart();
                    recentObjectives.clear(); // Clear mobile notifications on restart
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'RESTART',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Tap button above or press R to restart',
                style: TextStyle(color: Color(0xFFFFFF64), fontSize: 14),
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

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          gameState.toggleTrafficLight(Direction.north);
          audioManager.playTrafficLightSwitch();
          break;
        case LogicalKeyboardKey.arrowDown:
          gameState.toggleTrafficLight(Direction.south);
          audioManager.playTrafficLightSwitch();
          break;
        case LogicalKeyboardKey.arrowRight:
          gameState.toggleTrafficLight(Direction.east);
          audioManager.playTrafficLightSwitch();
          break;
        case LogicalKeyboardKey.arrowLeft:
          gameState.toggleTrafficLight(Direction.west);
          audioManager.playTrafficLightSwitch();
          break;
        case LogicalKeyboardKey.digit1:
          gameState.changeDifficulty(Difficulty.easy);
          break;
        case LogicalKeyboardKey.digit2:
          gameState.changeDifficulty(Difficulty.medium);
          break;
        case LogicalKeyboardKey.digit3:
          gameState.changeDifficulty(Difficulty.hard);
          break;
        case LogicalKeyboardKey.digit4:
          gameState.changeDifficulty(Difficulty.extreme);
          break;
        case LogicalKeyboardKey.digit5:
          gameState.changeDifficulty(Difficulty.insane);
          break;
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.escape:
          if (!gameState.gameStarted) {
            setState(() {
              gameState.startGame();
            });
          } else {
            setState(() {
              gameState.togglePause();
            });
          }
          break;
        case LogicalKeyboardKey.keyR:
          if (gameState.isGameOver) {
            setState(() {
              gameState.restart();
              recentObjectives.clear(); // Clear mobile notifications on restart
            });
          }
          break;
        case LogicalKeyboardKey.keyS:
          setState(() {
            audioManager.setSoundEnabled(!audioManager.soundEnabled);
          });
          break;
      }
    }
  }

  Widget _buildStartScreen() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          gameState.startGame();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF031926).withValues(alpha: 0.9),
                Color(0xFF1E3264).withValues(alpha: 0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                // Game Cover Image
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65, // Max 65% of screen height
                    maxWidth: MediaQuery.of(context).size.width * 0.9,    // Max 90% of screen width
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/tuesdae_rush_cover.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to text title if image fails to load
                        return Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.65,
                            maxWidth: MediaQuery.of(context).size.width * 0.9,
                          ),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFF77ACA2).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tuesdae Rush',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      blurRadius: 5,
                                      color: Colors.black.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Just another Tuesdae traffic scene',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Compact Instructions Section (max 20% screen height)
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.2, // Max 20% of screen height
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Start Instructions
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Press ESC or tap to start!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Quick controls hint
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF77ACA2).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🎮 Arrow Keys: Traffic Lights • 1-5: Difficulty',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Control traffic flow • Prevent crashes and jams!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to detect mobile devices
  bool _isMobile(BuildContext context) {
    // Use screen width to detect mobile devices
    // This works well for both native mobile and mobile browsers
    return MediaQuery.of(context).size.width < 600;
  }

  Widget _buildMobileHelpButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: _buildControlButton(
        icon: '❓',
        onTap: () {
          setState(() {
            showInstructions = !showInstructions;
          });
        },
      ),
         );
   }

  Widget _buildMobileObjectiveNotifications() {
    if (recentObjectives.isEmpty) {
      return Container();
    }

    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: Column(
        children: recentObjectives.map((objective) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD700).withOpacity(0.9),
                  Color(0xFFFFC107).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Achievement icon
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '🏆',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(width: 12),
                // Achievement text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        objective,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    audioManager.dispose();
    super.dispose();
  }
}

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
