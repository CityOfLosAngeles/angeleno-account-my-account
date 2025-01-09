import 'package:flutter/material.dart';

/* Environment variables */
const auth0ClientId = String.fromEnvironment('CLIENT_ID');
const auth0Domain = String.fromEnvironment('AUTH0_DOMAIN');
const redirectUri = String.fromEnvironment('REDIRECT_URI');
const cloudFunctionURL =
    String.fromEnvironment('CLOUD_FUNCTIONS_URL');
const serviceAccountSecret = String.fromEnvironment('SA_SECRET_KEY');
const serviceAccountEmail = String.fromEnvironment('SA_EMAIL');
const environment = String.fromEnvironment('ENVIRONMENT');

/* Regex */
final RegExp nameRegEx = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-\d]*$");

/* Media Query Breakpoints */
const double smallScreen = 575;

/* Text Styles */
const headerStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold
);

/* Colors */
const disabledColor = Colors.black54;

ColorScheme colorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF006B59),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF7BF8D9),
  onPrimaryContainer: Color(0xFF002019),
  secondary: Color(0xFF4B635C),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFCDE9DF),
  onSecondaryContainer: Color(0xFF07201A),
  tertiary: Color(0xFF426277),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFC6E7FF),
  onTertiaryContainer: Color(0xFF001E2D),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  background: Color(0xFFFAFDFA),
  onBackground: Color(0xFF191C1B),
  surface: Color(0xFFFAFDFA),
  onSurface: Color(0xFF191C1B),
  surfaceVariant: Color(0xFFDBE5E0),
  onSurfaceVariant: Color(0xFF3F4945),
  outline: Color(0xFF6F7975),
  onInverseSurface: Color(0xFFEFF1EE),
  inverseSurface: Color(0xFF2E3130),
  inversePrimary: Color(0xFF5CDBBE),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF006B59),
  outlineVariant: Color(0xFFBFC9C4),
  scrim: Color(0xFF000000),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF5CDBBE),
  onPrimary: Color(0xFF00382D),
  primaryContainer: Color(0xFF005142),
  onPrimaryContainer: Color(0xFF7BF8D9),
  secondary: Color(0xFFB1CCC3),
  onSecondary: Color(0xFF1D352E),
  secondaryContainer: Color(0xFF334B44),
  onSecondaryContainer: Color(0xFFCDE9DF),
  tertiary: Color(0xFFAACBE3),
  onTertiary: Color(0xFF103447),
  tertiaryContainer: Color(0xFF294A5E),
  onTertiaryContainer: Color(0xFFC6E7FF),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  background: Color(0xFF191C1B),
  onBackground: Color(0xFFE1E3E0),
  surface: Color(0xFF191C1B),
  onSurface: Color(0xFFE1E3E0),
  surfaceVariant: Color(0xFF3F4945),
  onSurfaceVariant: Color(0xFFBFC9C4),
  outline: Color(0xFF89938F),
  onInverseSurface: Color(0xFF191C1B),
  inverseSurface: Color(0xFFE1E3E0),
  inversePrimary: Color(0xFF006B59),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF5CDBBE),
  outlineVariant: Color(0xFF3F4945),
  scrim: Color(0xFF000000),
);