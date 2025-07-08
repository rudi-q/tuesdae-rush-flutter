import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuesdae_rush/app.dart';
import 'package:tuesdae_rush/feature/gameplay/presentation/game.dart';
import 'package:tuesdae_rush/feature/gameplay/presentation/game_canvas.dart';

void main() {
  group('Main Widget Tests', () {
    testWidgets('should build TuesdaeRushApp correctly', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(TuesdaeRushGame), findsOneWidget);
    });

    testWidgets('should display start screen initially', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Look for start screen elements
      expect(find.text('Press ESC or tap to start!'), findsOneWidget);
      expect(find.text('🎮 Arrow Keys: Traffic Lights • 1-5: Difficulty'), findsOneWidget);
    });

    testWidgets('should start game when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Tap to start game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Start screen should be gone, game UI should be visible
      expect(find.text('Press ESC or tap to start!'), findsNothing);
      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.text('Controls'), findsOneWidget);
    });

    testWidgets('should display game UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Check for game UI elements
      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.text('Objectives'), findsOneWidget);
      expect(find.text('Controls'), findsOneWidget);
      expect(find.text('Tuesdae Rush'), findsOneWidget);
    });

    testWidgets('should display traffic light touch areas', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Should have 4 touch areas for traffic lights
      expect(find.byType(GestureDetector), findsWidgets);
      
      // Find the GameCanvas which contains traffic light touch areas
      expect(find.byType(GameCanvas), findsOneWidget);
    });

    testWidgets('should handle keyboard input', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Simulate arrow key press
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      
      // Game should still be running (no errors)
      expect(find.text('Score: 0'), findsOneWidget);
    });

    testWidgets('should pause game with space key', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Press space to pause
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      
      // Game should handle the space key (test passes if no error)
      expect(find.text('Score: 0'), findsOneWidget);
    });

    testWidgets('should toggle fullscreen mode', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Find and tap fullscreen button (⛶)
      await tester.tap(find.text('⛶'));
      await tester.pump();
      
      // Header should be hidden in fullscreen mode
      expect(find.text('Tuesdae Rush'), findsNothing);
      
      // Tap again to exit fullscreen (⛷)
      await tester.tap(find.text('⛷'));
      await tester.pump();
      
      // Header should be visible again
      expect(find.text('Tuesdae Rush'), findsOneWidget);
    });

    testWidgets('should toggle dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Find and tap dark mode button (🌙)
      await tester.tap(find.text('🌙'));
      await tester.pump();
      
      // Should change to light mode button (☀️)
      expect(find.text('☀️'), findsOneWidget);
      
      // Tap again to go back to dark mode
      await tester.tap(find.text('☀️'));
      await tester.pump();
      
      // Should be back to dark mode button (🌙)
      expect(find.text('🌙'), findsOneWidget);
    });

    testWidgets('should toggle sound', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Find and tap sound button (🔊)
      await tester.tap(find.text('🔊'));
      await tester.pump();
      
      // Should change to muted button (🔇)
      expect(find.text('🔇'), findsOneWidget);
      
      // Tap again to unmute
      await tester.tap(find.text('🔇'));
      await tester.pump();
      
      // Should be back to sound on button (🔊)
      expect(find.text('🔊'), findsOneWidget);
    });

    testWidgets('should display objectives panel', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Check for objectives
      expect(find.text('Objectives'), findsOneWidget);
      expect(find.textContaining('Pass 20 cars'), findsOneWidget);
      expect(find.textContaining('Perfect safety'), findsOneWidget);
    });

    testWidgets('should display score panel', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Check for score panel elements
      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.textContaining('Difficulty:'), findsOneWidget);
      expect(find.textContaining('Cars Passed:'), findsOneWidget);
      expect(find.textContaining('Cars Spawned:'), findsOneWidget);
      expect(find.textContaining('Cars Crashed:'), findsOneWidget);
      expect(find.textContaining('Success Rate:'), findsOneWidget);
    });

    testWidgets('should display controls panel', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Check for controls panel elements
      expect(find.text('Controls'), findsOneWidget);
      expect(find.text('Arrow Keys: Traffic Lights'), findsOneWidget);
      expect(find.text('Space bar: Pause/Resume'), findsOneWidget);
      expect(find.text('1-5 Keys: Change Difficulty'), findsOneWidget);
      expect(find.text('Tap: Toggle Lights'), findsOneWidget);
    });

    testWidgets('should change difficulty with number keys', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Default should be medium
      expect(find.text('Difficulty: medium'), findsOneWidget);
      
      // Press 1 for easy
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      
      expect(find.text('Difficulty: easy'), findsOneWidget);
      
      // Press 3 for hard
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump();
      
      expect(find.text('Difficulty: hard'), findsOneWidget);
    });

    testWidgets('should handle screen size changes', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Change screen size
      await tester.binding.setSurfaceSize(Size(1200, 800));
      await tester.pump();
      
      // Game should still be rendered correctly
      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.byType(GameCanvas), findsOneWidget);
      
      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should build game screen without errors', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Game should be built successfully
      expect(find.byType(GameCanvas), findsOneWidget);
      expect(find.text('Score: 0'), findsOneWidget);
    });

    testWidgets('should handle R key input', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // Press R key
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      
      // Game should handle the R key (test passes if no error)
      expect(find.text('Score: 0'), findsOneWidget);
    });

    testWidgets('should handle layout builder correctly', (WidgetTester tester) async {
      await tester.pumpWidget(TuesdaeRushApp());
      
      // Should have LayoutBuilder for responsive canvas
      expect(find.byType(LayoutBuilder), findsOneWidget);
      
      // Start the game
      await tester.tap(find.byType(TuesdaeRushGame));
      await tester.pump();
      
      // LayoutBuilder should still be present
      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(find.byType(GameCanvas), findsOneWidget);
    });
  });
}
