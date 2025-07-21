import 'dart:io';
import 'dart:convert';

import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:angeleno_project/views/dialogs/mobile.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_provider.dart';
import '../../models/connected_applications_model.dart';
import '../../models/mfa_method.dart';
import '../dialogs/authenticator.dart';

class AdvancedSecurityScreen extends StatefulWidget {
  const AdvancedSecurityScreen({
    super.key
  });

  @override
  State<AdvancedSecurityScreen> createState() => _AdvancedSecurityState();
}

class _AdvancedSecurityState extends State<AdvancedSecurityScreen> with RouteAware, DatadogRouteAwareMixin {

  late DatadogNavigationObserver observer;

  RumViewInfo? infoExtractor(final Route<dynamic> route) => RumViewInfo(
    name: 'AdvancedSecurityScreen'
  );


  late Auth0UserApi auth0UserApi;
  late UserProvider userProvider;
  late Future<void> _authMethods;
  late List<Service> _connectedServices;

  bool authenticatorEnabled = false;
  bool smsEnabled = false;
  bool voiceEnabled = false;

  String totpAuthId = '';
  String smsAuthId = '';
  String voiceAuthId = '';

  List<MfaMethod> authenticators = [];

  @override
  void initState() {
    super.initState();

    auth0UserApi = Auth0UserApi();

    _triggerAuthMethods();

    observer = DatadogNavigationObserver(
      datadogSdk: DatadogSdk.instance,
      viewInfoExtractor: infoExtractor,
    );
  }

  void _triggerAuthMethods() {
    setState(() {
      _authMethods = getAuthenticationMethods();
    });
  }

  Future<void> getAuthenticationMethods() async {
    _connectedServices = [];
    authenticators = [];
    await auth0UserApi.getAuthenticationMethods(userProvider.user!.userId)
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
            )
            .toList();

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
                  authenticatorEnabled = true;
                  totpAuthId = methodId;
                  break;
                case 'phone':
                  mfaMethod.name = element['phone_number'] as String;
                  final prefMethod =
                    element['preferred_authentication_method'] as String;
                  if (prefMethod == 'sms') {
                    smsEnabled = true;
                    smsAuthId = methodId;
                    mfaMethod.oobChannel = 'sms';
                  } else {
                    voiceEnabled = true;
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

  @override
  Widget build(final BuildContext context) {
    userProvider = context.watch<UserProvider>();

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
                        authenticatorEnabled ?
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
                              setState(() {
                                authenticatorEnabled = false;
                              });
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
                          smsEnabled ?
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
                                setState(() {
                                  smsEnabled = false;
                                });
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
                          voiceEnabled ?
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
                                setState(() {
                                  voiceEnabled = false;
                                });
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
