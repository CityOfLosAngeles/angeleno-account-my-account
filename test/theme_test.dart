import 'package:angeleno_project/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaterialTheme Tests', () {
    late MaterialTheme materialTheme;

    setUp(() {
      materialTheme = MaterialTheme(TextTheme());
    });

    test('Light theme uses lightScheme', () {
      final themeData = materialTheme.light();
      expect(themeData.brightness, Brightness.light);
      expect(themeData.colorScheme.primary, const Color(0xff0c6b59));
      expect(themeData.colorScheme.onPrimary, const Color(0xffffffff));
    });

    test('Dark theme uses darkScheme', () {
      final themeData = materialTheme.dark();
      expect(themeData.brightness, Brightness.dark);
      expect(themeData.colorScheme.primary, const Color(0xff85d6bf));
      expect(themeData.colorScheme.onPrimary, const Color(0xff00382d));
    });

    test('LightMediumContrast theme uses lightMediumConstrastScheme', () {
      final themeData = materialTheme.lightMediumContrast();
      expect(themeData.brightness, Brightness.light);
      expect(themeData.colorScheme.primary, const Color(0xff003e33));
      expect(themeData.colorScheme.onPrimary, const Color(0xffffffff));
    });

    test('DarkMediumContast theme uses darkMediumContrastScheme', () {
      final themeData = materialTheme.darkMediumContrast();
      expect(themeData.brightness, Brightness.dark);
      expect(themeData.colorScheme.primary, const Color(0xff9becd5));
      expect(themeData.colorScheme.onPrimary, const Color(0xff002c23));
    });

    test('LightHighContrast theme uses lightHighContrastScheme', () {
      final themeData = materialTheme.lightHighContrast();
      expect(themeData.brightness, Brightness.light);
      expect(themeData.colorScheme.primary, const Color(0xff003329));
      expect(themeData.colorScheme.onPrimary, const Color(0xffffffff));
    });

    test('DarkHighContrast theme uses darkHighContrastScheme', () {
      final themeData = materialTheme.darkHighContrast();
      expect(themeData.brightness, Brightness.dark);
      expect(themeData.colorScheme.primary, const Color(0xffb3ffe9));
      expect(themeData.colorScheme.onPrimary, const Color(0xff000000));
    });

    test('Theme method applies ColorScheme and TextTheme correctly', () {
      final colorScheme = MaterialTheme.lightScheme();
      final themeData = materialTheme.theme(colorScheme);

      expect(themeData.colorScheme, colorScheme);
      expect(themeData.textTheme.bodyLarge?.color, colorScheme.onSurface);
      expect(themeData.scaffoldBackgroundColor, colorScheme.background);
      expect(themeData.canvasColor, colorScheme.surface);
    });

    test('ExtendedColor instantiation works correctly', () {
      const extendedColor = ExtendedColor(
        seed: Color(0xff000000),
        value: Color(0xff123456),
        light: ColorFamily(
          color: Color(0xffabcdef),
          onColor: Color(0xfffedcba),
          colorContainer: Color(0xff123123),
          onColorContainer: Color(0xff321321),
        ),
        lightHighContrast: ColorFamily(
          color: Color(0xff654321),
          onColor: Color(0xffabcdef),
          colorContainer: Color(0xff111111),
          onColorContainer: Color(0xff222222),
        ),
        lightMediumContrast: ColorFamily(
          color: Color(0xff333333),
          onColor: Color(0xff444444),
          colorContainer: Color(0xff555555),
          onColorContainer: Color(0xff666666),
        ),
        dark: ColorFamily(
          color: Color(0xff777777),
          onColor: Color(0xff888888),
          colorContainer: Color(0xff999999),
          onColorContainer: Color(0xffaaaaaa),
        ),
        darkHighContrast: ColorFamily(
          color: Color(0xffbbbbbb),
          onColor: Color(0xffcccccc),
          colorContainer: Color(0xffdddddd),
          onColorContainer: Color(0xffeeeeee),
        ),
        darkMediumContrast: ColorFamily(
          color: Color(0xffffffff),
          onColor: Color(0xff000000),
          colorContainer: Color(0xff123456),
          onColorContainer: Color(0xff654321),
        ),
      );

      expect(extendedColor.seed, const Color(0xff000000));
      expect(extendedColor.value, const Color(0xff123456));
      expect(extendedColor.light.color, const Color(0xffabcdef));
      expect(extendedColor.dark.onColor, const Color(0xff888888));
    });
  });
}