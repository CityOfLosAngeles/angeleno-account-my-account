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

  final isNotTestMode = kIsWeb ||
      !Platform.environment.containsKey('FLUTTER_TEST');

  PhoneNumber number = PhoneNumber(isoCode: 'US');
  String initialCountry = 'US';

  String phoneNumber = '';
  String mfaToken = '';
  String oobCode = '';
  String codeProvided = '';
  bool validPhoneNumber = false;

  @override
  void initState() {
    super.initState();

    userProvider = widget.userProvider;
    api = widget.userApi;
    channel = widget.channel;
    authMethods = widget.authMethods;
  }

  @override
  void dispose() {
    phoneField.dispose();
    super.dispose();
  }

  @override
  List<Widget> get dialogNext =>
      [
        TextButton(
          onPressed: !validPhoneNumber && isNotTestMode ? null : () {
            navigateToNextPage();
          },
          child: const Text('Continue'),
        ),
        TextButton(
          onPressed: passwordField.text.isEmpty ? null : () {
            enrollMobile();
          },
          child: const Text('Continue'),
        ),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        TextButton(
          onPressed: codeProvided.isEmpty ? null : () {
           confirmCode();
          },
          child: const Text('Continue')
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
        navigateToNextPage(increment: !requireAdditionalAuthentication ? 3 : 1);
      } else if (statusCode == HttpStatus.unauthorized) {
        requireAdditionalAuthentication = true;
        if (mfaToken.isEmpty) {
          mfaToken = mfaResponse.token;
        }
        navigateToNextPage();
      } else {
        setState(() {
          errorMessage = mfaResponse.errorMessage;
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

    api.confirmMFA(body).then((final response) {
      if (response.statusCode == HttpStatus.ok) {
        Navigator.pop(context, response.statusCode);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 280.0,
          content: Text('$channel MFA has been enabled.')
        ));
      }
      setState(() {
        inFlightRequest = false;
      });
    });
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
                selectorTextStyle: const TextStyle(color: Colors.black),
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
            const Text('Please enter the code received:'),
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
              Text(errorMessage, style: TextStyle(color: const ColorScheme.light().error))
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
          const Text('Select an authentication method:',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.black,
              fontSize: 16.0,
              fontWeight: FontWeight.normal
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 400,
            width: 400,
            child: ListView.builder(
              itemCount: authMethods.length,
              padding: const EdgeInsets.all(20),
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
                    navigateToNextPage();
                  },
                  child: Text(friendlyMfaMethodName),
                );
              }
            )
          ),
          const SizedBox(height: 15),
          if (errorMessage.isNotEmpty)
            ErrorMessage(message: errorMessage)
        ],
      )
    )
  );

  Widget get mfaAuthCodeScreen => modalBody(
    Align(
      child: Column(
        children: [
          const Text('Enter code provided:',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.black,
              fontSize: 16.0,
              fontWeight: FontWeight.normal
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 250,
            child: TextFormField(
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (final value) async {
                final Map<String, String> body = {
                  'mfaToken': mfaToken,
                  'oobCode': oobCode,
                  'bindingCode': mfaCode
                };

                final response = await api.requestMFAToken(body);

                setState(() {
                  mfaToken = jsonDecode(response.body)['access_token'] as String;
                });

                enrollMobile();

              },
              validator: (final value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Code is required';
                }
                return null;
              },
              onChanged: (final val) {
                setState(() {
                  oobCode = val;
                });
              },
            )
          ),
          const SizedBox(height: 15),
          if (errorMessage.isNotEmpty)
            Text(errorMessage, style: TextStyle(color: const ColorScheme.light().error))
        ],
      )
    )
  );

  List<Widget> get screens =>
      [
        phonePrompt,
        passwordPromptWidget,
        authenticatorList,
        mfaAuthCodeScreen,
        codeScreen
      ];

  @override
  Widget get dialogBody =>
      Container(
        padding: const EdgeInsets.all(20),
        child: screens[pageIndex],
      );
}