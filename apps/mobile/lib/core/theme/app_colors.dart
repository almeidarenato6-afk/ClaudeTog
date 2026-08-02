import 'package:flutter/material.dart';

/// PLACEHOLDER BRAND PALETTE — no official TogPlay brand guideline file
/// exists yet. This is a vibrant, sporty palette (energetic orange/coral
/// primary evoking beach-tennis courts and sunshine, deep navy secondary
/// evoking the beach at dusk / premium sport-tech) chosen to read well as
/// big tap targets against both light and dark backgrounds. Replace with
/// the real TogPlay brand kit as soon as one is provided — search the
/// codebase for `TOGPLAY_BRAND_PLACEHOLDER` to find every reference.
abstract final class AppColors {
  // TOGPLAY_BRAND_PLACEHOLDER — coral/orange, "quadra ao pôr do sol"
  static const Color coralPrimary = Color(0xFFFF6B4A);
  static const Color coralPrimaryDark = Color(0xFFE85A3A);
  static const Color coralPrimaryLight = Color(0xFFFF8F73);

  // TOGPLAY_BRAND_PLACEHOLDER — deep navy, "areia à noite"
  static const Color navySecondary = Color(0xFF152642);
  static const Color navySecondaryLight = Color(0xFF24406B);
  static const Color navySecondaryDark = Color(0xFF0B1526);

  // TOGPLAY_BRAND_PLACEHOLDER — supporting accents
  static const Color sunYellow = Color(0xFFFFC93C);
  static const Color sandBeige = Color(0xFFF5E6D3);
  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFE74C3C);
  static const Color neutralGrey = Color(0xFF8E97A8);

  static const Color lightSurface = Color(0xFFFFFBF8);
  static const Color darkSurface = Color(0xFF10151F);
}
