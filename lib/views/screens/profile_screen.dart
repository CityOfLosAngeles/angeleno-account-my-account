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

import 'package:angeleno_project/models/autofill_place.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:angeleno_project/controllers/place_api.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:uuid/uuid.dart';

class ProfileScreen extends StatefulWidget {
  final Auth0UserApi auth0UserApi;

  const ProfileScreen({required this.auth0UserApi, super.key});

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
  final isNotTestMode =
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  //TextEditingController usrFNameTextController = TextEditingController();
  //TextEditingController usrLNameTextController = TextEditingController();
  TextEditingController usrAddressTextController = TextEditingController();
  TextEditingController usr2ndAddressTextController = TextEditingController();
  TextEditingController usrCityTextController = TextEditingController();
  TextEditingController usrStateTextController = TextEditingController();
  TextEditingController usrZipTextController = TextEditingController();
  //TextEditingController usrPhoneTextController = TextEditingController();

  bool canceledEditing = false;
  String sessionToken = "";
  //This is needed since the user becomes overwritten to original user data. But if we check the autofill
  bool autoFilled = false;
  List<AutofillSuggestion> suggestions = [];
  late PlaceAPI apiClient;

  @override
  void initState() {
    super.initState();

    auth0UserApi = widget.auth0UserApi;
    sessionToken = Uuid().v4(); //Create token for the session
    apiClient = PlaceAPI(sessionToken);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            width: 280.0,
            content: Text(success ? 'User updated' : 'User update failed'),
            action: success
                ? null
                : SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      updateUser();
                    })));
      });
    }
  }

  Future<List<AutofillSuggestion>> fetchSuggestions(final String input) async {
    // Implement API call to fetch suggestions based on input
    apiClient.count++;
    return await apiClient.fetchSuggestions(
        input, Localizations.localeOf(context).languageCode);
  }

  Future<void> onSuggestionSelected(final AutofillSuggestion sugg) async {
    print('We are in onSuggestionSelected with suggestion: ${sugg.toString()}');
    autoFilled = true;
    AutofillPlace place = AutofillPlace();
    try {
      usrAddressTextController.clear();
      usrAddressTextController.text = sugg.streetAddress!;
      place = await PlaceAPI(sessionToken).getPlaceDetailFromId(sugg.placeId!);
    } catch (e) {
      print('The autofillPlace error is $e');
    }

    try {
      user.city = place.city;
      user.zip = place.zipCode;
      user.state = place.state;
      user.address = sugg.streetAddress;
      //user.address2 =
      usrCityTextController.text = place.city!;
      usrStateTextController.text = place.state!;
      usrZipTextController.text = place.zipCode!;
    } catch (e) {
      print('The error is $e');
    }

//We need this for the Autofill to become active after selecting and saving as the issue made the suggestion keep re-apperaring
    Future.delayed(const Duration(milliseconds: 1234), () {
      setState(() {
        autoFilled = false;
        apiClient.count = 0;
      });
    });
  }

  InputDecoration inputDecoration(final String label, final bool editMode) =>
      InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: editMode ? null : disabledColor),
      );

  TextStyle textStyle(final bool editMode) =>
      TextStyle(color: editMode ? null : disabledColor);

  @override
  void dispose() {
    //usrFNameTextController.dispose();
    //usrLNameTextController.dispose();
    // usrPhoneTextController.dispose();
    usrAddressTextController.dispose();
    usrCityTextController.dispose();
    usrStateTextController.dispose();
    usrZipTextController.dispose();
    usr2ndAddressTextController.dispose();
    super.dispose();
  }

  void loadAddress() {
    print('Loading Address');
    try {
      usrAddressTextController.text = user.address!;
      usr2ndAddressTextController.text = user.address2!;
      usrCityTextController.text = user.city!;
      usrStateTextController.text = user.state!;
      usrZipTextController.text = user.zip!;
    } catch (e) {
      print('The error of loading address is $e');
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    overlayProvider = context.watch<OverlayProvider>();
    userProvider = context.watch<UserProvider>();
    loadUser();
  }

  void loadUser() {
    if (userProvider.user == null) {
      //return const LinearProgressIndicator();
      print('user is null');
    } else {
      user = userProvider.user!;
      if (!autoFilled) {
        loadAddress();
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    /*else {
      user = userProvider.user!;
      //loadAddress();
    }*/

    final editMode = userProvider.isEditing;

    if (formKey.currentState != null) {
      isFormValid = formKey.currentState!.validate();
    }

    if (userProvider.user == null) {
      return const LinearProgressIndicator();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                              const SizedBox(height: 10.0),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: (editMode &&
                                              ((user.phone!.isNotEmpty &&
                                                      !validPhoneNumber) ||
                                                  !isFormValid) &&
                                              isNotTestMode)
                                          ? null
                                          : () {
                                              if (editMode) {
                                                updateUser();
                                              }
                                              setState(() {
                                                userProvider.toggleEditing();
                                              });
                                            },
                                      child: Text(editMode ? 'Save' : 'Edit'),
                                    )
                                  ]),
                              const SizedBox(height: 25.0),
                              TextFormField(
                                enabled: editMode,
                                decoration:
                                    inputDecoration('First Name', editMode),
                                style: textStyle(editMode),
                                initialValue: user.firstName,
                                maxLength: 300,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                keyboardType: TextInputType.name,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                                decoration:
                                    inputDecoration('Last Name', editMode),
                                style: textStyle(editMode),
                                initialValue: user.lastName,
                                maxLength: 150,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                keyboardType: TextInputType.name,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                                autoValidateMode: isNotTestMode
                                    ? AutovalidateMode.onUserInteraction
                                    : AutovalidateMode.disabled,
                                selectorTextStyle:
                                    const TextStyle(color: Colors.black),
                                initialValue: PhoneNumber(
                                    phoneNumber: user.phone, isoCode: 'US'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        signed: true, decimal: true),
                                ignoreBlank: true,
                                inputBorder: const OutlineInputBorder(),
                              ),
                              const SizedBox(height: 25.0),
                              /*
                              TextFormField(
                                enabled: editMode,
                                decoration:
                                    inputDecoration('Address', editMode),
                                style: textStyle(editMode),
                                keyboardType: TextInputType.streetAddress,
                                initialValue: user.address,
                                onChanged: (final val) {
                                  user.address = val;
                                },
                              ),*/

                              TypeAheadField<AutofillSuggestion>(
                                  key: const Key('AutofillWidget'),
                                  controller: usrAddressTextController,
                                  // suggestionsCallback: (search) => CityService.of(context).find(search),
                                  debounceDuration:
                                      const Duration(milliseconds: 555),
                                  hideOnEmpty: true,
                                  hideOnLoading: true,
                                  suggestionsCallback: (search) async {
                                    //At initial, if the widget is called, it show suggestions but we should avoid at ommit, so...
                                    bool isInitial = user.address ==
                                        usrAddressTextController.text;
                                    try {
                                      if (search.isEmpty ||
                                          autoFilled ||
                                          isInitial ||
                                          search.trim().length < 1) {
                                        // print('Show nothing');
                                        return [];
                                      } else {
                                        final cities =
                                            await fetchSuggestions(search);
                                        //print('Show cities');
                                        return cities;
                                      }
                                    } catch (error) {
                                      // Handle errors here
                                      print(error);
                                      return []; // Return an empty list in case of errors
                                    }
                                  },
                                  builder: (context, controller, focusNode) =>
                                      TextField(
                                        enabled: userProvider.isEditing,
                                        controller: controller,
                                        focusNode: focusNode,
                                        //autofocus: false,
                                        decoration: InputDecoration(
                                            suffixIcon: IconButton(
                                              icon: Icon(Icons.clear),
                                              onPressed: () {
                                                usrAddressTextController
                                                    .clear();
                                              },
                                            ),
                                            labelText: 'Address',
                                            border: OutlineInputBorder()),
                                      ),
                                  itemBuilder: (context, address) => ListTile(
                                        title: Text(address.description!),
                                        subtitle: Text(address.streetAddress!),
                                      ),
                                  onSelected: onSuggestionSelected),
                              const SizedBox(height: 25.0),
                              TextFormField(
                                enabled: editMode,
                                controller: usr2ndAddressTextController,
                                decoration:
                                    inputDecoration('Address 2', editMode),
                                style: textStyle(editMode),
                                keyboardType: TextInputType.streetAddress,
                                //initialValue: user.address2,
                                onChanged: (final val) {
                                  user.address2 = val;
                                },
                              ),
                              const SizedBox(height: 25.0),
                              TextFormField(
                                enabled: editMode,
                                controller: usrCityTextController,
                                decoration: inputDecoration('City', editMode),
                                style: textStyle(editMode),
                                keyboardType: TextInputType.streetAddress,
                                //initialValue: user.city,
                                onChanged: (final val) {
                                  user.city = val;
                                },
                              ),
                              const SizedBox(height: 25.0),
                              TextFormField(
                                enabled: editMode,
                                controller: usrStateTextController,
                                decoration: inputDecoration('State', editMode),
                                style: textStyle(editMode),
                                keyboardType: TextInputType.streetAddress,
                                //initialValue: user.state,
                                onChanged: (final val) {
                                  user.state = val;
                                },
                              ),
                              const SizedBox(height: 25.0),
                              TextFormField(
                                enabled: editMode,
                                controller: usrZipTextController,
                                decoration: inputDecoration('Zip', editMode),
                                style: textStyle(editMode),
                                //initialValue: user.zip,
                                onChanged: (final val) {
                                  user.zip = val;
                                },
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          )))))
        ],
      );
    }
  }
}
