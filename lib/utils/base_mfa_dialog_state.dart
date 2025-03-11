import 'package:angeleno_project/models/mfa_method.dart';
import 'package:angeleno_project/utils/error_message.dart';
import 'package:flutter/material.dart';

import 'constants.dart';

abstract class BaseDialogState<T extends StatefulWidget> extends State<T> {
  final passwordField = TextEditingController();
  List<Widget> get dialogNext => [];
  Widget get dialogBody;
  int pageIndex = 0;
  String errorMessage = '';
  bool obscurePassword = true;
  bool inFlightRequest = false;

  late bool _isSmallScreen;
  List<MfaMethod> authenticators = [];
  late String mfaToken = '';
  late String oobCode = '';
  late String mfaCode = '';
  bool requireAdditionalAuthentication = false;

  @override
  void initState() {
    super.initState();
    passwordField.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    passwordField.dispose();
    super.dispose();
  }

  Widget get dialogClose => IconButton(
    alignment: Alignment.centerLeft,
    onPressed: () {
      Navigator.pop(context);
    },
    icon: const Icon(Icons.close),
  );

  Widget get dialogBack => TextButton(
    onPressed: () {
      setState(() {
        pageIndex -= 1;
        inFlightRequest = false;
      });
    },
    child: const Text('Back'),
  );

  void navigateToNextPage({final int increment = 1}) {
    if (pageIndex <= 4) {
      setState(() {
        pageIndex += increment;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget passwordPrompt(final String promptText, final VoidCallback onSubmit) => modalBody(
    Align(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            promptText,
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          const SizedBox(height: 15),
          SizedBox(
            key: const Key('passwordField'),
            width: 250,
            child: TextFormField(
              autofocus: true,
              controller: passwordField,
              onFieldSubmitted: (final value) {
                onSubmit();
              },
              obscureText: obscurePassword,
              enableSuggestions: false,
              autocorrect: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (final value) {
                if (value == null || value.trim().isEmpty) {
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
                      obscurePassword ? Icons.visibility : Icons.visibility_off
                  ),
                )
              ),
            ),
          ),
          const SizedBox(height: 15),
          if (errorMessage.isNotEmpty)
            ErrorMessage(message: errorMessage)
        ],
      ),
    )
  );

  Widget modalBody(final Widget body) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      dialogClose,
      _isSmallScreen ? Expanded(child: body) : body,
      if (_isSmallScreen)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: pageIndex == 0 ? [dialogNext[pageIndex]] : [dialogBack, dialogNext[pageIndex]],
        ),
    ],
  );
  
  @override
  Widget build(final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < smallScreen;

    _isSmallScreen = isSmallScreen;

    return isSmallScreen
        ?
        Dialog.fullscreen(child: dialogBody)
        :
        AlertDialog(
          content: dialogBody,
          actionsAlignment: MainAxisAlignment.end,
          actions: pageIndex == 0 ? [dialogNext[pageIndex]] : [dialogBack, dialogNext[pageIndex]],

        );
  }
}