import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/views/screens/home_screen.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angeleno_project/main.dart';
import 'package:provider/provider.dart';

void main() {

  final userProvider = UserProvider();
  const auth0User = UserProfile(
    sub: 'auth0|id',
    email: 'user@email.com',
    givenName: 'FirstName',
    familyName: 'LastName',
    customClaims: {
      'user_metadata': {
        'addresses': {
          'primary': {
            'address': '123 Main St',
            'address2': 'Suite 200',
            'city': 'Main City',
            'state': 'Main State',
            'zip': '12345'
          }
        },
        'phone': '(555) 555-5555'
      }
    }
  );
  userProvider.setUser(auth0User);

  group('OverlayProvider', () {
    test('Test overlay initialization', () {
      final overlayProvider = OverlayProvider();
      expect(overlayProvider.isLoading, false);
    });

    test('Test showing overlay', () {
      final overlayProvider = OverlayProvider();
      overlayProvider.showLoading();
      expect(overlayProvider.isLoading, true);
    });
  });

  testWidgets('Initial application load', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider(create: (final _) => OverlayProvider())
        ],
        child: const MyApp()
      )
    );

    expect(find.byType(MyHomePage), findsOneWidget);
    expect(find.text('Angeleno Account'), findsOneWidget);
  });
}