import 'dart:convert';
import 'dart:io';

import 'package:angeleno_project/utils/error_message.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/user_provider.dart';
import '../../models/mfa_method.dart';
import '../../models/mfa_response.dart';
import '../../utils/base_mfa_dialog_state.dart';

class AuthenticatorDialog extends StatefulWidget {
  final UserProvider userProvider;
  final Auth0UserApi auth0UserApi;
  final List<MfaMethod> authMethods;

  const AuthenticatorDialog({
    required this.userProvider,
    required this.auth0UserApi,
    required this.authMethods,
    super.key
  });

  @override
  State<AuthenticatorDialog> createState() => _AuthenticatorDialogState();
}

class _AuthenticatorDialogState extends BaseDialogState<AuthenticatorDialog> {

  late UserProvider userProvider;
  late Auth0UserApi auth0UserApi;
  late List<MfaMethod> authMethods;

  String authenticatorQrCode = '';
  String qrCodeAltString = '';
  String authenticatorCode = '';

  @override
  void initState() {
    super.initState();

    userProvider = widget.userProvider;
    auth0UserApi = widget.auth0UserApi;
    authMethods = widget.authMethods;

    setState(() {
      methodBeingEnrolled = 'Authenticator Application';
    });
  }

  @override
  List<Widget> get dialogNext => [
    OutlinedButton(
      onPressed: passwordField.text.isEmpty || inFlightRequest ? null : () {
        enrollAuthenticator();
      },
      child: const Text('Continue'),
    ),
    if (requireAdditionalAuthentication) ...[
    const SizedBox.shrink(),
    OutlinedButton(
      onPressed: inFlightRequest ? null : () {
        getMfaToken();
      },
      child: const Text('Continue'),
    )],
    OutlinedButton(
      onPressed: () {
        navigateToNextPage();
      },
      child: const Text('Continue'),
    ),
    FilledButton(
      onPressed: authenticatorCode.isEmpty || inFlightRequest ? null : () {
        confirmAuthenticator();
      },
      child: const Text('Finish'),
    )
  ];

  void enrollAuthenticator() async {

    setState(() {
      errorMessage = '';
      inFlightRequest = true;
    });

    if (passwordField.text.isEmpty) {
      return;
    }

    final Map<String, String> body = {
      'email': userProvider.user!.email,
      'password': passwordField.text,
      'mfaFactor': 'otp',
      'mfaToken': mfaToken
    };

    auth0UserApi.enrollMFA(body).then((final response) {
      final int statusCode = response['status'] as int;
      final mfaResponse = response['body'] as MfaResponse;

      if (statusCode == HttpStatus.ok) {
        authenticatorQrCode = mfaResponse.barcode;
        mfaToken = mfaResponse.token;
        qrCodeAltString = mfaResponse.barcodeString;
        inFlightRequest = false;

        navigateToNextPage();
      } else if (statusCode == HttpStatus.unauthorized) {
        requireAdditionalAuthentication = true;
        if (mfaToken.isEmpty) {
          mfaToken = mfaResponse.token;
          setState(() {
            inFlightRequest = false;
          });
        }
        navigateToNextPage();
      } else {
        // Covers edge case where user presses back button
        if (mfaResponse.errorMessage == 'User is already enrolled.') {
          navigateToNextPage();
        } else {
          setState(() {
            errorMessage = mfaResponse.errorMessage;
          });
        }
        setState(() {
          inFlightRequest = false;
        });
      }
    });
  }

  void confirmAuthenticator() async {

    setState(() {
      errorMessage = '';
      inFlightRequest = true;
    });

    if (authenticatorCode.isEmpty) {
      return;
    }

    final Map<String, String> body = {
      'mfaToken': mfaToken,
      'userOtpCode': authenticatorCode
    };

    final response = await auth0UserApi.confirmMFA(body);
    if (!mounted) return;
    if (response.statusCode == HttpStatus.ok) {
      Navigator.pop(context, response.statusCode);
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 280.0,
        content: Text('Authenticator app has been set up.')
      ));
    } else {
      setState(() {
        errorMessage = response.body;
      });
    }
    setState(() {
      inFlightRequest = false;
    });
  }

  void getMfaToken() async {
    final Map<String, String> body = {
      'mfaToken': mfaToken,
      'oobCode': oobCode,
      'bindingCode': mfaCode
    };

    final response = await auth0UserApi.requestMFAToken(body);

    if (response.statusCode == HttpStatus.ok) {
      mfaToken = jsonDecode(response.body)['access_token'] as String;
      enrollAuthenticator();
    } else {
      setState(() {
        errorMessage = response.body;
      });
    }

  }

  Widget get passwordPromptWidget => passwordPrompt(
    'Set up Multi-Factor Authentication (MFA). Continue MFA setup to add an additional layer of security when signing in to your account. \n\n Please enter your password:',
    enrollAuthenticator
  );

  Widget get qrCodeScreen =>  modalBody(
    Align(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Set up your authenticator by scanning code below:',
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 16.0,
              fontWeight: FontWeight.normal
            ),
          ),
        SizedBox(
            height: 150,
            width: 150,
            child: QrImageView(
              data: authenticatorQrCode,
              size: 150
            ),
          ),
          const SizedBox(height: 20),
          const Text('If unable to scan, please enter the code below:'),
          const SizedBox(height: 15),
          SelectableText(
            qrCodeAltString,
            style: const TextStyle(
              decoration: TextDecoration.none,
              fontSize: 14.0,
              fontWeight: FontWeight.normal
            )
          )
        ],
      ),
    ),
  );

  Widget get confirmationScreen => modalBody(
Align(
      child:  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Enter the code displayed from your application:',
              textAlign: TextAlign.center,
              softWrap: true
          ),
          SizedBox(
              width: 250,
              child: TextFormField(
                key: const Key('totpCode'),
                autofocus: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onFieldSubmitted: (final value) {
                  confirmAuthenticator();
                },
                validator: (final value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Code is required';
                  }
                  return null;
                },
                onChanged: (final val) {
                  setState(() {
                    authenticatorCode = val;
                  });
                },
              )
          ),
          const SizedBox(height: 15),
          if (errorMessage.isNotEmpty)
            ErrorMessage(message: errorMessage)
        ],
      )
    )
  );

  Widget get authenticatorList => modalBody(
    Align(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please select an authentication method to verify your request:',
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 16.0,
              fontWeight: FontWeight.normal
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 300,
            height: authMethods.length * 60,
            child: ListView.builder(
              itemCount: authMethods.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (final BuildContext context, final int index) {

                late final String friendlyMfaMethodName;
                final method = authMethods[index];

                if (method.authenticatorType == 'phone') {
                  if (method.oobChannel == 'sms') {
                    friendlyMfaMethodName = 'SMS Message to ${method.name}';
                  } else {
                    friendlyMfaMethodName = 'Voice Call to ${method.name}';
                  }
                } else {
                  friendlyMfaMethodName = 'Authenticator (TOTP) application';
                }

                return TextButton(
                  onPressed: () async {
                    final Map<String, String> body = {
                      'mfaToken': mfaToken,
                      'authenticatorId': 'oob'
                    };

                    final response = await auth0UserApi.challengeMFA(body);

                    if (response.statusCode == HttpStatus.ok) {
                      final jsonResponse = jsonDecode(response.body);
                      oobCode = jsonResponse['oob_code'] as String;
                      navigateToNextPage();
                    } else {
                      setState(() {
                        errorMessage = response.body;
                      });
                    }
                  },
                  child: Text(friendlyMfaMethodName),
                );
              }
            )
          )
        ],
      )
    )
  );

  Widget get mfaAuthCodeScreen => modalBody(
    Align(
      child: Column(
        children: [
          const Text('Enter the code sent to your phone:',
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 16.0,
              fontWeight: FontWeight.normal
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 250,
            child: TextFormField(
              key: const Key('additionalMfaCode'),
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (final value) => getMfaToken,
              validator: (final value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Code is required';
                }
                return null;
              },
              onChanged: (final val) {
                setState(() {
                  mfaCode = val;
                });
              },
            )
          ),
          const SizedBox(height: 15),
          if (errorMessage.isNotEmpty)
            ErrorMessage(message: errorMessage)
        ],
      )
    )
  );

  List<Widget> get screens => [
    passwordPromptWidget,
    if (requireAdditionalAuthentication) ...[
      authenticatorList,
      mfaAuthCodeScreen,
    ],
    qrCodeScreen,
    confirmationScreen
  ];

  @override
  Widget get dialogBody => Container(
    child: screens[pageIndex]
  );
}