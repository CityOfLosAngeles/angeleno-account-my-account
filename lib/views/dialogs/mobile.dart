import 'dart:io';
import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../controllers/user_provider.dart';
import '../../utils/BaseMFADialogState.dart';
import '../../utils/constants.dart';

class MobileDialog extends StatefulWidget {
  final UserProvider userProvider;
  final Auth0UserApi userApi;
  final String channel;

  const MobileDialog({
    required this.userProvider,
    required this.userApi,
    required this.channel,
    super.key
  });

  @override
  State<MobileDialog> createState() => _MobileDialogState();
}

class _MobileDialogState extends BaseDialogState<MobileDialog> {

  final passwordField = TextEditingController();
  final phoneField = TextEditingController();

  late UserProvider userProvider;
  late Auth0UserApi api;
  late String channel;

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

    passwordField.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    passwordField.dispose();
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
        TextButton(
          onPressed: codeProvided.isEmpty ? null : () {
           confirmCode();
          },
          child: const Text('Continue')
        )
      ];

  void enrollMobile() async {
    setState(() {
      errMsg = '';
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
      'number': phoneNumber
    };

    api.enrollMFA(body).then((final response) {
      final bool success = response['status'] == HttpStatus.ok;
      if (success) {
        oobCode = response['oobCode'] as String;
        mfaToken = response['token'] as String;
        navigateToNextPage();
      } else {
        setState(() {
          errMsg = (response['body'] ?? 'An error occurred') as String;
          inFlightRequest = false;
        });
      }
    });
  }

  void confirmCode() async {
    setState(() {
      errMsg = '';
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

  Widget get passwordPrompt =>
      modalBody(
          Align(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                const Text(
                  'Please enter your password:',
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    key: const Key('passwordField'),
                    autofocus: true,
                    controller: passwordField,
                    obscureText: obscurePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    onFieldSubmitted: (final value) {
                      enrollMobile();
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (final value) {
                      if (value == null || value
                          .trim()
                          .isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        key: const Key('toggle_password'),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                            obscurePassword ? Icons.visibility : Icons
                                .visibility_off
                        ),
                      )
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                if (errMsg.isNotEmpty)
                  Text(errMsg, style: TextStyle(color: Theme.of(context).colorScheme.error))
              ],
            ),
          )
      );

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
            if (errMsg.isNotEmpty)
              Text(errMsg, style: TextStyle(color: Theme.of(context).colorScheme.error))
          ],
        ),
      ));

  List<Widget> get screens =>
      [
        phonePrompt,
        passwordPrompt,
        codeScreen
      ];

  @override
  Widget get dialogBody =>
      Container(
        padding: const EdgeInsets.all(20),
        child: screens[pageIndex],
      );
}