import 'package:flutter/material.dart';

import 'constants.dart';

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static MaterialScheme lightScheme() => const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0B6B59),
      surfaceTint: Color(0xFF0B6B59),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFA1F2DC),
      onPrimaryContainer: Color(0xFF002019),
      secondary: Color(0xFF4B635C),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFCDE8DF),
      onSecondaryContainer: Color(0xFF07201A),
      tertiary: Color(0xFF426277),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFC6E7FF),
      onTertiaryContainer: Color(0xFF001E2E),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      background: Color(0xFFF5FBF7),
      onBackground: Color(0xFF171D1B),
      surface: Color(0xFFF5FBF7),
      onSurface: Color(0xFF171D1B),
      surfaceVariant: Color(0xFFDBE5E0),
      onSurfaceVariant: Color(0xFF3F4945),
      outline: Color(0xFF6F7975),
      outlineVariant: Color(0xFFBFC9C4),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2B322F),
      inverseOnSurface: Color(0xFFECF2EE),
      inversePrimary: Color(0xFF85D6C0),
      primaryFixed: Color(0xFFA1F2DC),
      onPrimaryFixed: Color(0xFF002019),
      primaryFixedDim: Color(0xFF85D6C0),
      onPrimaryFixedVariant: Color(0xFF005143),
      secondaryFixed: Color(0xFFCDE8DF),
      onSecondaryFixed: Color(0xFF07201A),
      secondaryFixedDim: Color(0xFFB1CCC3),
      onSecondaryFixedVariant: Color(0xFF334B44),
      tertiaryFixed: Color(0xFFC6E7FF),
      onTertiaryFixed: Color(0xFF001E2E),
      tertiaryFixedDim: Color(0xFFAACBE3),
      onTertiaryFixedVariant: Color(0xFF294A5F),
      surfaceDim: Color(0xFFD5DBD8),
      surfaceBright: Color(0xFFF5FBF7),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFEFF5F1),
      surfaceContainer: Color(0xFFE9EFEB),
      surfaceContainerHigh: Color(0xFFE3EAE6),
      surfaceContainerHighest: Color(0xFFDEE4E0),
    );

  ThemeData light() => theme(lightScheme().toColorScheme());

  static MaterialScheme lightMediumContrastScheme() => const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xFF004C3F),
      surfaceTint: Color(0xFF0B6B59),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF2E826F),
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondary: Color(0xFF2F4841),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF617A72),
      onSecondaryContainer: Color(0xFFFFFFFF),
      tertiary: Color(0xFF25465A),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFF58788E),
      onTertiaryContainer: Color(0xFFFFFFFF),
      error: Color(0xFF8C0009),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFDA342E),
      onErrorContainer: Color(0xFFFFFFFF),
      background: Color(0xFFF5FBF7),
      onBackground: Color(0xFF171D1B),
      surface: Color(0xFFF5FBF7),
      onSurface: Color(0xFF171D1B),
      surfaceVariant: Color(0xFFDBE5E0),
      onSurfaceVariant: Color(0xFF3B4541),
      outline: Color(0xFF57615D),
      outlineVariant: Color(0xFF737D79),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2B322F),
      inverseOnSurface: Color(0xFFECF2EE),
      inversePrimary: Color(0xFF85D6C0),
      primaryFixed: Color(0xFF2E826F),
      onPrimaryFixed: Color(0xFFFFFFFF),
      primaryFixedDim: Color(0xFF046857),
      onPrimaryFixedVariant: Color(0xFFFFFFFF),
      secondaryFixed: Color(0xFF617A72),
      onSecondaryFixed: Color(0xFFFFFFFF),
      secondaryFixedDim: Color(0xFF486159),
      onSecondaryFixedVariant: Color(0xFFFFFFFF),
      tertiaryFixed: Color(0xFF58788E),
      onTertiaryFixed: Color(0xFFFFFFFF),
      tertiaryFixedDim: Color(0xFF3F6075),
      onTertiaryFixedVariant: Color(0xFFFFFFFF),
      surfaceDim: Color(0xFFD5DBD8),
      surfaceBright: Color(0xFFF5FBF7),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFEFF5F1),
      surfaceContainer: Color(0xFFE9EFEB),
      surfaceContainerHigh: Color(0xFFE3EAE6),
      surfaceContainerHighest: Color(0xFFDEE4E0),
    );

  ThemeData lightMediumContrast() => theme(lightMediumContrastScheme().toColorScheme());

  static MaterialScheme lightHighContrastScheme() => const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xFF002820),
      surfaceTint: Color(0xFF0B6B59),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF004C3F),
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondary: Color(0xFF0E2620),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF2F4841),
      onSecondaryContainer: Color(0xFFFFFFFF),
      tertiary: Color(0xFF002537),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFF25465A),
      onTertiaryContainer: Color(0xFFFFFFFF),
      error: Color(0xFF4E0002),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFF8C0009),
      onErrorContainer: Color(0xFFFFFFFF),
      background: Color(0xFFF5FBF7),
      onBackground: Color(0xFF171D1B),
      surface: Color(0xFFF5FBF7),
      onSurface: Color(0xFF000000),
      surfaceVariant: Color(0xFFDBE5E0),
      onSurfaceVariant: Color(0xFF1D2623),
      outline: Color(0xFF3B4541),
      outlineVariant: Color(0xFF3B4541),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2B322F),
      inverseOnSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFFAAFCE5),
      primaryFixed: Color(0xFF004C3F),
      onPrimaryFixed: Color(0xFFFFFFFF),
      primaryFixedDim: Color(0xFF00342A),
      onPrimaryFixedVariant: Color(0xFFFFFFFF),
      secondaryFixed: Color(0xFF2F4841),
      onSecondaryFixed: Color(0xFFFFFFFF),
      secondaryFixedDim: Color(0xFF19312B),
      onSecondaryFixedVariant: Color(0xFFFFFFFF),
      tertiaryFixed: Color(0xFF25465A),
      onTertiaryFixed: Color(0xFFFFFFFF),
      tertiaryFixedDim: Color(0xFF0A3043),
      onTertiaryFixedVariant: Color(0xFFFFFFFF),
      surfaceDim: Color(0xFFD5DBD8),
      surfaceBright: Color(0xFFF5FBF7),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFEFF5F1),
      surfaceContainer: Color(0xFFE9EFEB),
      surfaceContainerHigh: Color(0xFFE3EAE6),
      surfaceContainerHighest: Color(0xFFDEE4E0),
    );

  ThemeData lightHighContrast() => theme(lightHighContrastScheme().toColorScheme());

  static MaterialScheme darkScheme() => const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF85D6C0),
      surfaceTint: Color(0xFF85D6C0),
      onPrimary: Color(0xFF00382D),
      primaryContainer: Color(0xFF005143),
      onPrimaryContainer: Color(0xFFA1F2DC),
      secondary: Color(0xFFB1CCC3),
      onSecondary: Color(0xFF1D352E),
      secondaryContainer: Color(0xFF334B44),
      onSecondaryContainer: Color(0xFFCDE8DF),
      tertiary: Color(0xFFAACBE3),
      onTertiary: Color(0xFF103447),
      tertiaryContainer: Color(0xFF294A5F),
      onTertiaryContainer: Color(0xFFC6E7FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      background: Color(0xFF0E1513),
      onBackground: Color(0xFFDEE4E0),
      surface: Color(0xFF0E1513),
      onSurface: Color(0xFFDEE4E0),
      surfaceVariant: Color(0xFF3F4945),
      onSurfaceVariant: Color(0xFFBFC9C4),
      outline: Color(0xFF89938F),
      outlineVariant: Color(0xFF3F4945),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDEE4E0),
      inverseOnSurface: Color(0xFF2B322F),
      inversePrimary: Color(0xFF0B6B59),
      primaryFixed: Color(0xFFA1F2DC),
      onPrimaryFixed: Color(0xFF002019),
      primaryFixedDim: Color(0xFF85D6C0),
      onPrimaryFixedVariant: Color(0xFF005143),
      secondaryFixed: Color(0xFFCDE8DF),
      onSecondaryFixed: Color(0xFF07201A),
      secondaryFixedDim: Color(0xFFB1CCC3),
      onSecondaryFixedVariant: Color(0xFF334B44),
      tertiaryFixed: Color(0xFFC6E7FF),
      onTertiaryFixed: Color(0xFF001E2E),
      tertiaryFixedDim: Color(0xFFAACBE3),
      onTertiaryFixedVariant: Color(0xFF294A5F),
      surfaceDim: Color(0xFF0E1513),
      surfaceBright: Color(0xFF343B38),
      surfaceContainerLowest: Color(0xFF090F0E),
      surfaceContainerLow: Color(0xFF171D1B),
      surfaceContainer: Color(0xFF1B211F),
      surfaceContainerHigh: Color(0xFF252B29),
      surfaceContainerHighest: Color(0xFF303634),
    );

  ThemeData dark() => theme(darkScheme().toColorScheme());

  static MaterialScheme darkMediumContrastScheme() => const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF89DAC4),
      surfaceTint: Color(0xFF85D6C0),
      onPrimary: Color(0xFF001A14),
      primaryContainer: Color(0xFF4E9F8B),
      onPrimaryContainer: Color(0xFF000000),
      secondary: Color(0xFFB6D1C7),
      onSecondary: Color(0xFF021A15),
      secondaryContainer: Color(0xFF7C968E),
      onSecondaryContainer: Color(0xFF000000),
      tertiary: Color(0xFFAECFE8),
      onTertiary: Color(0xFF001826),
      tertiaryContainer: Color(0xFF7495AC),
      onTertiaryContainer: Color(0xFF000000),
      error: Color(0xFFFFBAB1),
      onError: Color(0xFF370001),
      errorContainer: Color(0xFFFF5449),
      onErrorContainer: Color(0xFF000000),
      background: Color(0xFF0E1513),
      onBackground: Color(0xFFDEE4E0),
      surface: Color(0xFF0E1513),
      onSurface: Color(0xFFF6FCF8),
      surfaceVariant: Color(0xFF3F4945),
      onSurfaceVariant: Color(0xFFC3CDC8),
      outline: Color(0xFF9BA5A1),
      outlineVariant: Color(0xFF7B8581),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDEE4E0),
      inverseOnSurface: Color(0xFF252B29),
      inversePrimary: Color(0xFF005244),
      primaryFixed: Color(0xFFA1F2DC),
      onPrimaryFixed: Color(0xFF001510),
      primaryFixedDim: Color(0xFF85D6C0),
      onPrimaryFixedVariant: Color(0xFF003E33),
      secondaryFixed: Color(0xFFCDE8DF),
      onSecondaryFixed: Color(0xFF001510),
      secondaryFixedDim: Color(0xFFB1CCC3),
      onSecondaryFixedVariant: Color(0xFF233B34),
      tertiaryFixed: Color(0xFFC6E7FF),
      onTertiaryFixed: Color(0xFF00131F),
      tertiaryFixedDim: Color(0xFFAACBE3),
      onTertiaryFixedVariant: Color(0xFF173A4D),
      surfaceDim: Color(0xFF0E1513),
      surfaceBright: Color(0xFF343B38),
      surfaceContainerLowest: Color(0xFF090F0E),
      surfaceContainerLow: Color(0xFF171D1B),
      surfaceContainer: Color(0xFF1B211F),
      surfaceContainerHigh: Color(0xFF252B29),
      surfaceContainerHighest: Color(0xFF303634),
    );

  ThemeData darkMediumContrast() => theme(darkMediumContrastScheme().toColorScheme());

  static MaterialScheme darkHighContrastScheme() => const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFECFFF7),
      surfaceTint: Color(0xFF85D6C0),
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFF89DAC4),
      onPrimaryContainer: Color(0xFF000000),
      secondary: Color(0xFFECFFF7),
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFFB6D1C7),
      onSecondaryContainer: Color(0xFF000000),
      tertiary: Color(0xFFF8FBFF),
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFFAECFE8),
      onTertiaryContainer: Color(0xFF000000),
      error: Color(0xFFFFF9F9),
      onError: Color(0xFF000000),
      errorContainer: Color(0xFFFFBAB1),
      onErrorContainer: Color(0xFF000000),
      background: Color(0xFF0E1513),
      onBackground: Color(0xFFDEE4E0),
      surface: Color(0xFF0E1513),
      onSurface: Color(0xFFFFFFFF),
      surfaceVariant: Color(0xFF3F4945),
      onSurfaceVariant: Color(0xFFF3FDF8),
      outline: Color(0xFFC3CDC8),
      outlineVariant: Color(0xFFC3CDC8),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDEE4E0),
      inverseOnSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF003127),
      primaryFixed: Color(0xFFA5F7E0),
      onPrimaryFixed: Color(0xFF000000),
      primaryFixedDim: Color(0xFF89DAC4),
      onPrimaryFixedVariant: Color(0xFF001A14),
      secondaryFixed: Color(0xFFD1EDE3),
      onSecondaryFixed: Color(0xFF000000),
      secondaryFixedDim: Color(0xFFB6D1C7),
      onSecondaryFixedVariant: Color(0xFF021A15),
      tertiaryFixed: Color(0xFFD0EAFF),
      onTertiaryFixed: Color(0xFF000000),
      tertiaryFixedDim: Color(0xFFAACBE3),
      onTertiaryFixedVariant: Color(0xFF173A4D),
      surfaceDim: Color(0xFF0E1513),
      surfaceBright: Color(0xFF343B38),
      surfaceContainerLowest: Color(0xFF090F0E),
      surfaceContainerLow: Color(0xFF171D1B),
      surfaceContainer: Color(0xFF1B211F),
      surfaceContainerHigh: Color(0xFF252B29),
      surfaceContainerHighest: Color(0xFF303634),
    );

  ThemeData darkHighContrast() => theme(darkHighContrastScheme().toColorScheme());


  ThemeData theme(final ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    // overrides
    inputDecorationTheme: const InputDecorationTheme(
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: disabledColor)
      )
    )
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class MaterialScheme {
  const MaterialScheme({
    required this.brightness,
    required this.primary,
    required this.surfaceTint,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixedVariant,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });

  final Brightness brightness;
  final Color primary;
  final Color surfaceTint;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixedVariant;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
}

extension MaterialSchemeUtils on MaterialScheme {
  ColorScheme toColorScheme() => ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
    );
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
