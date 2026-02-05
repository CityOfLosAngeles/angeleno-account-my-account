import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverlayProvider', () {
    late OverlayProvider overlayProvider;

    setUp(() {
      overlayProvider = OverlayProvider();
    });

    test('Initial state isLoading is false', () {
      expect(overlayProvider.isLoading, false);
    });

    test('showLoading sets isLoading to true', () {
      overlayProvider.showLoading();
      expect(overlayProvider.isLoading, true);
    });

    test('hideLoading sets isLoading to false', () {
      overlayProvider.showLoading();
      expect(overlayProvider.isLoading, true);

      overlayProvider.hideLoading();
      expect(overlayProvider.isLoading, false);
    });

    test('Multiple showLoading calls keep isLoading true', () {
      overlayProvider.showLoading();
      overlayProvider.showLoading();
      overlayProvider.showLoading();
      expect(overlayProvider.isLoading, true);
    });

    test('hideLoading after multiple showLoading sets isLoading to false', () {
      overlayProvider.showLoading();
      overlayProvider.showLoading();
      overlayProvider.hideLoading();
      expect(overlayProvider.isLoading, false);
    });

    test('showLoading notifies listeners', () {
      var listenerCalled = false;
      overlayProvider.addListener(() {
        listenerCalled = true;
      });

      overlayProvider.showLoading();
      expect(listenerCalled, true);
    });

    test('hideLoading notifies listeners', () {
      var listenerCalled = false;
      overlayProvider.showLoading();
      
      overlayProvider.addListener(() {
        listenerCalled = true;
      });

      overlayProvider.hideLoading();
      expect(listenerCalled, true);
    });
  });
}
