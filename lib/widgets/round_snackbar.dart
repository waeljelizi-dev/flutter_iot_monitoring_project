import 'package:flutter/material.dart';

class RoundSnackBar {
  static const int LENGTH_LONG = 3;
  static const int LENGTH_SHORT = 1;

  static void show(BuildContext context, String message,
      {Color color = Colors.black, int duration = LENGTH_SHORT}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      backgroundColor: color.withOpacity(0.9),
      duration: Duration(seconds: duration),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
