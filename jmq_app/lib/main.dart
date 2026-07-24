import 'package:flutter/material.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JMQApp());
}

class JMQApp extends StatelessWidget {
  const JMQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'JMQ Service Manual',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      routerConfig: appRouter,
    );
  }
}

final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF000000),
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF2A2A2A),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFCCCCCC),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF2A2A2A),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFF888888),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF222222),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFF2A2A2A),
    onErrorContainer: Color(0xFFFFFFFF),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFF1A1A1A),
    onSurfaceVariant: Color(0xFFB0B0B0),
    outline: Color(0xFF555555),
    outlineVariant: Color(0xFF2A2A2A),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: Color(0xFF000000),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF111111),
    foregroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Color(0xFF111111),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1A1A1A),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF222222),
    labelStyle: const TextStyle(color: Color(0xFFFFFFFF)),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF000000),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF444444)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF444444)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF2A2A2A),
  ),
);

final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF000000),
    surfaceTint: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E0E0),
    onPrimaryContainer: Color(0xFF000000),
    secondary: Color(0xFF555555),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E0E0),
    onSecondaryContainer: Color(0xFF000000),
    tertiary: Color(0xFF888888),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF0F0F0),
    onTertiaryContainer: Color(0xFF000000),
    error: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFE0E0E0),
    onErrorContainer: Color(0xFF000000),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    surfaceContainerHighest: Color(0xFFF5F5F5),
    onSurfaceVariant: Color(0xFF555555),
    outline: Color(0xFFBBBBBB),
    outlineVariant: Color(0xFFDDDDDD),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF000000),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFFFFFFFF),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F5),
    foregroundColor: Color(0xFF000000),
    surfaceTintColor: Color(0xFFF5F5F5),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFFFAFAFA),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFEEEEEE),
    labelStyle: const TextStyle(color: Color(0xFF000000)),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF000000),
      foregroundColor: const Color(0xFFFFFFFF),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF000000)),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE0E0E0),
  ),
);
