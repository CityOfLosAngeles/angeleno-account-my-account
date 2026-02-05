import 'package:angeleno_project/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Constants', () {
    test('nameRegEx validates valid names', () {
      expect(nameRegEx.hasMatch('John'), true);
      expect(nameRegEx.hasMatch('John Doe'), true);
      expect(nameRegEx.hasMatch("O'Brien"), true);
      expect(nameRegEx.hasMatch('José'), true);
      expect(nameRegEx.hasMatch('María García'), true);
      expect(nameRegEx.hasMatch('Jean-Pierre'), true);
      expect(nameRegEx.hasMatch(''), true);
    });

    test('nameRegEx accepts names with accents', () {
      expect(nameRegEx.hasMatch('François'), true);
      expect(nameRegEx.hasMatch('Müller'), true);
      expect(nameRegEx.hasMatch('Søren'), true);
      expect(nameRegEx.hasMatch('Ñoño'), true);
    });

    test('nameRegEx accepts names with numbers', () {
      expect(nameRegEx.hasMatch('Louis XIV'), true);
      expect(nameRegEx.hasMatch('John 3rd'), true);
    });

    test('nameRegEx validates invalid characters', () {
      expect(nameRegEx.hasMatch('John@Doe'), false);
      expect(nameRegEx.hasMatch('John#Doe'), false);
      expect(nameRegEx.hasMatch('John$Doe'), false);
      expect(nameRegEx.hasMatch('John%Doe'), false);
      expect(nameRegEx.hasMatch('John&Doe'), false);
    });

    test('smallScreenWidthBreakpoint has correct value', () {
      expect(smallScreenWidthBreakpoint, 575);
    });

    test('headerStyle has correct properties', () {
      expect(headerStyle.fontSize, 20);
      expect(headerStyle.fontWeight, FontWeight.bold);
    });
  });
}
