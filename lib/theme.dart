import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KColors {
  static const violet = Color(0xFF6A1B9A);
  static const rose = Color(0xFFD81B8A);
  static const orange = Color(0xFFF59E0B);
  static const vert = Color(0xFF2E9E5B);
  static const bleu = Color(0xFF2F7DE1);
  static const fond = Color(0xFFFBF6FB);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: KColors.violet,
    primary: KColors.violet,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: KColors.fond,
    appBarTheme: const AppBarTheme(
      backgroundColor: KColors.fond,
      foregroundColor: KColors.violet,
      elevation: 0,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.purple.shade100),
      ),
    ),
  );
}

String fcfa(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}$b FCFA';
}

String dateFr(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
