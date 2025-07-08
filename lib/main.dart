import 'package:flutter/material.dart';
import 'package:tuesdae_rush/initialize.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(TuesdaeRushApp());
}
