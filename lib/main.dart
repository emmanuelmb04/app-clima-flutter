import 'package:flutter/material.dart';
import 'package:app_clima/theme/clima_theme.dart';
import 'package:app_clima/screens/clima_screen.dart';
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Clima',
      theme: temaClima,
      home: const PantallaClima(),
    ),
  );
}
