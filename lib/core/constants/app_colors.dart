import 'package:flutter/material.dart';

/// Paleta do app. A ideia central: verde-jade representa o estado de
/// "jejum" (frio, calmo, disciplinado); âmbar representa "alimentação"
/// (quente, energia). Esse contraste frio/quente é usado de propósito no
/// timer e nos indicadores de status, em vez de ser só decoração.
class AppColors {
  // Estado "jejum"
  static const primary = Color(0xFF2E7D6B);
  static const primaryDark = Color(0xFF1B4D42);
  static const primaryLight = Color(0xFFCFE6DF);

  // Estado "alimentação" / energia
  static const accent = Color(0xFFF2A65A);
  static const accentDark = Color(0xFFB9752A);

  // Superfícies
  static const backgroundLight = Color(0xFFFAF8F4);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const backgroundDark = Color(0xFF14181A);
  static const surfaceDark = Color(0xFF1E2426);

  // Texto — definidos explicitamente pra nunca depender do contraste
  // padrão do Material (foi o que causou o bug de legibilidade no login).
  static const textPrimaryLight = Color(0xFF1F2B29);
  static const textSecondaryLight = Color(0xFF5C6B68);
  static const textPrimaryDark = Color(0xFFF2F5F4);
  static const textSecondaryDark = Color(0xFFAAB8B5);

  // Semânticas
  static const danger = Color(0xFFC0554D);
  static const success = Color(0xFF4CAF50);
}
