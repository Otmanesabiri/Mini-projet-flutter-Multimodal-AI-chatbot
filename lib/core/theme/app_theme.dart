import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _lightPrimaryColor = Color(0xFFF8F9FA);
  static const Color _lightAccentColor = Color(0xFF7B68EE);
  static const Color _darkPrimaryColor = Color(0xFF121826);
  static const Color _darkAccentColor = Color(0xFF9D86FF);

  // Text colors
  static const Color _lightTextColor = Color(0xFF1F1F1F);
  static const Color _darkTextColor = Color(0xFFF5F5F5);

  // Message bubble colors
  static const Color _lightUserBubbleColor = Color(0xFFE3DFFD);
  static const Color _lightAiBubbleColor = Color(0xFFFFFFFF);
  static const Color _darkUserBubbleColor = Color(0xFF2A2D3E);
  static const Color _darkAiBubbleColor = Color(0xFF1E1E2C);

  static ThemeData lightTheme() {
    return _baseTheme(
      brightness: Brightness.light,
      primaryColor: _lightPrimaryColor,
      accentColor: _lightAccentColor,
      textColor: _lightTextColor,
      userBubbleColor: _lightUserBubbleColor,
      aiBubbleColor: _lightAiBubbleColor,
    );
  }

  static ThemeData darkTheme() {
    return _baseTheme(
      brightness: Brightness.dark,
      primaryColor: _darkPrimaryColor,
      accentColor: _darkAccentColor,
      textColor: _darkTextColor,
      userBubbleColor: _darkUserBubbleColor,
      aiBubbleColor: _darkAiBubbleColor,
    );
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color accentColor,
    required Color textColor,
    required Color userBubbleColor,
    required Color aiBubbleColor,
  }) {
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: accentColor,
      onPrimary: brightness == Brightness.light ? Colors.white : Colors.black,
      secondary: accentColor.withOpacity(0.8),
      onSecondary: brightness == Brightness.light ? Colors.white : Colors.black,
      error: Colors.red.shade800,
      onError: Colors.white,
      background: primaryColor,
      onBackground: textColor,
      surface: brightness == Brightness.light 
          ? Colors.white 
          : const Color(0xFF1E1E2C),
      onSurface: textColor,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: primaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textColor.withOpacity(0.6),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: textColor,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: GoogleFonts.poppins(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.poppins(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textColor,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textColor,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          color: textColor.withOpacity(0.8),
          fontSize: 12,
          height: 1.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: brightness == Brightness.light
            ? Colors.grey.shade100
            : const Color(0xFF2A2D3E),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
      ),
      cardTheme: CardTheme(
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1E1E2C),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: brightness == Brightness.light 
              ? Colors.white 
              : Colors.black,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        ChatThemeExtension(
          userBubbleColor: userBubbleColor,
          aiBubbleColor: aiBubbleColor,
        ),
      ],
    );
  }
}

class ChatThemeExtension extends ThemeExtension<ChatThemeExtension> {
  final Color userBubbleColor;
  final Color aiBubbleColor;

  ChatThemeExtension({
    required this.userBubbleColor,
    required this.aiBubbleColor,
  });

  @override
  ThemeExtension<ChatThemeExtension> copyWith({
    Color? userBubbleColor,
    Color? aiBubbleColor,
  }) {
    return ChatThemeExtension(
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      aiBubbleColor: aiBubbleColor ?? this.aiBubbleColor,
    );
  }

  @override
  ThemeExtension<ChatThemeExtension> lerp(
    ThemeExtension<ChatThemeExtension>? other,
    double t,
  ) {
    if (other is! ChatThemeExtension) {
      return this;
    }
    return ChatThemeExtension(
      userBubbleColor: Color.lerp(userBubbleColor, other.userBubbleColor, t)!,
      aiBubbleColor: Color.lerp(aiBubbleColor, other.aiBubbleColor, t)!,
    );
  }
}