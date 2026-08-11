import 'package:flutter/material.dart';

/// PALETA DE MARCA PLACEHOLDER — ainda não existe um arquivo oficial de
/// diretrizes de marca da TogPlay. Esta é uma paleta vibrante e esportiva
/// (laranja/coral primário energético evocando quadras de beach tennis e
/// sol, azul-marinho profundo secundário evocando a praia ao entardecer /
/// sport-tech premium) escolhida para funcionar bem como grandes áreas de
/// toque contra fundos claros e escuros. Substitua pelo kit de marca real
/// da TogPlay assim que um for fornecido — busque no código por
/// `TOGPLAY_BRAND_PLACEHOLDER` para encontrar todas as referências.
abstract final class AppColors {
  // TOGPLAY_BRAND_PLACEHOLDER — coral/laranja, "quadra ao pôr do sol"
  static const Color coralPrimary = Color(0xFFFF6B4A);
  static const Color coralPrimaryDark = Color(0xFFE85A3A);
  static const Color coralPrimaryLight = Color(0xFFFF8F73);

  // TOGPLAY_BRAND_PLACEHOLDER — azul-marinho profundo, "areia à noite"
  static const Color navySecondary = Color(0xFF152642);
  static const Color navySecondaryLight = Color(0xFF24406B);
  static const Color navySecondaryDark = Color(0xFF0B1526);

  // TOGPLAY_BRAND_PLACEHOLDER — cores de apoio
  static const Color sunYellow = Color(0xFFFFC93C);
  static const Color sandBeige = Color(0xFFF5E6D3);
  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFE74C3C);
  static const Color neutralGrey = Color(0xFF8E97A8);

  static const Color lightSurface = Color(0xFFFFFBF8);
  static const Color darkSurface = Color(0xFF10151F);
}
