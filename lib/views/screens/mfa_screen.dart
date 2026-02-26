import 'dart:io';
import 'dart:convert';

import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_provider.dart';
import '../../controllers/auth0_user_api_implementation.dart';
import '../../utils/constants.dart';
import '../../models/connected_applications_model.dart';
import '../../models/mfa_method.dart';
import '../dialogs/mobile.dart';
import '../dialogs/authenticator.dart';

class AdvancedSecurityScreen extends StatefulWidget {
  const AdvancedSecurityScreen({
    super.key
  });

  @override
  State<AdvancedSecurityScreen> createState() => _AdvancedSecurityState();
}

class _AdvancedSecurityState extends State<AdvancedSecurityScreen> with RouteAware, DatadogRouteAwareMixin {

  @override
  RumViewInfo get rumViewInfo => RumViewInfo(name: 'MFA Screen');

  late Auth0UserApi auth0UserApi;
  late UserProvider userProvider;
  late Future<void> _authMethods;
  late List<Service> _connectedServices;
  late VoidCallback _userListener;

  bool _authenticatorEnabled = false;
  bool _smsEnabled = false;
  bool _voiceEnabled = false;
  bool _isInitialized = false;

  String totpAuthId = '';
  String smsAuthId = '';
  String voiceAuthId = '';

  List<MfaMethod> authenticators = [];

  @override
  void initState() {
    super.initState();
    _authMethods = Future.value();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      userProvider = Provider.of(context, listen: false);
      auth0UserApi = Auth0UserApi(userProvider);

      _userListener = () {
        print('hey');
        if (userProvider.user != null) {
          _triggerAuthMethods();
        }
      };

      userProvider.removeListener(_userListener);
      userProvider.addListener(_userListener);

      if (userProvider.user != null) {
        _triggerAuthMethods();
      }
      _isInitialized = true;
    }

  }

  @override
  void dispose() {
    userProvider.removeListener(_userListener);
    super.dispose();
  }

  void _triggerAuthMethods() {
    setState(() {
      _authMethods = getAuthenticationMethods();
    });
  }

  Future<void> getAuthenticationMethods() async {
    _connectedServices = [];
    authenticators = [];

    await auth0UserApi.getAuthenticationMethods(userProvider.user!.userId, userProvider.user!.consentedAppIds.join(','))
      .then((final response) {
        final bool success = response.statusCode == HttpStatus.ok;
        if (success) {
          final String jsonString = response.body;
          final json = jsonDecode(jsonString) as Map<String, dynamic>;

          final List<dynamic> dataList = json['mfaMethods'] as List<dynamic>;

          final List<dynamic> services = json.containsKey('services')
              ? json['services'] as List<dynamic> : [];

          final List<Service> connectedServices = services
            .map((final e) =>
             Service.fromJson(e as Map<String, dynamic>)
          ).toList();

          _connectedServices.addAll(connectedServices);

          if (dataList.isNotEmpty) {
            for (final element in dataList) {
              final type = element['type'] as String;
              final methodId = element['id'] as String;

              final MfaMethod mfaMethod = MfaMethod();
              mfaMethod.id = methodId;
              mfaMethod.authenticatorType = type;

              switch(type) {
                case 'totp':
                  _authenticatorEnabled = true;
                  totpAuthId = methodId;
                  break;
                case 'phone':
                  mfaMethod.name = element['phone_number'] as String;
                  final prefMethod =
                  element['preferred_authentication_method'] as String;
                  if (prefMethod == 'sms') {
                    _smsEnabled = true;
                    smsAuthId = methodId;
                    mfaMethod.oobChannel = 'sms';
                  } else {
                    _voiceEnabled = true;
                    voiceAuthId = methodId;
                    mfaMethod.oobChannel = 'voice';
                  }
              }

              authenticators.add(mfaMethod);
            }
          }
        }
      });

  }

  Future<void> disableMFA(final String mfaAuthId, final String method) async {

    final response = await auth0UserApi.unenrollMFA({
      'authFactorId': mfaAuthId,
      'userId': userProvider.user!.userId
    });

    if (!mounted) return;

    final bool success = response.statusCode == HttpStatus.ok;
    if (success) {

      getAuthenticationMethods();

      String authMethod;
      switch (method) {
        case 'totp':
          authMethod = 'Authenticator App';
          break;
        case 'sms':
          authMethod = 'SMS';
          break;
        case 'voice':
          authMethod = 'Voice';
          break;
        default:
          authMethod = 'Unknown';
      }

      Navigator.pop(context, response.statusCode);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 280.0,
        content: Text('$authMethod has been removed.')
      ));
    }
  }

  Future<void> removeConnection(String id) async {
    final consentData = userProvider.user!.appMetadata.remove('consent') as Map<String, dynamic>? ?? {};
    final appMetadataCopy = Map<String, dynamic>.from(consentData);
    appMetadataCopy.remove(id);
    userProvider.user!.appMetadata.addAll({'consent': appMetadataCopy});

    final response = await auth0UserApi.removeConnection(userProvider.user!.userId, userProvider.user!.appMetadata);

    if (response.statusCode == HttpStatus.ok) {
      Navigator.pop(context, response.statusCode);
      setState(() {
        _connectedServices.removeWhere((final service) => service.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 280.0,
        content: Text('Service has been disconnected.')
      ));

    }
  }

  @override
  Widget build(final BuildContext context) {

    if (userProvider.user == null) {
      return const LinearProgressIndicator();
    }

    return FutureBuilder(
      future: _authMethods,
      builder:(final BuildContext context, final AsyncSnapshot<void> snapshot) =>
      snapshot.connectionState == ConnectionState.done ?
        Align(
          alignment: Alignment.topCenter,
            child:  SingleChildScrollView(
              child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: const Text(
                        'Multi-factor authentication',
                        textAlign: TextAlign.left,
                        style: headerStyle
                      )
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Authenticator app (Timed one-time password)',
                            softWrap: true,
                          ),
                        ),
                        _authenticatorEnabled ?
                        FilledButton.tonal(
                          key: const Key('disableAuthenticator'),
                          onPressed: () => showDialog<int>(
                            context: context,
                            builder: (final BuildContext context) => AlertDialog(
                              title: const Text('Remove authenticator app?'),
                              content: const SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      // ignore: avoid_escaping_inner_quotes
                                      Text('You won\'t be able to use your  '
                                          'authenticator app to sign into your Angeleno '
                                          'Account.')
                                    ],
                                  )
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Ok'),
                                  onPressed: () {
                                    disableMFA(totpAuthId, 'totp');
                                  },
                                )
                              ],
                            )
                          ).then((final value) {
                            if (value != null && value == HttpStatus.ok) {
                              _authenticatorEnabled = false;
                            }
                          }),
                          child: const Text('Disable', semanticsLabel: 'Disable authenticator application'),
                        )
                            :
                        FilledButton(
                          key: const Key('enableAuthenticator'),
                          onPressed: () {
                            showDialog<int>(
                              context: context,
                              builder: (final BuildContext context) =>
                                AuthenticatorDialog(
                                  userProvider: userProvider,
                                  auth0UserApi: auth0UserApi,
                                  authMethods: authenticators
                                ),
                            ).then((final value) {
                              if (value != null && value == HttpStatus.ok){
                                _triggerAuthMethods();
                              }
                            });
                          },
                          child: const Text('Enable', semanticsLabel: 'Enable authenticator application')
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SMS text'),
                        _smsEnabled ?
                        FilledButton.tonal(
                          key: const Key('disableSMS'),
                          onPressed: () => showDialog<int>(
                            context: context,
                            builder: (final BuildContext context) => AlertDialog(
                              title: const Text('Remove SMS MFA?'),
                              content: const SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    // ignore: avoid_escaping_inner_quotes
                                    Text('Do you confirm to remove SMS text? This'
                                        ' action is irreversible. If you want to use this'
                                        ' factor again you will need to enroll the'
                                        ' factor again.'
                                    )
                                  ],
                                )
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Ok'),
                                  onPressed: () {
                                    disableMFA(smsAuthId, 'sms');
                                  },
                                )
                              ],
                            )
                          ).then((final value) {
                            if (value != null && value == HttpStatus.ok) {
                              _smsEnabled = false;
                            }
                          }),
                          child: const Text('Disable', semanticsLabel: 'Disable sms mfa'),
                        )
                            :
                        FilledButton(
                          key: const Key('enableSMS'),
                          onPressed: () {
                            showDialog<int>(
                              context: context,
                              builder: (final BuildContext context) =>
                                MobileDialog(
                                  userProvider: userProvider,
                                  userApi: auth0UserApi,
                                  channel: 'sms',
                                  authMethods: authenticators
                                )
                            ).then((final value) {
                              if (value != null && value == HttpStatus.ok){
                                _triggerAuthMethods();
                              }
                            });
                          },
                          child: const Text('Enable', semanticsLabel: 'Enable sms mfa')
                        )
                      ]
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phone call'),
                        _voiceEnabled ?
                        FilledButton.tonal(
                          key: const Key('disableVoice'),
                          onPressed: () => showDialog<int>(
                            context: context,
                            builder: (final BuildContext context) => AlertDialog(
                              title: const Text('Remove Voice MFA?'),
                              content: const SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    // ignore: avoid_escaping_inner_quotes
                                    Text('Do you confirm to remove voice calls? This'
                                        ' action is irreversible. If you want to use this'
                                        ' factor again you will need to enroll the'
                                        ' factor again.'
                                    )
                                  ],
                                )
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Ok'),
                                  onPressed: () {
                                    disableMFA(voiceAuthId, 'voice');
                                  },
                                )
                              ],
                            )
                          ).then((final value) {
                            if (value != null && value == HttpStatus.ok) {
                              _voiceEnabled = false;
                            }
                          }),
                          child: const Text('Disable', semanticsLabel: 'Disable voice authentication'),
                        )
                            :
                        FilledButton(
                          key: const Key('enableVoice'),
                          onPressed: () {
                            showDialog<int>(
                              context: context,
                              builder: (final BuildContext context) =>
                                MobileDialog(
                                  userProvider: userProvider,
                                  userApi: auth0UserApi,
                                  channel: 'voice',
                                  authMethods: authenticators
                                )
                            ).then((final value) {
                              if (value != null && value == HttpStatus.ok){
                                _triggerAuthMethods();
                              }
                            });
                          },
                          child: const Text('Enable', semanticsLabel: 'Enable voice authentication')
                        )
                      ]
                    ),
                const SizedBox(height: 20),
                _connectedServices.isEmpty ?
                const Text('No connected services')
                    :
                Semantics(
                    header: true,
                    child: const Text(
                        'Your connected services',
                        textAlign: TextAlign.left,
                        style: headerStyle
                    )
                ),
                ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(0),
                    itemCount: _connectedServices.length,
                    itemBuilder: (final BuildContext context, final int index) {
                      final service = _connectedServices[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.all(0),
                        leading: service.icon.isNotEmpty ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(
                            semanticLabel: '${service.name} logo',
                            service.icon,
                            width: 50,
                            height: 50,
                            errorBuilder: (context, exception, stackTrace) => const SizedBox.shrink(),
                          ),
                        ) : null,
                        title: Text(service.name),
                        subtitle: Text(service.scope),
                        trailing: TextButton(
                            // key: Key('disconnect_${service.grantId}'),
                            onPressed: () =>
                                showDialog<int>(
                                    context: context,
                                    builder: (final BuildContext context) =>
                                        AlertDialog(
                                          title: Text(
                                              'Revoke consent for ${service
                                                  .name}?'),
                                          content: Container(
                                              width: MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width * 0.4,
                                              child: SingleChildScrollView(
                                                  child: ListBody(
                                                    children: <Widget>[
                                                      // ignore: avoid_escaping_inner_quotes
                                                      // ignore: lines_longer_than_80_chars
                                                      Text(
                                                          'Your Angeleno Account information will no longer be shared with ${service
                                                              .name}.',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight
                                                                  .bold)),
                                                      const SizedBox(
                                                          height: 10),
                                                      // ignore: lines_longer_than_80_chars
                                                      Text(
                                                          'The information you already shared with ${service
                                                              .name} will not be deleted. If you want to delete the information you shared with ${service
                                                              .name}, you will need to contact ${service
                                                              .name}.'),
                                                      const SizedBox(
                                                          height: 10),
                                                      // ignore: lines_longer_than_80_chars
                                                      Text('To access ${service
                                                          .name} again in the future, you will need to give your consent to share your Angeleno Account information again. You can give consent again by going to the ${service
                                                          .name} site and logging in.')
                                                    ],
                                                  )
                                              )
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Ok'),
                                              onPressed: () {
                                                removeConnection(service.id);
                                                print('Not implemented');
                                              },
                                            )
                                          ],
                                        )
                                ),
                            child: const Text('Disconnect')
                        ),
                      );
                    }
                    )
                  ],
                )
            )
        )
            :
        const LinearProgressIndicator()
    );
  }


}
