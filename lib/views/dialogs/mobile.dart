import 'dart:convert';
import 'dart:io';
import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../controllers/user_provider.dart';
import '../../models/mfa_method.dart';
import '../../models/mfa_response.dart';
import '../../utils/base_mfa_dialog_state.dart';
import '../../utils/error_message.dart';

class MobileDialog extends StatefulWidget {
  final UserProvider userProvider;
  final Auth0UserApi userApi;
  final String channel;
  final List<MfaMethod> authMethods;


  const MobileDialog({
    required this.userProvider,
    required this.userApi,
    required this.channel,
    required this.authMethods,
    super.key
  });

  @override
  State<MobileDialog> createState() => _MobileDialogState();
}

class _MobileDialogState extends BaseDialogState<MobileDialog> {

  final phoneField = TextEditingController();

  late UserProvider userProvider;
  late Auth0UserApi api;
  late String channel;
  late List<MfaMethod> authMethods;
  bool useAuthenticatorSecondFactor = false;

  final isNotTestMode = kIsWeb ||
      !Platform.environment.containsKey('FLUTTER_TEST');

  PhoneNumber number = PhoneNumber(isoCode: 'US');
  String initialCountry = 'US';

  String phoneNumber = '';
  String codeProvided = '';
  bool validPhoneNumber = false;

  @override
  void initState() {
    super.initState();

    userProvider = widget.userProvider;
    api = widget.userApi;
    channel = widget.channel;
    authMethods = widget.authMethods;

    setState(() {
      methodBeingEnrolled = widget.channel == 'sms' ? 'SMS' : 'Voice';
    });
  }

  @override
  void dispose() {
    phoneField.dispose();
    super.dispose();
  }

  @override
  List<Widget> get dialogNext =>
    [
      OutlinedButton(
        onPressed: !validPhoneNumber && isNotTestMode ? null : () {
          navigateToNextPage();
        },
        child: const Text('Continue'),
      ),
      OutlinedButton(
        onPressed: passwordField.text.isEmpty ? null : () {
          enrollMobile();
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
        ),
      ],
      FilledButton(
        onPressed: codeProvided.isEmpty ? null : () {
         confirmCode();
        },
        child: const Text('Finish')
      )
    ];

  void enrollMobile() async {
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
      'mfaFactor': 'oob',
      'channel': channel,
      'number': phoneNumber,
      'mfaToken': mfaToken
    };

    api.enrollMFA(body).then((final response) {
      final int statusCode = response['status'] as int;
      final mfaResponse = response['body'] as MfaResponse;

      if (statusCode == HttpStatus.ok) {
        oobCode = mfaResponse.oobCode;
        mfaToken = mfaResponse.token;
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

  void confirmCode() async {
    setState(() {
      errorMessage = '';
      inFlightRequest = true;
    });

    if (codeProvided.isEmpty) {
      return;
    }

    final Map<String, String> body = {
      'mfaToken': mfaToken,
      'oobCode': oobCode,
      'userOtpCode': codeProvided
    };

    final response = await api.confirmMFA(body);
    if (!mounted) return;

    if (response.statusCode == HttpStatus.ok) {
      Navigator.pop(context, response.statusCode);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 280.0,
        content: Text('$methodBeingEnrolled MFA has been enabled.')
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

    final response = await api.requestMFAToken(body);

    if (response.statusCode == HttpStatus.ok) {
      mfaToken = jsonDecode(response.body)['access_token'] as String;
      enrollMobile();
    } else {
      setState(() {
        errorMessage = response.body;
      });
    }

  }

  Widget get phonePrompt =>
    modalBody(Align(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Please enter your phone number:',
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 500,
            child: InternationalPhoneNumberInput(
              selectorConfig: const SelectorConfig(
                selectorType: PhoneInputSelectorType.DIALOG,
                setSelectorButtonAsPrefixIcon: true,
                leadingPadding: 20.0
              ),
              key: const Key('phoneField'),
              onInputChanged: (final PhoneNumber number) {
                phoneNumber = number.phoneNumber!;
              },
              onInputValidated: (final bool value) {
                setState(() {
                  validPhoneNumber = value;
                });
              },
              onFieldSubmitted: (final value) {
                navigateToNextPage();
              },
              autoFocus: true,
              autoValidateMode: isNotTestMode ?
                AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
              initialValue: number,
              textFieldController: phoneField,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true
              ),
              inputBorder: const OutlineInputBorder(),
            ),
          )
        ],
      ),
    ));

  Widget get codeScreen =>
    modalBody(Align(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Please enter the code sent to ${phoneField.text}:'),
          SizedBox(
            width: 250,
            child: TextFormField(
              key: const Key('phoneCode'),
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (final value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return 'Code is required';
                }
                return null;
              },
              onFieldSubmitted: (final value) {
                confirmCode();
              },
              onChanged: (final val) {
                setState(() {
                  codeProvided = val;
                });
              },
            ),
          ),
          const SizedBox(height: 15),
          if (errorMessage.isNotEmpty)
            ErrorMessage(message: errorMessage)
        ],
      ),
    ));

  Widget get passwordPromptWidget => passwordPrompt(
    'Please enter your password:',
    enrollMobile
  );

  Widget get authenticatorList => modalBody(
    Align(
      child: Column(
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
                    if (method.authenticatorType == 'totp') {
                      useAuthenticatorSecondFactor = true;
                      navigateToNextPage();
                      return;
                    } else {

                      final Map<String, String> body = {
                        'mfaToken': mfaToken,
                        'authenticatorId': 'oob',
                        'bindingCode': oobCode
                      };

                      final response = await api.challengeMFA(body);

                      if (response.statusCode == HttpStatus.ok) {
                        final jsonResponse = jsonDecode(response.body);
                        oobCode = jsonResponse['oob_code'] as String;
                        navigateToNextPage();
                      } else {
                        setState(() {
                          errorMessage = response.body;
                        });
                      }
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
          Text('Enter the code provided by your ${useAuthenticatorSecondFactor ? 'Authenticator' : 'Phone'}:',
            style: const TextStyle(
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
                  if (useAuthenticatorSecondFactor) {
                    oobCode = val;
                  } else {
                    mfaCode = val;
                  }
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
    phonePrompt,
    passwordPromptWidget,
    if (requireAdditionalAuthentication) ...[
      authenticatorList,
      mfaAuthCodeScreen,
    ],
    codeScreen
  ];

  @override
  Widget get dialogBody =>
      Container(
        padding: const EdgeInsets.all(20),
        child: screens[pageIndex],
      );
}
