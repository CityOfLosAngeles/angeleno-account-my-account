import 'dart:convert';

import 'package:angeleno_project/models/mfa_method.dart';
import 'package:flutter/material.dart';

import 'constants.dart';

abstract class BaseDialogState<T extends StatefulWidget> extends State<T> {
  
  List<Widget> get dialogNext => [];
  Widget get dialogBody;
  int pageIndex = 0;
  String errMsg = '';
  bool obscurePassword = true;
  bool inFlightRequest = false;

  late bool _isSmallScreen;
  List<MfaMethod> authenticators = [];
  late String mfaToken = '';
  late String oobCode = '';
  late String mfaCode = '';
  bool requireAdditionalAuthentication = false;

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