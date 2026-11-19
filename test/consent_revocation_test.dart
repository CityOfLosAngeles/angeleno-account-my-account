import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('revocation updates live and clean consent state', () {
    final userProvider = UserProvider();
    userProvider.setUser(UserProfile(
      sub: 'user-id',
      email: 'user@example.com',
      customClaims: {
        'app_metadata': {
          'consent': {
            'application-a': {'scopes_labels': 'openid', 'datetime': 123},
            'application-b': {'scopes_labels': 'profile', 'datetime': 456},
          },
        },
      },
    ));
    userProvider.setCleanUser(userProvider.user!);

    final updatedAppMetadata = Map<String, dynamic>.from(userProvider.user!.appMetadata);
    updatedAppMetadata['consent'] = Map<String, dynamic>.from(
      updatedAppMetadata['consent'] as Map<String, dynamic>,
    )..remove('application-a');

    userProvider.updateConsentAfterRevocation('user-id', 'application-a', updatedAppMetadata);

    expect(userProvider.user!.appMetadata['consent'], isNot(contains('application-a')));
    expect(userProvider.user!.connectedApplications, isNot(contains('application-a')));
    expect(userProvider.cleanUser!.appMetadata['consent'], isNot(contains('application-a')));
    expect(userProvider.cleanUser!.connectedApplications, isNot(contains('application-a')));

    userProvider.discardChanges();

    expect(userProvider.user!.appMetadata['consent'], isNot(contains('application-a')));
    expect(userProvider.user!.connectedApplications, isNot(contains('application-a')));
  });
}
