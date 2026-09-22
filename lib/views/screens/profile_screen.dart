import 'dart:io';

import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/overlay_provider.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware, DatadogRouteAwareMixin{

  @override
  RumViewInfo get rumViewInfo => RumViewInfo(name: 'Profile Screen');

  final TextEditingController _phoneController = TextEditingController();
  ValueNotifier<bool> validPhoneNumberNotifier = ValueNotifier<bool>(true);
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late Auth0UserApi auth0UserApi;
  late OverlayProvider overlayProvider;
  late UserProvider userProvider;
  late User user;
  late PhoneNumber _initialPhone;

  String? ISOCode;
  String? dialCode;

  bool validPhoneNumber = false;
  final isNotTestMode =
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  bool get _namesValid {
    final first = user.firstName ?? '';
    final last = user.lastName ?? '';
    if (first.trim().isEmpty || last.trim().isEmpty) {
      return false;
    }
    return nameRegEx.hasMatch(first) && nameRegEx.hasMatch(last);
  }

  @override
  void initState() {
    super.initState();
    _initialPhone = PhoneNumber(isoCode: 'US');
    final initialPhone = context.read<UserProvider>().user?.phone ?? '';
    _resolveIsoCode(initialPhone);
  }

  Future<void> _resolveIsoCode(final String phone) async {
    try {
      if (phone.isNotEmpty) {
        final PhoneNumber number =
        await PhoneNumber.getRegionInfoFromPhoneNumber(phone);
        if (!mounted) return;

        final newIso = number.isoCode;
        final newDial = number.dialCode;
        final iso = newIso ?? ISOCode;
        final dial = newDial ?? dialCode;

        if (iso != ISOCode || dial != dialCode) {
        setState(() {
          ISOCode = iso;
          dialCode = dial;
          _initialPhone = number;
        });
        }
      } else {
        if (ISOCode != 'US' || dialCode != '+1') {
          setState(() {
            ISOCode = 'US';
            dialCode = '+1';
            _initialPhone = PhoneNumber(isoCode: 'US');
          });
        }
      }

    } catch (_) {
      print('Failed to resolve ISO code for phone number: $phone');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    overlayProvider = context.watch<OverlayProvider>();
    userProvider = context.watch<UserProvider>();
    auth0UserApi = Auth0UserApi(userProvider);
  }

  Future<void> updateUser() async {
    // Only submit patch if data has been updated
    if (!(user == userProvider.cleanUser)) {
      overlayProvider.showLoading();
      final response = await auth0UserApi.updateUser(user);
      if (!mounted) return;
      final success = response == HttpStatus.ok;
      overlayProvider.hideLoading();
      if (success) {
        userProvider.setCleanUser(user);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 280.0,
          content: Text(success ? 'User updated' : 'User update failed'),
          action: success ? null : SnackBarAction(
              label: 'Retry',
              onPressed: () {
                updateUser();
              }
            )
          )
      );
    }
  }

  InputDecoration inputDecoration(final String label, final bool editMode) =>
      InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        // labelStyle: TextStyle(color: editMode ? null : Theme.of(context).colorScheme.onSurfaceVariant),
      );

  TextStyle textStyle(final bool editMode) =>
      TextStyle(color: editMode ? null : Theme.of(context).colorScheme.onSurfaceVariant);

  @override
  Widget build(final BuildContext context) {
    if (userProvider.user != null) {
      user = userProvider.user!;
    }

    final editMode = userProvider.isEditing;

    return Scaffold(
        body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'Profile',
                textAlign: TextAlign.left,
                style: headerStyle
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: !editMode ?
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      userProvider.toggleEditing();
                    });
                  },
                  child: const Text('Edit'),
                )
                :
                ValueListenableBuilder<bool>(
                  valueListenable: validPhoneNumberNotifier,
                  builder: (final context, final valid, final child) {
                    final phoneOk = user.phone!.isEmpty || valid;
                    final canSave = _namesValid && phoneOk;
                    return  FilledButton(
                      onPressed: (!canSave && isNotTestMode)
                          ? null : () {
                        if (editMode) {
                          updateUser();
                        }
                        setState(() {
                          userProvider.toggleEditing();
                        });
                      },
                      child: const Text('Save'),
                    );
                  }
                )
            )
          ]
        ),
        Expanded(
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: Form(
                        key: formKey,
                        onChanged: () {
                          formKey.currentState!.save();
                        },
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          children: [
                            const SizedBox(height: 25.0),
                            TextFormField(
                              enabled: editMode,
                              decoration: inputDecoration('First name (required)', editMode),
                              style: textStyle(editMode),
                              initialValue: user.firstName,
                              maxLength: 300,
                              maxLengthEnforcement: MaxLengthEnforcement.enforced,
                              keyboardType: TextInputType.name,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (final val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter a first name';
                                }

                                if (!nameRegEx.hasMatch(val)) {
                                  return 'Invalid characters in first name';
                                }

                                return null;
                              },
                              onChanged: (final val) {
                                setState(() {
                                  user.firstName = val;
                                });
                              },
                            ),
                            const SizedBox(height: 25.0),
                            TextFormField(
                              enabled: editMode,
                              decoration: inputDecoration('Last name (required)', editMode),
                              style: textStyle(editMode),
                              initialValue: user.lastName,
                              maxLength: 150,
                              maxLengthEnforcement: MaxLengthEnforcement.enforced,
                              keyboardType: TextInputType.name,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (final val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter a last name';
                                }

                                if (!nameRegEx.hasMatch(val)) {
                                  return 'Invalid characters in last name';
                                }

                                return null;
                              },
                              onChanged: (final val) {
                                setState(() {
                                  user.lastName = val;
                                });
                              },
                            ),
                            const SizedBox(height: 25.0),
                            InternationalPhoneNumberInput(
                              key: Key('phoneField-${ISOCode ?? ''}-${dialCode ?? ''}'),
                              selectorConfig: const SelectorConfig(
                                selectorType: PhoneInputSelectorType.DIALOG,
                                setSelectorButtonAsPrefixIcon: true,
                                leadingPadding: 20.0,
                              ),
                              isEnabled: editMode,
                              onInputChanged: (final PhoneNumber number) {
                                if (number.parseNumber().isNotEmpty) {
                                  user.phone = number.phoneNumber!;
                                } else {
                                  user.phone = '';
                                  if (!validPhoneNumberNotifier.value) {
                                    validPhoneNumberNotifier.value = true;
                                  }
                                }
                              },
                              onInputValidated: (final bool value) {
                                if (user.phone!.isEmpty) {
                                  if (!validPhoneNumberNotifier.value) {
                                    validPhoneNumberNotifier.value = true;
                                  }
                                } else if (validPhoneNumberNotifier.value != value) {
                                  validPhoneNumberNotifier.value = value;
                                }
                              },
                              autoValidateMode: isNotTestMode ?
                                AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                              textFieldController: _phoneController,
                              initialValue: _initialPhone,
                              keyboardType: const TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true
                              ),
                              ignoreBlank: true,
                              inputBorder: const OutlineInputBorder(),
                            ),
                            const SizedBox(height: 25.0),
                            TextFormField(
                              enabled: editMode,
                              decoration: inputDecoration('Address', editMode),
                              style: textStyle(editMode),
                              keyboardType: TextInputType.streetAddress,
                              initialValue: user.address,
                              onChanged: (final val) {
                                user.address = val;
                              },
                            ),
                            const SizedBox(height: 25.0),
                            TextFormField(
                              enabled: editMode,
                              decoration: inputDecoration('Address 2', editMode),
                              style: textStyle(editMode),
                              keyboardType: TextInputType.streetAddress,
                              initialValue: user.address2,
                              onChanged: (final val) {
                                user.address2 = val;
                              },
                            ),
                            const SizedBox(height: 25.0),
                            TextFormField(
                              enabled: editMode,
                              decoration: inputDecoration('City', editMode),
                              style: textStyle(editMode),
                              keyboardType: TextInputType.streetAddress,
                              initialValue: user.city,
                              onChanged: (final val) {
                                user.city = val;
                              },
                            ),
                            const SizedBox(height: 25.0),
                            TextFormField(
                              enabled: editMode,
                              decoration: inputDecoration('State', editMode),
                              style: textStyle(editMode),
                              keyboardType: TextInputType.streetAddress,
                              initialValue: user.state,
                              onChanged: (final val) {
                                user.state = val;
                              },
                            ),
                            const SizedBox(height: 25.0),
                            TextFormField(
                              enabled: editMode,
                              decoration: inputDecoration('Zip', editMode),
                              style: textStyle(editMode),
                              initialValue: user.zip,
                              onChanged: (final val) {
                                user.zip = val;
                              },
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        )
                    )
                )
            )
          )
        ],
      )
    );
  }
}
