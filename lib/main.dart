import 'package:flimbit_mobile/screens/home-screen.dart';
import 'package:flutter/material.dart';
import 'package:flimbit_mobile/theme/AppTheme.dart';

void main() {
  runApp(const FlimBitApp());
}

class FlimBitApp extends StatelessWidget {
  const FlimBitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FilmBitx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: HomeScreen(),
    );
  }
}
