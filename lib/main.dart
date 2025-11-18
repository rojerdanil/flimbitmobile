import 'package:flutter/material.dart';
import 'package:flimbit_mobile/theme/AppTheme.dart';
import 'package:flimbit_mobile/securityScreen/splash_screen.dart';

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
      //  home: HomeScreen(),
      home: SplashScreen(),
    );
  }
}
