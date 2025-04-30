import 'package:angeleno_project/models/user.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class UserProvider extends ChangeNotifier {
  final Auth0Web auth0Web = Auth0Web(auth0Domain, auth0ClientId);
  User? _user;
  User? _cleanUser;
  bool _isEditing = false;

  UserProvider() {
    // temporary, to skip tests
    if (auth0Domain.isNotEmpty) {
      auth0Web.onLoad().then((final credentials) async {
        if (credentials != null
            && await auth0Web.hasValidCredentials()) {

          setUser(credentials.user);

          DatadogSdk.instance.setUserInfo(
            email: credentials.user.email
          );

          setCleanUser(_user!);

        } else {
          await auth0Web.loginWithRedirect(redirectUrl: redirectUri);
        }
      });
    }
  }

  void setUser(final UserProfile user) {

    String zip = '';
    String address = '';
    String address2 = '';
    String city = '';
    String state = '';
    String phone = '';

    final metadata = user.customClaims?['user_metadata']
                                  as Map<String, dynamic>;

    if (metadata.isNotEmpty) {
      final primaryAddress = metadata['addresses']?['primary'];

      if (primaryAddress != null) {
        address = primaryAddress['address'] != null ?
          primaryAddress['address'] as String : '';
        address2 = primaryAddress['address2'] != null ?
          primaryAddress['address2'] as String : '';
        city =  primaryAddress['city'] != null ?
          primaryAddress['city'] as String : '';
        state = primaryAddress['state'] != null ?
          primaryAddress['state'] as String : '';
        zip = primaryAddress['zip'] != null ?
          primaryAddress['zip'] as String : '';
      }

      phone = metadata['phone'] as String;
    }

    _user = User(
        userId: user.sub,
        email: user.email!,
        firstName: user.givenName ?? '',
        lastName: user.familyName ?? '',
        zip: zip,
        address: address,
        address2: address2,
        city: city,
        state: state,
        phone: phone,
        metadata: metadata
    );

    notifyListeners();
  }

  void setCleanUser(final User user) {
    _cleanUser = User.copy(user);
  }

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  Future<void> logout() => auth0Web.logout(
      federated: false,
      returnToUrl: 'https://sandbox.account.lacity.gov/'
  );

  User? get user => _user;

  User? get cleanUser => _cleanUser;

  bool get isEditing => _isEditing;
}
