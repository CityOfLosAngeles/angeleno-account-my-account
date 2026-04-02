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
  String methodBeingEnrolled = '';

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

  Widget get dialogClose => TextButton(
    onPressed: () {
      Navigator.pop(context);
    },
    child: const Text('Cancel'),
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

  void navigateToNextPage() {
    if (pageIndex <= dialogNext.length - 1) {
      setState(() {
        pageIndex += 1;
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

  List<Widget> get dialogActions {

    final actions = [
      dialogClose,
    ];

    if (pageIndex > 0) {
      actions.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dialogBack,
            dialogNext[pageIndex]
          ],
        )
      );
    } else {
      actions.add(dialogNext[pageIndex]);
    }

    return actions;
  }

  Widget modalBody(final Widget body) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_isSmallScreen) ...[
        Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enroll $methodBeingEnrolled',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 22
                  ),
                ),
                Expanded(
                  child: body,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: dialogActions
                )
              ],
            )
        )

      ] else ...[body]
    ],
  );
  
  @override
  Widget build(final BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < smallScreenWidthBreakpoint;

    _isSmallScreen = isSmallScreen;

    return isSmallScreen
        ?
        Dialog.fullscreen(child: Padding(padding: const EdgeInsets.all(20), child:dialogBody))
        :
        AlertDialog(
          title: Text('Enroll $methodBeingEnrolled'),
          content: dialogBody,
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: dialogActions

        );
  }
}