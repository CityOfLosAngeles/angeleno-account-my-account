import 'package:angeleno_project/models/user.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class UserProvider extends ChangeNotifier {
  final Auth0Web auth0Web = Auth0Web(auth0Domain, auth0ClientId);
  User? _user;
  String? _accessToken;
  User? _cleanUser;
  bool _isEditing = false;

  UserProvider() {
    // temporary, to skip tests
    if (auth0Domain.isNotEmpty) {
      auth0Web.onLoad(audience: 'https://$auth0NonCustomDomain/api/v2/').then((final credentials) async {
        if (credentials != null
            && await auth0Web.hasValidCredentials()) {

          setUser(credentials.user);
          setAccessToken(credentials.accessToken);

          DatadogSdk.instance.setUserInfo(
            email: credentials.user.email,
            id: credentials.user.sub
          );

          setCleanUser(_user!);

        } else {
          await auth0Web.loginWithRedirect(redirectUrl: redirectUri);
        }
      });
    }
  }

  void setUser(final UserProfile user) {

    Address userAddress = Address();
    String phone = '';
    final consentedApps = <String, dynamic>{};

    final metadata = user.customClaims?['user_metadata']
                                  as Map<String, dynamic>? ?? {};

    final appData = user.customClaims?['app_metadata']
          as Map<String, dynamic>? ?? {};

    if (metadata.isNotEmpty) {
      final addressData = metadata['addresses']
        as Map<String, dynamic>? ?? {};

      final primaryAddress = addressData['primary']
        as Map<String, dynamic>? ?? {};

      userAddress = Address.fromJson(primaryAddress);

      phone = metadata['phone'] as String? ?? '';
    }

    if (appData.isNotEmpty) {
      final consentedApplications = appData['consent']
        as Map<String, dynamic>? ?? {};

      if (consentedApplications.isNotEmpty) {
        consentedApplications.forEach((final key, final value) {
          final appDetails = value as Map<String, dynamic>;
          final scopes = appDetails['scopes'] as String? ?? '';
          consentedApps[key] = {
            'scopes': scopes,
            'date': appDetails['datetime'] as int? ?? ''
          };
        });
      }
    }

    _user = User(
      userId: user.sub,
      email: user.email!,
      firstName: user.givenName ?? '',
      lastName: user.familyName ?? '',
      zip: userAddress.zip,
      address: userAddress.address,
      address2: userAddress.address2,
      city: userAddress.city,
      state: userAddress.state,
      phone: phone,
      metadata: metadata,
      appMetadata: appData,
      consentedApps: consentedApps
    );

    notifyListeners();
  }

  void setAccessToken(final String accessToken) {
    _accessToken = accessToken;
  }

  String? getAccessToken() => _accessToken;

  void setCleanUser(final User user) {
    _cleanUser = User.copy(user);
  }

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  Future<void> logout() => auth0Web.logout(
      federated: false,
      returnToUrl: 'https://account.lacity.gov/'
  );

  User? get user => _user;

  User? get cleanUser => _cleanUser;

  bool get isEditing => _isEditing;
}
