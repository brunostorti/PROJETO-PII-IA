import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Nova paleta moderna baseada em #001489
  static const Color primaryColor = Color(0xFF001489); // Azul escuro moderno
  static const Color primaryLight = Color(0xFF3D5CFF); // Azul mais claro
  static const Color primaryDark = Color(0xFF000761); // Azul ainda mais escuro

  // Cores secundárias modernas
  static const Color secondaryColor = Color(0xFF00D4AA); // Verde menta moderno
  static const Color accentColor = Color(0xFFFF6B9D); // Rosa moderno

  // Gradientes modernos
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFE3F2FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cores de fundo modernas
  static const Color backgroundColor = Color(0xFFFAFBFF); // Fundo com tom azulado
  static const Color surfaceColor = Color(0xFFF8FAFF); // Superfície glassmorphism
  static const Color cardColor = Colors.white;

  // Cores de texto modernas
  static const Color textPrimaryColor = Color(0xFF0D1B2A); // Quase preto
  static const Color textSecondaryColor = Color(0xFF415A77); // Cinza azulado
  static const Color textLightColor = Color(0xFF8B949E); // Cinza claro

  // Cores de estado modernas
  static const Color successColor = Color(0xFF00C853); // Verde sucesso
  static const Color warningColor = Color(0xFFFFB74D); // Amarelo moderno
  static const Color errorColor = Color(0xFFFF5252); // Vermelho moderno

  // Sombras modernas (glassmorphism) - definidas como funções para evitar constantes
  static List<BoxShadow> get cardShadow {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: primaryColor.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ];
  }

  static List<BoxShadow> get floatingShadow {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(0.25),
        blurRadius: 20,
        offset: const Offset(0, 10),
        spreadRadius: -5,
      ),
    ];
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      // Base text theme will be overridden below with Inter

      // AppBar moderna com gradiente
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),

      // Botões modernos com gradiente e animações
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
        ),
      ),

      // Floating Action Button moderno (extended em formato pill)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),

      // Cards com glassmorphism
      cardTheme: CardThemeData(
        color: cardColor.withOpacity(0.9),
        shadowColor: Colors.black.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),

      // Input Decoration moderna
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: textLightColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Text themes modernas (Inter via Google Fonts)
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textPrimaryColor,
          letterSpacing: -1,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.6,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.3,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          height: 1.6,
          letterSpacing: -0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          height: 1.5,
          letterSpacing: -0.1,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondaryColor,
          height: 1.4,
          letterSpacing: 0,
        ),
      )),

      // Color scheme moderna
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: textPrimaryColor,
        onSurface: textPrimaryColor,
        onError: Colors.white,
      ),

      // Componentes adicionais modernos
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 24,
      ),

      // SnackBar moderno
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        behavior: SnackBarBehavior.floating,
      ),

      // Transições de página suaves
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Método para criar gradientes personalizados
  static LinearGradient createGradient(List<Color> colors, {AlignmentGeometry begin = Alignment.topLeft, AlignmentGeometry end = Alignment.bottomRight}) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }
}
