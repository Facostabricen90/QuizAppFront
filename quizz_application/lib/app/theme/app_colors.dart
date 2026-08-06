import 'package:flutter/material.dart';

/// Centraliza todos los colores utilizados por la aplicación.
///
/// No utilizar colores directamente dentro de los Widgets.
abstract final class AppColors {
  AppColors._();

  //==========================
  // Brand
  //==========================

  static const Color primary = Color(0xFF245B43);
  static const Color primaryLight = Color(0xFF3F7B5B);

  static const Color accent = Color(0xFFD8E58A);

  //==========================
  // Backgrounds
  //==========================

  static const Color background = Color(0xFFF7F9F4);

  static const Color surface = Colors.white;

  static const Color surfaceSecondary = Color(0xFFE8F0E8);

  //==========================
  // Text
  //==========================

  static const Color textPrimary = Color(0xFF14221B);

  static const Color textSecondary = Color(0xFF405247);

  static const Color textHint = Color(0xFF7A8A81);

  //==========================
  // States
  //==========================

  static const Color success = Color(0xFF5FA66B);

  static const Color warning = Color(0xFFC99446);

  static const Color error = Color(0xFFD9534F);

  static const Color info = Color(0xFFDCE9EE);

  //==========================
  // Others
  //==========================

  static const Color border = Color(0xFFE1E8E2);

  static const Color divider = Color(0xFFE8ECE8);

  static const Color disabled = Color(0xFFC5CEC8);
}
