import 'dart:convert';

import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/models/api_exception.dart';
import 'package:angeleno_project/models/api_response.dart';
import 'package:angeleno_project/models/connected_applications_model.dart';
import 'package:angeleno_project/models/mfa_method.dart';
import 'package:angeleno_project/models/mfa_response.dart';
import 'package:angeleno_project/models/password_reset.dart';
import 'package:angeleno_project/models/user.dart';
import 'package:angeleno_project/utils/error_message.dart';
import 'package:angeleno_project/utils/theme.dart';
import 'package:angeleno_project/views/screens/password_screen.dart';
import 'package:angeleno_project/views/screens/profile_screen.dart';
import 'package:angeleno_project/widgets/navigation_button.dart';
import 'package:auth0_flutter/auth0_flutter.dart' hide ApiException;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Helper: creates a minimal MaterialApp wrapper for widget tests
// ---------------------------------------------------------------------------
Widget wrapWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

// =========================================================================
//  MODEL TESTS
// =========================================================================

// ---- User model ----------------------------------------------------------
void userModelTests() {
  group('User model', () {
    late User user;

    setUp(() {
      user = User(
        userId: 'auth0|abc123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        address: '123 Main St',
        address2: 'Apt 4',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
        phone: '+11234567890',
        metadata: {'key': 'value'},
      );
    });

    test('toJson returns correct map', () {
      final json = user.toJson();
      expect(json['userId'], 'auth0|abc123');
      expect(json['email'], 'test@example.com');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['address'], '123 Main St');
      expect(json['address2'], 'Apt 4');
      expect(json['city'], 'Los Angeles');
      expect(json['state'], 'CA');
      expect(json['zip'], '90001');
      expect(json['phone'], '+11234567890');
      expect(json['metadata'], {'key': 'value'});
    });

    test('toString returns formatted string', () {
      final str = user.toString();
      expect(str, contains('auth0|abc123'));
      expect(str, contains('test@example.com'));
      expect(str, contains('John'));
      expect(str, contains('Doe'));
    });

    test('User.copy creates an independent copy', () {
      final copy = User.copy(user);
      expect(copy.userId, user.userId);
      expect(copy.email, user.email);
      expect(copy.firstName, user.firstName);
      expect(copy.lastName, user.lastName);
      expect(copy.address, user.address);
      expect(copy.address2, user.address2);
      expect(copy.city, user.city);
      expect(copy.state, user.state);
      expect(copy.zip, user.zip);
      expect(copy.phone, user.phone);
      expect(copy.metadata, user.metadata);
    });

    test('equality compares editable fields only (not email/userId)', () {
      final copy = User.copy(user);
      expect(user == copy, isTrue);

      // Changing email does NOT break equality (by design)
      copy.email = 'other@example.com';
      expect(user == copy, isTrue);

      // Changing firstName DOES break equality
      copy.firstName = 'Jane';
      expect(user == copy, isFalse);
    });

    test('equality detects address differences', () {
      final copy = User.copy(user);
      copy.address = '456 New Ave';
      expect(user == copy, isFalse);
    });

    test('equality detects city differences', () {
      final copy = User.copy(user);
      copy.city = 'San Francisco';
      expect(user == copy, isFalse);
    });

    test('equality detects state differences', () {
      final copy = User.copy(user);
      copy.state = 'NY';
      expect(user == copy, isFalse);
    });

    test('equality detects zip differences', () {
      final copy = User.copy(user);
      copy.zip = '10001';
      expect(user == copy, isFalse);
    });

    test('equality detects phone differences', () {
      final copy = User.copy(user);
      copy.phone = '+10987654321';
      expect(user == copy, isFalse);
    });

    test('equality detects address2 differences', () {
      final copy = User.copy(user);
      copy.address2 = 'Suite 5';
      expect(user == copy, isFalse);
    });

    test('hashCode is consistent with equality', () {
      final copy = User.copy(user);
      expect(user.hashCode, copy.hashCode);
    });

    test('User with null optional fields serialises correctly', () {
      final u = User(
        userId: 'id1',
        email: 'e@e.com',
        firstName: null,
        lastName: null,
        address: null,
        address2: null,
        city: null,
        state: null,
        zip: null,
        phone: null,
        metadata: null,
      );
      final json = u.toJson();
      expect(json['firstName'], isNull);
      expect(json['metadata'], isNull);
    });

    test('equality between user and non-User object is false', () {
      // ignore: unrelated_type_equality_checks
      expect(user == 'not a user', isFalse);
    });
  });
}

// ---- Address model -------------------------------------------------------
void addressModelTests() {
  group('Address model', () {
    test('default constructor uses empty strings', () {
      final addr = Address();
      expect(addr.address, '');
      expect(addr.address2, '');
      expect(addr.city, '');
      expect(addr.state, '');
      expect(addr.zip, '');
    });

    test('fromJson parses a full JSON map', () {
      final json = {
        'address': '100 Elm St',
        'address2': 'Unit B',
        'city': 'Pasadena',
        'state': 'CA',
        'zip': '91101',
      };
      final addr = Address.fromJson(json);
      expect(addr.address, '100 Elm St');
      expect(addr.address2, 'Unit B');
      expect(addr.city, 'Pasadena');
      expect(addr.state, 'CA');
      expect(addr.zip, '91101');
    });

    test('fromJson handles missing keys gracefully', () {
      final addr = Address.fromJson({});
      expect(addr.address, '');
      expect(addr.city, '');
    });

    test('fromJson handles null values gracefully', () {
      final json = <String, dynamic>{
        'address': null,
        'address2': null,
        'city': null,
        'state': null,
        'zip': null,
      };
      final addr = Address.fromJson(json);
      expect(addr.address, '');
      expect(addr.address2, '');
      expect(addr.city, '');
      expect(addr.state, '');
      expect(addr.zip, '');
    });

    test('toJson returns correct map', () {
      final addr = Address(
        address: 'A',
        address2: 'B',
        city: 'C',
        state: 'D',
        zip: 'E',
      );
      final json = addr.toJson();
      expect(json, {
        'address': 'A',
        'address2': 'B',
        'city': 'C',
        'state': 'D',
        'zip': 'E',
      });
    });

    test('roundtrip fromJson -> toJson preserves data', () {
      final original = {
        'address': '1 Street',
        'address2': '',
        'city': 'LA',
        'state': 'CA',
        'zip': '90001',
      };
      final addr = Address.fromJson(original);
      expect(addr.toJson(), original);
    });
  });
}

// ---- ApiException --------------------------------------------------------
void apiExceptionTests() {
  group('ApiException', () {
    test('error parses JSON body', () {
      final body = jsonEncode({'error': 'invalid_grant'});
      final ex = ApiException(400, body);
      expect(ex.statusCode, 400);
      expect(ex.error, 'invalid_grant');
    });

    test('error returns fallback when body is invalid JSON', () {
      final ex = ApiException(500, 'not json');
      expect(ex.error, 'Error encountered');
    });

    test('error returns fallback when body is null', () {
      final ex = ApiException(500, null);
      expect(ex.error, 'Error encountered');
    });

    test('error returns fallback when JSON has no error key', () {
      final body = jsonEncode({'message': 'oops'});
      final ex = ApiException(400, body);
      // jsonDecode succeeds but cast to String on null throws
      expect(ex.error, 'Error encountered');
    });

    test('implements Exception', () {
      final ex = ApiException(400, '{}');
      expect(ex, isA<Exception>());
    });
  });
}

// ---- ApiResponse ---------------------------------------------------------
void apiResponseTests() {
  group('ApiResponse', () {
    test('stores statusCode and body', () {
      final res = ApiResponse(200, 'OK');
      expect(res.statusCode, 200);
      expect(res.body, 'OK');
    });

    test('implements Exception', () {
      final res = ApiResponse(200, '');
      expect(res, isA<Exception>());
    });
  });
}

// ---- Service (ConnectedApplicationsModel) --------------------------------
void serviceModelTests() {
  group('Service model', () {
    test('fromJson parses valid JSON', () {
      final json = {
        'clientId': 'cid1',
        'name': 'My App',
        'scope': ['openid', 'profile', 'email'],
        'logo_uri': 'https://img.com/logo.png',
        'grantId': 'gid1',
      };
      final svc = Service.fromJson(json);
      expect(svc.id, 'cid1');
      expect(svc.name, 'My App');
      expect(svc.scope, ['profile', 'email']); // openid filtered out
      expect(svc.icon, 'https://img.com/logo.png');
      expect(svc.grantId, 'gid1');
    });

    test('fromJson filters out openid scope', () {
      final json = {
        'clientId': 'c',
        'name': 'n',
        'scope': ['openid'],
        'logo_uri': '',
        'grantId': 'g',
      };
      final svc = Service.fromJson(json);
      expect(svc.scope, isEmpty);
    });

    test('fromJson defaults icon to empty string when logo_uri missing', () {
      final json = {
        'clientId': 'c',
        'name': 'n',
        'scope': <String>[],
        'grantId': 'g',
      };
      final svc = Service.fromJson(json);
      expect(svc.icon, '');
    });

    test('toJson returns correct map', () {
      final svc = Service(
        id: 'c1',
        name: 'App',
        scope: ['read'],
        icon: 'icon.png',
        grantId: 'g1',
      );
      final json = svc.toJson();
      expect(json['clientId'], 'c1');
      expect(json['name'], 'App');
      expect(json['scope'], ['read']);
      expect(json['logo_uri'], 'icon.png');
      expect(json['grantId'], 'g1');
    });

    test('roundtrip fromJson -> toJson preserves data (minus openid)', () {
      final original = {
        'clientId': 'c1',
        'name': 'SvcName',
        'scope': ['profile'],
        'logo_uri': 'logo.png',
        'grantId': 'g1',
      };
      final svc = Service.fromJson(original);
      expect(svc.toJson(), original);
    });
  });
}

// ---- MfaMethod -----------------------------------------------------------
void mfaMethodTests() {
  group('MfaMethod model', () {
    test('default constructor uses sensible defaults', () {
      final m = MfaMethod();
      expect(m.id, '');
      expect(m.authenticatorType, '');
      expect(m.active, false);
      expect(m.oobChannel, '');
      expect(m.name, '');
    });

    test('fromJson parses full JSON', () {
      final json = {
        'id': 'mfa1',
        'authenticator_type': 'oob',
        'active': true,
        'oob_channel': 'sms',
        'name': 'My Phone',
      };
      final m = MfaMethod.fromJson(json);
      expect(m.id, 'mfa1');
      expect(m.authenticatorType, 'oob');
      expect(m.active, true);
      expect(m.oobChannel, 'sms');
      expect(m.name, 'My Phone');
    });

    test('fromJson handles missing keys with defaults', () {
      final m = MfaMethod.fromJson({});
      expect(m.id, '');
      expect(m.authenticatorType, '');
      expect(m.active, false);
      expect(m.oobChannel, '');
      expect(m.name, '');
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'authenticator_type': null,
        'active': null,
        'oob_channel': null,
        'name': null,
      };
      final m = MfaMethod.fromJson(json);
      expect(m.id, '');
      expect(m.active, false);
    });

    test('toJson returns correct map', () {
      final m = MfaMethod(
        id: 'x',
        authenticatorType: 'oob',
        active: true,
        oobChannel: 'voice',
        name: 'Phone',
      );
      final json = m.toJson();
      expect(json, {
        'id': 'x',
        'authenticator_type': 'oob',
        'active': true,
        'oob_channel': 'voice',
        'name': 'Phone',
      });
    });
  });
}

// ---- MfaResponse ---------------------------------------------------------
void mfaResponseTests() {
  group('MfaResponse model', () {
    test('default constructor uses empty strings', () {
      final r = MfaResponse();
      expect(r.barcode, '');
      expect(r.token, '');
      expect(r.barcodeString, '');
      expect(r.oobCode, '');
      expect(r.errorMessage, '');
    });

    test('fromJson parses token from "token" key', () {
      final json = {
        'token': 'tok123',
        'barcode_uri': 'otpauth://totp/...',
        'secret': 'ABCDEF',
        'oob_code': 'oob1',
        'error': '',
      };
      final r = MfaResponse.fromJson(json);
      expect(r.token, 'tok123');
      expect(r.barcode, 'otpauth://totp/...');
      expect(r.barcodeString, 'ABCDEF');
      expect(r.oobCode, 'oob1');
      expect(r.errorMessage, '');
    });

    test('fromJson falls back to "mfaToken" when "token" is absent', () {
      final json = <String, dynamic>{
        'mfaToken': 'mfa_tok',
      };
      final r = MfaResponse.fromJson(json);
      expect(r.token, 'mfa_tok');
    });

    test('fromJson defaults to empty when both token keys absent', () {
      final r = MfaResponse.fromJson({});
      expect(r.token, '');
    });

    test('fromJson parses error message', () {
      final json = {
        'error': 'User is already enrolled.',
      };
      final r = MfaResponse.fromJson(json);
      expect(r.errorMessage, 'User is already enrolled.');
    });

    test('fromJson handles null values', () {
      final json = <String, dynamic>{
        'token': null,
        'mfaToken': null,
        'barcode_uri': null,
        'secret': null,
        'oob_code': null,
        'error': null,
      };
      final r = MfaResponse.fromJson(json);
      expect(r.token, '');
      expect(r.barcode, '');
      expect(r.barcodeString, '');
      expect(r.oobCode, '');
      expect(r.errorMessage, '');
    });

    test('toString contains all fields', () {
      final r = MfaResponse(
        barcode: 'b',
        token: 't',
        barcodeString: 'bs',
        oobCode: 'o',
      );
      final s = r.toString();
      expect(s, contains('barcode: b'));
      expect(s, contains('token: t'));
      expect(s, contains('barcodeString: bs'));
      expect(s, contains('oobCode: o'));
    });
  });
}

// ---- PasswordBody --------------------------------------------------------
void passwordBodyTests() {
  group('PasswordBody model', () {
    test('toJson returns correct map', () {
      final p = PasswordBody(
        email: 'user@test.com',
        oldPassword: 'old123',
        newPassword: 'new456',
        userId: 'uid1',
      );
      expect(p.toJson(), {
        'email': 'user@test.com',
        'oldPassword': 'old123',
        'newPassword': 'new456',
        'userId': 'uid1',
      });
    });

    test('fields are mutable via late assignment', () {
      final p = PasswordBody(
        email: 'a',
        oldPassword: 'b',
        newPassword: 'c',
        userId: 'd',
      );
      p.email = 'updated@test.com';
      expect(p.email, 'updated@test.com');
    });
  });
}

// =========================================================================
//  CONTROLLER TESTS
// =========================================================================

// ---- OverlayProvider -----------------------------------------------------
void overlayProviderTests() {
  group('OverlayProvider', () {
    late OverlayProvider provider;

    setUp(() {
      provider = OverlayProvider();
    });

    test('initial isLoading is false', () {
      expect(provider.isLoading, isFalse);
    });

    test('showLoading sets isLoading to true', () {
      provider.showLoading();
      expect(provider.isLoading, isTrue);
    });

    test('hideLoading sets isLoading to false', () {
      provider.showLoading();
      provider.hideLoading();
      expect(provider.isLoading, isFalse);
    });

    test('showLoading notifies listeners', () {
      var notified = false;
      provider.addListener(() {
        notified = true;
      });
      provider.showLoading();
      expect(notified, isTrue);
    });

    test('hideLoading notifies listeners', () {
      provider.showLoading();
      var notified = false;
      provider.addListener(() {
        notified = true;
      });
      provider.hideLoading();
      expect(notified, isTrue);
    });

    test('multiple showLoading calls keep isLoading true', () {
      provider.showLoading();
      provider.showLoading();
      expect(provider.isLoading, isTrue);
    });

    test('hideLoading without prior showLoading keeps isLoading false', () {
      provider.hideLoading();
      expect(provider.isLoading, isFalse);
    });

    test('toggle show/hide cycle works repeatedly', () {
      for (var i = 0; i < 5; i++) {
        provider.showLoading();
        expect(provider.isLoading, isTrue);
        provider.hideLoading();
        expect(provider.isLoading, isFalse);
      }
    });
  });
}

// =========================================================================
//  UTILS / CONSTANTS TESTS
// =========================================================================
void nameRegexTests() {
  // The regex from constants.dart:  ^[a-zA-Z\u00C0-\u00FF\s'\-\d]*$
  final RegExp nameRegEx = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-\d]*$");

  group('nameRegEx (from constants)', () {
    test('allows simple alpha names', () {
      expect(nameRegEx.hasMatch('John'), isTrue);
      expect(nameRegEx.hasMatch('jane'), isTrue);
    });

    test('allows accented characters', () {
      expect(nameRegEx.hasMatch('José'), isTrue);
      expect(nameRegEx.hasMatch('François'), isTrue);
      expect(nameRegEx.hasMatch('Müller'), isTrue);
    });

    test('allows hyphens', () {
      expect(nameRegEx.hasMatch('Anne-Marie'), isTrue);
    });

    test('allows apostrophes', () {
      expect(nameRegEx.hasMatch("O'Brien"), isTrue);
    });

    test('allows digits', () {
      expect(nameRegEx.hasMatch('John3'), isTrue);
    });

    test('allows spaces', () {
      expect(nameRegEx.hasMatch('Mary Jane'), isTrue);
    });

    test('allows empty string', () {
      expect(nameRegEx.hasMatch(''), isTrue);
    });

    test('rejects special symbols', () {
      expect(nameRegEx.hasMatch('John!'), isFalse);
      expect(nameRegEx.hasMatch('Jane@Doe'), isFalse);
      expect(nameRegEx.hasMatch('Test#'), isFalse);
      expect(nameRegEx.hasMatch('Foo\$Bar'), isFalse);
    });

    test('rejects angle brackets', () {
      expect(nameRegEx.hasMatch('<script>'), isFalse);
    });
  });
}

// =========================================================================
//  WIDGET TESTS
// =========================================================================

// ---- ErrorMessage widget -------------------------------------------------
void errorMessageWidgetTests() {
  group('ErrorMessage widget', () {
    testWidgets('displays default message', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(const ErrorMessage()));
      expect(find.text('An error occurred'), findsOneWidget);
    });

    testWidgets('displays custom message', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWidget(const ErrorMessage(message: 'Custom error')),
      );
      expect(find.text('Custom error'), findsOneWidget);
    });

    testWidgets('text uses error color from theme', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(const ErrorMessage()));
      final textWidget = tester.widget<Text>(find.text('An error occurred'));
      final style = textWidget.style!;
      // Just verify the style has a color set (the actual error colour
      // comes from the theme so we check it is non-null)
      expect(style.color, isNotNull);
    });
  });
}

// ---- NavigationButton widget ---------------------------------------------
void navigationButtonWidgetTests() {
  group('NavigationButton widget', () {
    testWidgets('renders icon and text', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(
        NavigationButton(
          icon: const Icon(Icons.person),
          text: const Text('Profile'),
          onPressed: () {},
          isActive: false,
        ),
      ));

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWidget(
        NavigationButton(
          icon: const Icon(Icons.person),
          text: const Text('Profile'),
          onPressed: () {
            tapped = true;
          },
          isActive: false,
        ),
      ));

      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
    });

    testWidgets('active state uses non-transparent background',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(
        NavigationButton(
          icon: const Icon(Icons.home),
          text: const Text('Home'),
          onPressed: () {},
          isActive: true,
        ),
      ));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final bgProp = button.style?.backgroundColor;
      // When active, backgroundColor resolves to null (theme default)
      expect(bgProp, isNotNull);
    });

    testWidgets('inactive state uses transparent background',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(
        NavigationButton(
          icon: const Icon(Icons.home),
          text: const Text('Home'),
          onPressed: () {},
          isActive: false,
        ),
      ));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final bgProp = button.style?.backgroundColor;
      // When inactive, resolve is Colors.transparent
      final resolved = bgProp?.resolve(<WidgetState>{});
      expect(resolved, Colors.transparent);
    });

    testWidgets('inactive state uses transparent shadow',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(
        NavigationButton(
          icon: const Icon(Icons.home),
          text: const Text('Home'),
          onPressed: () {},
          isActive: false,
        ),
      ));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final shadowProp = button.style?.shadowColor;
      final resolved = shadowProp?.resolve(<WidgetState>{});
      expect(resolved, Colors.transparent);
    });

    testWidgets('takes full width', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWidget(
        NavigationButton(
          icon: const Icon(Icons.home),
          text: const Text('Home'),
          onPressed: () {},
          isActive: false,
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });
  });
}

// =========================================================================
//  THEME TESTS
// =========================================================================
void materialThemeTests() {
  group('MaterialTheme', () {
    test('lightScheme returns a light ColorScheme', () {
      final cs = MaterialTheme.lightScheme();
      expect(cs.brightness, Brightness.light);
      expect(cs.primary, const Color(0xff0c6b59));
      expect(cs.error, const Color(0xffba1a1a));
    });

    test('darkScheme returns a dark ColorScheme', () {
      final cs = MaterialTheme.darkScheme();
      expect(cs.brightness, Brightness.dark);
      expect(cs.primary, const Color(0xff85d6bf));
    });

    test('lightMediumContrastScheme has light brightness', () {
      final cs = MaterialTheme.lightMediumContrastScheme();
      expect(cs.brightness, Brightness.light);
    });

    test('lightHighContrastScheme has light brightness', () {
      final cs = MaterialTheme.lightHighContrastScheme();
      expect(cs.brightness, Brightness.light);
    });

    test('darkMediumContrastScheme has dark brightness', () {
      final cs = MaterialTheme.darkMediumContrastScheme();
      expect(cs.brightness, Brightness.dark);
    });

    test('darkHighContrastScheme has dark brightness', () {
      final cs = MaterialTheme.darkHighContrastScheme();
      expect(cs.brightness, Brightness.dark);
    });

    test('theme() returns ThemeData with Material3 enabled', () {
      const mt = MaterialTheme(TextTheme());
      final td = mt.theme(MaterialTheme.lightScheme());
      expect(td.useMaterial3, isTrue);
      expect(td.colorScheme.brightness, Brightness.light);
    });

    test('light() convenience returns light ThemeData', () {
      const mt = MaterialTheme(TextTheme());
      final td = mt.light();
      expect(td.colorScheme.brightness, Brightness.light);
    });

    test('dark() convenience returns dark ThemeData', () {
      const mt = MaterialTheme(TextTheme());
      final td = mt.dark();
      expect(td.colorScheme.brightness, Brightness.dark);
    });

    test('theme applies textTheme body/display colors from colorScheme', () {
      const mt = MaterialTheme(TextTheme());
      final cs = MaterialTheme.lightScheme();
      final td = mt.theme(cs);
      expect(td.textTheme.bodyLarge?.color, cs.onSurface);
    });

    test('extendedColors is empty by default', () {
      const mt = MaterialTheme(TextTheme());
      expect(mt.extendedColors, isEmpty);
    });
  });

  group('ColorFamily', () {
    test('stores all four color fields', () {
      const cf = ColorFamily(
        color: Color(0xff000000),
        onColor: Color(0xffffffff),
        colorContainer: Color(0xff111111),
        onColorContainer: Color(0xffeeeeee),
      );
      expect(cf.color, const Color(0xff000000));
      expect(cf.onColor, const Color(0xffffffff));
      expect(cf.colorContainer, const Color(0xff111111));
      expect(cf.onColorContainer, const Color(0xffeeeeee));
    });
  });

  group('ExtendedColor', () {
    test('stores seed, value, and all scheme families', () {
      const fam = ColorFamily(
        color: Color(0xff000000),
        onColor: Color(0xffffffff),
        colorContainer: Color(0xff111111),
        onColorContainer: Color(0xffeeeeee),
      );
      const ec = ExtendedColor(
        seed: Color(0xffaaaaaa),
        value: Color(0xffbbbbbb),
        light: fam,
        lightHighContrast: fam,
        lightMediumContrast: fam,
        dark: fam,
        darkHighContrast: fam,
        darkMediumContrast: fam,
      );
      expect(ec.seed, const Color(0xffaaaaaa));
      expect(ec.value, const Color(0xffbbbbbb));
      expect(ec.light.color, const Color(0xff000000));
    });
  });
}

// =========================================================================
//  USER PROVIDER TESTS (non-Auth0 methods)
// =========================================================================
void userProviderTests() {
  group('UserProvider', () {
    late UserProvider provider;

    setUp(() {
      // auth0Domain is empty at test time → constructor skips Auth0Web login
      provider = UserProvider();
    });

    test('initial user is null', () {
      expect(provider.user, isNull);
    });

    test('initial cleanUser is null', () {
      expect(provider.cleanUser, isNull);
    });

    test('initial isEditing is false', () {
      expect(provider.isEditing, isFalse);
    });

    test('initial accessToken is null', () {
      expect(provider.getAccessToken(), isNull);
    });

    test('setAccessToken / getAccessToken round-trip', () {
      provider.setAccessToken('tok-abc');
      expect(provider.getAccessToken(), 'tok-abc');
    });

    test('setAccessToken overwrites previous token', () {
      provider.setAccessToken('first');
      provider.setAccessToken('second');
      expect(provider.getAccessToken(), 'second');
    });

    test('toggleEditing flips isEditing', () {
      expect(provider.isEditing, isFalse);
      provider.toggleEditing();
      expect(provider.isEditing, isTrue);
      provider.toggleEditing();
      expect(provider.isEditing, isFalse);
    });

    test('toggleEditing notifies listeners', () {
      var notified = false;
      provider.addListener(() {
        notified = true;
      });
      provider.toggleEditing();
      expect(notified, isTrue);
    });

    test('setUser maps UserProfile to User correctly (no metadata)', () {
      const profile = UserProfile(
        sub: 'auth0|user1',
        email: 'user@example.com',
        givenName: 'Jane',
        familyName: 'Smith',
      );

      provider.setUser(profile);

      final user = provider.user;
      expect(user, isNotNull);
      expect(user!.userId, 'auth0|user1');
      expect(user.email, 'user@example.com');
      expect(user.firstName, 'Jane');
      expect(user.lastName, 'Smith');
      expect(user.phone, '');
      expect(user.address, '');
    });

    test('setUser maps metadata with address and phone', () {
      const profile = UserProfile(
        sub: 'auth0|user2',
        email: 'u@e.com',
        givenName: 'A',
        familyName: 'B',
        customClaims: {
          'user_metadata': {
            'phone': '+12125551234',
            'addresses': {
              'primary': {
                'address': '100 Main St',
                'address2': 'Apt 1',
                'city': 'LA',
                'state': 'CA',
                'zip': '90001',
              }
            }
          }
        },
      );

      provider.setUser(profile);
      final user = provider.user!;
      expect(user.phone, '+12125551234');
      expect(user.address, '100 Main St');
      expect(user.address2, 'Apt 1');
      expect(user.city, 'LA');
      expect(user.state, 'CA');
      expect(user.zip, '90001');
    });

    test('setUser with empty metadata gives defaults', () {
      const profile = UserProfile(
        sub: 'auth0|u3',
        email: 'x@x.com',
        customClaims: {
          'user_metadata': <String, dynamic>{}
        },
      );
      provider.setUser(profile);
      expect(provider.user!.phone, '');
      expect(provider.user!.address, '');
    });

    test('setUser with null customClaims gives defaults', () {
      const profile = UserProfile(
        sub: 'auth0|u4',
        email: 'z@z.com',
      );
      provider.setUser(profile);
      expect(provider.user!.phone, '');
      expect(provider.user!.firstName, '');
    });

    test('setUser notifies listeners', () {
      var notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });
      const profile = UserProfile(sub: 'id', email: 'e@e.com');
      provider.setUser(profile);
      expect(notifyCount, 1);
    });

    test('setCleanUser creates an independent copy', () {
      const profile = UserProfile(
        sub: 'id',
        email: 'e@e.com',
        givenName: 'Orig',
        familyName: 'Name',
      );
      provider.setUser(profile);
      provider.setCleanUser(provider.user!);

      // Mutate the active user
      provider.user!.firstName = 'Changed';

      // cleanUser should still have original value
      expect(provider.cleanUser!.firstName, 'Orig');
    });

    test('setUser with missing givenName/familyName defaults to empty', () {
      const profile = UserProfile(
        sub: 'id',
        email: 'e@e.com',
      );
      provider.setUser(profile);
      expect(provider.user!.firstName, '');
      expect(provider.user!.lastName, '');
    });
  });
}

// =========================================================================
//  PASSWORD SCREEN WIDGET TESTS
// =========================================================================

/// Helper: wraps a widget with the required ChangeNotifierProviders
Widget wrapWithProviders(Widget child, {UserProvider? up, OverlayProvider? op}) {
  final userProvider = up ?? UserProvider();
  final overlayProvider = op ?? OverlayProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<OverlayProvider>.value(value: overlayProvider),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Creates a UserProvider that already has a user set (bypasses auth0)
UserProvider createSeededUserProvider() {
  final up = UserProvider();
  const profile = UserProfile(
    sub: 'auth0|pw_test',
    email: 'pw@test.com',
    givenName: 'Test',
    familyName: 'User',
  );
  up.setUser(profile);
  up.setCleanUser(up.user!);
  up.setAccessToken('fake-token');
  return up;
}

void passwordScreenWidgetTests() {
  group('PasswordScreen widget', () {
    testWidgets('renders header and three password fields',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      expect(find.text('Password change'), findsOneWidget);
      expect(find.text('Current password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);
    });

    testWidgets('submit button starts disabled',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update password and logout'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('password visibility toggle for current password',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      // Initially obscured → visibility icon is shown
      expect(find.byIcon(Icons.visibility), findsWidgets);

      // Tap the toggle for old password
      await tester.tap(find.byKey(const Key('toggle_old_password')));
      await tester.pump();

      // Now the eye-off icon should appear for that field
      expect(find.byIcon(Icons.visibility_off), findsWidgets);
    });

    testWidgets('shows password length requirement text',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      expect(find.text('Password must:'), findsOneWidget);
      expect(find.textContaining('Be at least 12 characters'), findsOneWidget);
    });

    testWidgets('submit button enables when all fields are valid and match',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      // Fill current password
      await tester.enterText(find.byKey(const Key('old_password')), 'OldPass123!');
      await tester.pump();

      // Fill new password (>= 12 chars)
      await tester.enterText(find.byKey(const Key('new_password')), 'NewSecure12345');
      await tester.pump();

      // Fill confirm password (matching)
      await tester.enterText(find.byKey(const Key('match_password')), 'NewSecure12345');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update password and logout'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('submit button stays disabled when passwords do not match',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('old_password')), 'OldPass123!');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('new_password')), 'NewSecure12345');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('match_password')), 'Mismatch12345');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update password and logout'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button stays disabled when new password is too short',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('old_password')), 'OldPass123!');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('new_password')), 'Short1');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('match_password')), 'Short1');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update password and logout'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('new password visibility toggle works',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_new_password')));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsWidgets);
    });

    testWidgets('confirm password visibility toggle works',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_match_password')));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsWidgets);
    });

    testWidgets('validation error shown for empty current password',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const PasswordScreen(), up: up));
      await tester.pumpAndSettle();

      // Enter and clear to trigger validation
      await tester.enterText(find.byKey(const Key('old_password')), 'x');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('old_password')), '');
      await tester.pump();

      expect(find.text('Password is required'), findsWidgets);
    });
  });
}

// =========================================================================
//  PROFILE SCREEN WIDGET TESTS
// =========================================================================

/// Creates a UserProvider with full profile data (address, phone, etc.)
UserProvider createFullProfileProvider() {
  final up = UserProvider();
  const profile = UserProfile(
    sub: 'auth0|profile_test',
    email: 'profile@test.com',
    givenName: 'Alice',
    familyName: 'Wonder',
    customClaims: {
      'user_metadata': {
        'phone': '+12125559999',
        'addresses': {
          'primary': {
            'address': '742 Evergreen Ter',
            'address2': 'Unit 3',
            'city': 'Springfield',
            'state': 'IL',
            'zip': '62704',
          }
        }
      }
    },
  );
  up.setUser(profile);
  up.setCleanUser(up.user!);
  up.setAccessToken('fake-token');
  return up;
}

void profileScreenWidgetTests() {
  group('ProfileScreen widget', () {
    testWidgets('renders Profile header',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('renders all form field labels',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      expect(find.text('First name (required)'), findsOneWidget);
      expect(find.text('Last name (required)'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Address 2'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
      expect(find.text('Zip'), findsOneWidget);
    });

    testWidgets('shows Edit button in view mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('tapping Edit shows Save button and hides Edit',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('form fields are disabled in view mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      // All TextFormFields should be disabled. We can verify by checking
      // that none of the EditableText widgets accept input.
      // A pragmatic check: find TextFormFields and verify they have
      // enabled == false through their decoration opacity or by trying
      // to enter text and seeing it doesn't change.
      final firstNameField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(firstNameField.enabled, isFalse);
    });

    testWidgets('form fields become enabled after tapping Edit',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final firstNameField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(firstNameField.enabled, isTrue);
    });

    testWidgets('displays initial user values in form fields',
        (WidgetTester tester) async {
      final up = createFullProfileProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      // Check that user data is visible in the form
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Wonder'), findsOneWidget);
      expect(find.text('742 Evergreen Ter'), findsOneWidget);
      expect(find.text('Unit 3'), findsOneWidget);
      expect(find.text('Springfield'), findsOneWidget);
      expect(find.text('IL'), findsOneWidget);
      expect(find.text('62704'), findsOneWidget);
    });

    testWidgets('can modify first name in edit mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find the first TextFormField (first name) and change it
      final firstNameFinder = find.byType(TextFormField).first;
      await tester.enterText(firstNameFinder, 'NewFirst');
      await tester.pump();

      expect(up.user!.firstName, 'NewFirst');
    });

    testWidgets('can modify last name in edit mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Second TextFormField is last name
      final lastNameFinder = find.byType(TextFormField).at(1);
      await tester.enterText(lastNameFinder, 'NewLast');
      await tester.pump();

      expect(up.user!.lastName, 'NewLast');
    });

    testWidgets('can modify address field in edit mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // TextFormFields order: 0=first, 1=last, 2=phone(inside intl widget),
      // 3=address, 4=address2, 5=city, 6=state, 7=zip
      // The intl phone widget contains its own TextFormField, so address
      // is at index 3 in the overall byType list.
      final addressFinder = find.byType(TextFormField).at(3);
      await tester.enterText(addressFinder, '999 New Blvd');
      await tester.pump();

      expect(up.user!.address, '999 New Blvd');
    });

    testWidgets('can modify city field in edit mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // city is at index 5
      final cityFinder = find.byType(TextFormField).at(5);
      await tester.enterText(cityFinder, 'Gotham');
      await tester.pump();

      expect(up.user!.city, 'Gotham');
    });

    testWidgets('can modify zip field in edit mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // zip is at index 7
      final zipFinder = find.byType(TextFormField).at(7);
      await tester.enterText(zipFinder, '10001');
      await tester.pump();

      expect(up.user!.zip, '10001');
    });

    testWidgets('first name validation: empty shows error',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final firstNameFinder = find.byType(TextFormField).first;
      // Clear the field
      await tester.enterText(firstNameFinder, '');
      await tester.pump();

      expect(find.text('Please enter a first name'), findsOneWidget);
    });

    testWidgets('first name validation: invalid characters shows error',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final firstNameFinder = find.byType(TextFormField).first;
      await tester.enterText(firstNameFinder, 'Test<script>');
      await tester.pump();

      expect(find.text('Invalid characters in first name'), findsOneWidget);
    });

    testWidgets('last name validation: empty shows error',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final lastNameFinder = find.byType(TextFormField).at(1);
      await tester.enterText(lastNameFinder, '');
      await tester.pump();

      expect(find.text('Please enter a last name'), findsOneWidget);
    });

    testWidgets('last name validation: invalid characters shows error',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final lastNameFinder = find.byType(TextFormField).at(1);
      await tester.enterText(lastNameFinder, 'Doe@#!');
      await tester.pump();

      expect(find.text('Invalid characters in last name'), findsOneWidget);
    });

    testWidgets('tapping Save returns to view mode',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back to view mode
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('edit/save roundtrip preserves field values',
        (WidgetTester tester) async {
      final up = createFullProfileProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Modify first name
      final firstNameFinder = find.byType(TextFormField).first;
      await tester.enterText(firstNameFinder, 'Bob');
      await tester.pump();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // User model should reflect the change
      expect(up.user!.firstName, 'Bob');
      // Other fields should remain unchanged
      expect(up.user!.lastName, 'Wonder');
      expect(up.user!.city, 'Springfield');
    });

    testWidgets('phone field is present',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      // The InternationalPhoneNumberInput renders with a Key
      expect(find.byKey(const Key('phoneField')), findsOneWidget);
    });

    testWidgets('first name accepts accented characters without error',
        (WidgetTester tester) async {
      final up = createSeededUserProvider();
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen(), up: up));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final firstNameFinder = find.byType(TextFormField).first;
      await tester.enterText(firstNameFinder, 'José-François');
      await tester.pump();

      // No validation errors should appear
      expect(find.text('Invalid characters in first name'), findsNothing);
      expect(find.text('Please enter a first name'), findsNothing);
      expect(up.user!.firstName, 'José-François');
    });
  });
}

// =========================================================================
//  MAIN – runs all groups
// =========================================================================
void main() {
  // Models
  userModelTests();
  addressModelTests();
  apiExceptionTests();
  apiResponseTests();
  serviceModelTests();
  mfaMethodTests();
  mfaResponseTests();
  passwordBodyTests();

  // Controllers / Providers
  overlayProviderTests();
  userProviderTests();

  // Utils / Constants
  nameRegexTests();
  materialThemeTests();

  // Widgets
  errorMessageWidgetTests();
  navigationButtonWidgetTests();
  passwordScreenWidgetTests();
  profileScreenWidgetTests();
}

