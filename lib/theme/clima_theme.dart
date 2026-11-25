import 'package:flutter/material.dart';

final temaClima = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF245BB5),
  ),
  scaffoldBackgroundColor: const Color(0xFFF2F7FF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF2F7FF),
    foregroundColor: Color(0xFF16335E),
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB4C8E6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF245BB5), width: 2),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF245BB5),
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
);
