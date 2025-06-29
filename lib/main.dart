import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_manager.dart';
import 'game_painter.dart';
import 'game_state.dart';
import 'mobile_manager.dart';
import 'responsive_layout.dart';

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
  late MobileManager mobileManager;
  late FocusNode _focusNode;
  bool isDarkMode = true;
  bool isFullscreen = false;
  bool showInstructions = true;
  List<String> recentObjectives = [];

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    gameState = GameState();
    audioManager = AudioManager();
    mobileManager = MobileManager();

    // 60 FPS game loop
    _gameLoopController = AnimationController(
      duration: Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    )..repeat();

    _gameLoopController.addListener(_gameLoop);

    // Initialize game, audio, and mobile features
    gameState.initialize();
    audioManager.initialize();
    mobileManager.initialize();
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
      backgroundColor: isDarkMode ? Color(0xFF031926) : Color(0xFF77ACA2),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          return _handleKeyEvent(event);
        },
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
    final responsive = ResponsiveLayout.instance;
    final layout = responsive.getUILayout(context);
    final size = MediaQuery.of(context).size;
    final topMargin = size.height * 0.02;
    final padding = responsive.getPadding(context, type: 'panel');
    
    if (!layout['headerVisible']) {
      return SizedBox.shrink();
    }
    
    return Positioned(
      top: topMargin,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Color(0xFF77ACA2).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Tuesdae Rush',
              style: responsive.getTextStyle(context, 'header', fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: responsive.getSpacing(context, type: 'small')),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding.horizontal * 0.8, 
              vertical: padding.vertical * 0.4
            ),
            decoration: BoxDecoration(
              color: Color(0xFF77ACA2).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Just another Tuesdae traffic scene',
              style: responsive.getTextStyle(context, 'subtitle').copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePanel() {
    final responsive = ResponsiveLayout.instance;
    final layout = responsive.getUILayout(context);
    final deviceType = responsive.getDeviceType(context);
    final padding = responsive.getPadding(context, type: 'panel');
    final opacity = responsive.getPanelOpacity(context);
    final showCompact = layout['showCompactUI'] ?? false;
    
    return Positioned(
      top: layout['scorePosition']['top'],
      left: layout['scorePosition']['left'],
      child: Container(
        constraints: BoxConstraints(
          maxWidth: layout['panelMaxWidth'],
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showCompact) ...[
              Text('Score: ${gameState.score}', style: responsive.getTextStyle(context, 'score', fontWeight: FontWeight.bold)),
              Text('Difficulty: ${gameState.currentDifficulty.name}', style: responsive.getTextStyle(context, 'body', color: gameState.getDifficultyColor())),
              Text('Multiplier: x${gameState.getDifficultyMultiplier()}', style: responsive.getTextStyle(context, 'caption', color: Color(0xFFFFFF96))),
              Text('Cars: ${gameState.totalCarsPassed}/${gameState.totalCarsSpawned}', style: responsive.getTextStyle(context, 'caption', color: Color(0xFFC8FFC8))),
              Text('Crashed: ${gameState.totalCarsCrashed}', style: responsive.getTextStyle(context, 'caption', color: Color(0xFFFF9696))),
              Text('Waiting: ${gameState.getWaitingCarsCount()}', style: responsive.getTextStyle(context, 'caption', color: Color(0xFFFFC864))),
              Text('Success: ${gameState.getSuccessRate()}%', style: responsive.getTextStyle(context, 'caption', color: Colors.yellow)),
            ],
            if (showCompact || deviceType == DeviceType.phone) ...[
              Text('Score: ${gameState.score}', style: responsive.getTextStyle(context, 'score', fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivesPanel() {
    final responsive = ResponsiveLayout.instance;
    final layout = responsive.getUILayout(context);
    final padding = responsive.getPadding(context, type: 'panel');
    final opacity = responsive.getPanelOpacity(context);
    final showCompact = layout['showCompactUI'] ?? false;
    final deviceType = responsive.getDeviceType(context);
    
    return Positioned(
      top: layout['objectivesPosition']['top'],
      right: layout['objectivesPosition'].containsKey('right') ? layout['objectivesPosition']['right'] : null,
      left: layout['objectivesPosition'].containsKey('left') ? layout['objectivesPosition']['left'] : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: layout['panelMaxWidth'],
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showCompact) ...[
              Text(
                'Objectives',
                style: responsive.getTextStyle(context, 'subtitle', color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
              ),
              SizedBox(height: responsive.getSpacing(context, type: 'small')),
              ...gameState.objectives.entries.take(6).map((entry) {
                bool completed = gameState.objectivesCompleted[entry.key] ?? false;
                return Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${completed ? "✓" : "•"} ${_getObjectiveText(entry.key, entry.value, showCompact)}',
                    style: responsive.getTextStyle(
                      context, 
                      'caption', 
                      color: completed ? Color(0xFF4CAF50) : Colors.grey
                    ),
                    maxLines: showCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            if (showCompact || deviceType == DeviceType.phone) ...[
              Text(
                'Objectives',
                style: responsive.getTextStyle(context, 'subtitle', color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
              ),
              SizedBox(height: responsive.getSpacing(context, type: 'small')),
            ]
          ],
        ),
      ),
    );
  }

  String _getObjectiveText(String key, bool completed, [bool compact = false]) {
    switch (key) {
      case 'pass_20_cars':
        return compact ? 'Pass 20 cars' : 'Pass 20 cars ${gameState.totalCarsPassed < 20 ? "(${gameState.totalCarsPassed}/20)" : ""}';
      case 'zero_crashes':
        return compact ? 'Perfect safety' : 'Perfect safety (10+ cars) ${gameState.totalCarsPassed < 10 ? "(${gameState.totalCarsPassed}/10)" : ""}';
      case 'pass_50_cars':
        return compact ? 'Pass 50 cars' : 'Pass 50 cars ${gameState.totalCarsPassed < 50 ? "(${gameState.totalCarsPassed}/50)" : ""}';
      case 'efficiency_85':
        return compact ? '85% efficiency' : '85% efficiency (20+ cars) ${gameState.totalCarsPassed < 20 ? "(${gameState.totalCarsPassed}/20)" : "(${gameState.getSuccessRate()}/85)"}';
      case 'pass_100_cars':
        return compact ? 'Pass 100 cars' : 'Pass 100 cars ${gameState.totalCarsPassed < 100 ? "(${gameState.totalCarsPassed}/100)" : ""}';
      case 'no_traffic_jams':
        return compact ? 'Traffic master' : 'Traffic master (30+ cars) ${gameState.totalCarsPassed < 30 ? "(${gameState.totalCarsPassed}/30)" : ""}';
      default:
        return key;
    }
  }

  Widget _buildControlsPanel() {
    final responsive = ResponsiveLayout.instance;
    final layout = responsive.getUILayout(context);
    final padding = responsive.getPadding(context, type: 'panel');
    final opacity = responsive.getPanelOpacity(context);
    final showCompact = layout['showCompactUI'] ?? false;
    
    if (!layout['instructionsVisible']) {
      return SizedBox.shrink(); // Hide on very small screens
    }
    
    return Positioned(
      bottom: layout['controlsPosition']['bottom'],
      left: layout['controlsPosition']['left'],
      child: Container(
        constraints: BoxConstraints(
          maxWidth: layout['panelMaxWidth'],
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: responsive.getTextStyle(context, 'subtitle', color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
            ),
            if (!showCompact) Text('Arrow Keys: Traffic Lights', style: responsive.getTextStyle(context, 'caption')),
            if (!showCompact) Text('Space bar: Pause/Resume', style: responsive.getTextStyle(context, 'caption')),
            if (!showCompact) Text('1-5 Keys: Change Difficulty', style: responsive.getTextStyle(context, 'caption')),
            Text('Tap: Toggle Lights', style: responsive.getTextStyle(context, 'caption')),
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
    final responsive = ResponsiveLayout.instance;
    final layout = responsive.getUILayout(context);
    final size = MediaQuery.of(context).size;
    final sideMargin = size.width * 0.02;
    
    return Positioned(
      bottom: layout['bottomControlsPosition']['bottom'],
      right: sideMargin,
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
            SizedBox(width: 8),
          ],
          _buildControlButton(
            icon: isFullscreen ? '⛷' : '⛶',
            onTap: () {
              setState(() {
                isFullscreen = !isFullscreen;
              });
              mobileManager.selectionHaptic();
            },
          ),
          SizedBox(width: 8),
          _buildControlButton(
            icon: isDarkMode ? '🌙' : '☀️',
            onTap: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
              mobileManager.selectionHaptic();
            },
          ),
          SizedBox(width: 8),
          _buildControlButton(
            icon: audioManager.soundEnabled ? '🔊' : '🔇',
            onTap: () {
              setState(() {
                audioManager.setSoundEnabled(!audioManager.soundEnabled);
              });
              mobileManager.selectionHaptic();
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
    final responsive = ResponsiveLayout.instance;
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: gameState.isGameOver ? () {
          setState(() {
            gameState.restart();
            recentObjectives.clear(); // Clear mobile notifications on restart
          });
        } : null,
        child: Container(
          color: Color(0xFF1E3264).withValues(alpha: 0.8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GAME OVER',
                  style: responsive.getTextStyle(context, 'gameOver', color: Colors.red, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: responsive.getSpacing(context, type: 'medium')),
                Text(
                  gameState.gameOverReason,
                  style: responsive.getTextStyle(context, 'title'),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.getSpacing(context, type: 'large')),
                Text(
                  'Press R or tap screen to restart',
                  style: responsive.getTextStyle(context, 'body', color: Color(0xFFFFFF64)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    final responsive = ResponsiveLayout.instance;
    
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.7),
        child: Center(
          child: Text(
            'PAUSED',
            style: responsive.getTextStyle(context, 'pause', color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      
      if (key == LogicalKeyboardKey.arrowUp) {
        setState(() {
          gameState.toggleTrafficLight(Direction.north);
          audioManager.playTrafficLightSwitch();
          mobileManager.lightHaptic();
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowDown) {
        setState(() {
          gameState.toggleTrafficLight(Direction.south);
          audioManager.playTrafficLightSwitch();
          mobileManager.lightHaptic();
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowRight) {
        setState(() {
          gameState.toggleTrafficLight(Direction.east);
          audioManager.playTrafficLightSwitch();
          mobileManager.lightHaptic();
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          gameState.toggleTrafficLight(Direction.west);
          audioManager.playTrafficLightSwitch();
          mobileManager.lightHaptic();
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit1) {
        setState(() {
          gameState.changeDifficulty(Difficulty.easy);
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit2) {
        setState(() {
          gameState.changeDifficulty(Difficulty.medium);
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit3) {
        setState(() {
          gameState.changeDifficulty(Difficulty.hard);
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit4) {
        setState(() {
          gameState.changeDifficulty(Difficulty.extreme);
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit5) {
        setState(() {
          gameState.changeDifficulty(Difficulty.insane);
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.escape) {
        if (!gameState.gameStarted) {
          setState(() {
            gameState.startGame();
          });
        } else {
          setState(() {
            gameState.togglePause();
          });
        }
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyR) {
        if (gameState.isGameOver) {
          setState(() {
            gameState.restart();
            recentObjectives.clear(); // Clear mobile notifications on restart
          });
        }
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyS) {
        setState(() {
          audioManager.setSoundEnabled(!audioManager.soundEnabled);
        });
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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

  @override
  void dispose() {
    _gameLoopController.dispose();
    _focusNode.dispose();
    audioManager.dispose();
    super.dispose();
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
                MobileManager().lightHaptic();
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
