import 'package:flutter/material.dart';

import 'colors.dart';

Color accent = Colors.white;
Color primary = greedyBackground;

final Map<int, Color> color = {
  50:  greedyBackground,
  100: greedyBackground,
  200: greedyBackground,
  300: greedyBackground,
  400: greedyBackground,
  500: greedyBackground,
  600: greedyBackground,
  700: greedyBackground,
  800: greedyBackground,
  900: greedyBackground,
};

MaterialColor colorCustom = MaterialColor(0xFF000f26, color);

ThemeData greedyTheme = ThemeData(
    colorScheme: ColorScheme.fromSwatch(primarySwatch: colorCustom).copyWith(
      secondary: accent,
      primary: primary,
    ),
    // fontFamily: "Montserrat",
    scaffoldBackgroundColor: primary);
