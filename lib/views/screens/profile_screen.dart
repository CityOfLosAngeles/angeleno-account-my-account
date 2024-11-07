import 'dart:io';

import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/overlay_provider.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final Auth0UserApi auth0UserApi;

  const ProfileScreen({
    required this.auth0UserApi,
    super.key
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late Auth0UserApi auth0UserApi;
  late OverlayProvider overlayProvider;
  late UserProvider userProvider;
  late User user;
  late bool isFormValid;
  bool validPhoneNumber = false;
  final isNotTestMode = kIsWeb ||
      !Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();

    auth0UserApi = widget.auth0UserApi;
  }

  void updateUser() {
    // Only submit patch if data has been updated
    if (!(user == userProvider.cleanUser)) {
      overlayProvider.showLoading();
      auth0UserApi.updateUser(user).then((final response) {
          final success = response == HttpStatus.ok;
          overlayProvider.hideLoading();
          if (success) {
            userProvider.setCleanUser(user);
          }
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(
              behavior: SnackBarBehavior.floating,
              width: 280.0,
              content: Text(success ? 'User updated' : 'User update failed'),
              action: success ? null : SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  updateUser();
                }
              )
          ));
      });
    }
  }

  InputDecoration inputDecoration (final String label, final bool editMode) =>
    InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      labelStyle: TextStyle(color: editMode ? null : disabledColor),
    );

  TextStyle textStyle (final bool editMode) =>
    TextStyle(color: editMode ? null : disabledColor);

  @override
  Widget build(final BuildContext context) {
    overlayProvider = context.watch<OverlayProvider>();
    userProvider = context.watch<UserProvider>();

    if (userProvider.user == null) {
      return const LinearProgressIndicator();
    } else {
      user = userProvider.user!;
    }

    final editMode = userProvider.isEditing;

    if (formKey.currentState != null) {
      isFormValid = formKey.currentState!.validate();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: (editMode &&
                    ((user.phone!.isNotEmpty && !validPhoneNumber) ||
                        !isFormValid) && isNotTestMode
                ) ? null : () {
                  if (editMode) {
                    updateUser();
                  }
                  setState(() {
                    userProvider.toggleEditing();
                  });
                },
                child: Text(
                    editMode ? 'Save' : 'Edit'
                ),
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
                          decoration: inputDecoration('First Name', editMode),
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
                          decoration: inputDecoration('Last Name', editMode),
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
                          selectorConfig: const SelectorConfig(
                            selectorType: PhoneInputSelectorType.DIALOG,
                            setSelectorButtonAsPrefixIcon: true,
                            leadingPadding: 20.0,
                          ),
                          isEnabled: editMode,
                          key: const Key('phoneField'),
                          onInputChanged: (final PhoneNumber number) {
                            if (number.parseNumber().isNotEmpty) {
                              user.phone = number.phoneNumber!;
                            } else {
                              user.phone = '';
                            }
                          },
                          onInputValidated: (final bool value) {
                            if (user.phone!.isEmpty) {
                              setState(() {
                                validPhoneNumber = true;
                              });
                            } else {
                              if (validPhoneNumber != value) {
                                setState(() {
                                  validPhoneNumber = value;
                                });
                              }
                            }
                          },
                          autoValidateMode: isNotTestMode ?
                          AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          selectorTextStyle: const TextStyle(color: Colors.black),
                          initialValue: PhoneNumber(phoneNumber: user.phone, isoCode: 'US'),
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
