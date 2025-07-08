import 'package:flutter/material.dart';

Widget buildInstructions() {
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
