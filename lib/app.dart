import 'package:flutter/material.dart';

import 'core/navigation/app_router.dart';

class TuesdaeRushApp extends StatelessWidget {
  const TuesdaeRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tuesdae Rush - Traffic Control Game',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Segoe UI'),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
