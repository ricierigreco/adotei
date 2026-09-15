import 'package:flutter/material.dart';

class AppColors {
  // Paleta de Cores Curada (Coral / Warm Theme)
  static const Color primary = Color(0xFFFF6F59); // Coral quente e amigável
  static const Color primaryDark = Color(0xFFE0523C); // Coral escuro
  static const Color secondary = Color(0xFF254B5C); // Azul petróleo elegante
  static const Color accent = Color(
    0xFFFFB236,
  ); // Dourado/Amarelo quente para destaques

  // Tons Neutros
  static const Color backgroundLight = Color(
    0xFFF8FAFC,
  ); // Cinza azulado muito claro (premium)
  static const Color backgroundDark = Color(
    0xFF0F172A,
  ); // Slate Dark para Modo Escuro
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);

  // Texto
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textLight = Color(0xFFF1F5F9); // Slate 100
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Status de Anúncio
  static const Color statusDisponivel = Color(0xFF10B981); // Verde esmeralda
  static const Color statusProcesso = Color(0xFFF59E0B); // Âmbar
  static const Color statusAdotado = Color(0xFF64748B); // Cinza

  // Gradientes Modernos
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF8A75), Color(0xFFFF5238)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF254B5C), Color(0xFF1A3542)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sombras Modernas (Soft Shadows)
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> primaryButtonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
