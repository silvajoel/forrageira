import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,

  fontFamily: 'Roboto',
  scaffoldBackgroundColor: AppColors.greenLight,

  colorScheme: const ColorScheme.light(
    primary: AppColors.green,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    surface: AppColors.cardBg,
    onSurface: AppColors.textPrimary,
  ),

  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: AppColors.green,
    foregroundColor: Colors.white,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.green,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.greenDark,
    foregroundColor: Colors.white,
  ),
);