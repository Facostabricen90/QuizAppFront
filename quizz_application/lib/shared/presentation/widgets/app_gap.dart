import 'package:flutter/widgets.dart';

/// Espaciados reutilizables.
///
/// Evita escribir constantemente:
///
/// const SizedBox(height: 16)
/// const SizedBox(width: 24)
///
/// Ejemplo:
///
/// AppGap.h16,
/// AppGap.w8,
///
abstract final class AppGap {
  //==========================
  // Vertical
  //==========================

  static SizedBox get h4 => const SizedBox(height: 4);

  static SizedBox get h8 => const SizedBox(height: 8);

  static SizedBox get h12 => const SizedBox(height: 12);

  static SizedBox get h16 => const SizedBox(height: 16);

  static SizedBox get h20 => const SizedBox(height: 20);

  static SizedBox get h24 => const SizedBox(height: 24);

  static SizedBox get h32 => const SizedBox(height: 32);

  static SizedBox get h40 => const SizedBox(height: 40);

  static SizedBox get h48 => const SizedBox(height: 48);

  static SizedBox get h64 => const SizedBox(height: 64);

  //==========================
  // Horizontal
  //==========================

  static SizedBox get w4 => const SizedBox(width: 4);

  static SizedBox get w8 => const SizedBox(width: 8);

  static SizedBox get w12 => const SizedBox(width: 12);

  static SizedBox get w16 => const SizedBox(width: 16);

  static SizedBox get w20 => const SizedBox(width: 20);

  static SizedBox get w24 => const SizedBox(width: 24);

  static SizedBox get w32 => const SizedBox(width: 32);

  static SizedBox get w40 => const SizedBox(width: 40);

  static SizedBox get w48 => const SizedBox(width: 48);

  static SizedBox get w64 => const SizedBox(width: 64);
}
