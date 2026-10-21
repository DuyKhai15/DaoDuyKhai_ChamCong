import 'package:flutter/material.dart';

const kPurple = Color(0xFF6A1B9A);
const kPurpleDark = Color(0xFF4A148C);
const kPurpleLight = Color(0xFFF3E5F5);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: kPurple),
  scaffoldBackgroundColor: const Color(0xFFF7F2FB),
  appBarTheme: const AppBarTheme(backgroundColor: kPurple, foregroundColor: Colors.white, centerTitle: true),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPurple,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: kPurple, foregroundColor: Colors.white),
);

const kGradient = LinearGradient(colors: [kPurpleDark, kPurple, Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight);
