import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import 'core/services/analytics_service.dart';
import 'feature/gameplay/presentation/game.dart';

class TuesdaeRushApp extends StatelessWidget {
  const TuesdaeRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get analytics instance safely
    final analytics = AnalyticsService.analytics;

    return MaterialApp(
      title: 'Tuesdae Rush - Traffic Control Game',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Segoe UI',
      ),
      home: TuesdaeRushGame(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: analytics != null ? [
        FirebaseAnalyticsObserver(analytics: analytics),
      ] : [],
    );
  }
}