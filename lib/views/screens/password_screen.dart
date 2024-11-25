import 'dart:io';

import 'package:angeleno_project/models/password_reset.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/overlay_provider.dart';
import '../../controllers/user_provider.dart';

class PasswordScreen extends StatefulWidget {
  final Auth0UserApi auth0UserApi;

  const PasswordScreen({
    required this.auth0UserApi,
    super.key
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  late OverlayProvider overlayProvider;
  late UserProvider userProvider;
  late Auth0UserApi auth0UserApi;

  final minPasswordLength = 12;

  String currentPassword = '';
  String newPassword = '';
  String passwordMatch = '';

  bool viewPassword = false;
  bool viewNewPassword = false;
  bool viewPasswordMatch = false;

  late bool _isButtonDisabled = true;

  late bool acceptableLength = false;

  late String errorMsg = '';

  @override
  void initState() {
    super.initState();
    auth0UserApi = widget.auth0UserApi;
  }

  void submitRequest() {
    if (newPassword == passwordMatch) {

      setState(() {
        errorMsg = '';
      });

      overlayProvider.showLoading();

      final body = PasswordBody(
        email: userProvider.user!.email,
        oldPassword: currentPassword,
        newPassword: newPassword,
        userId: userProvider.user!.userId
      );

      auth0UserApi.updatePassword(body).then((final response) {
        final success = response['status'] == HttpStatus.ok;
        overlayProvider.hideLoading();
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(
            behavior: SnackBarBehavior.floating,
            width: 280.0,
            content: Text(success ? 'Password updated. Logging out...'
                : 'Password update failed')
        ));

        if (!success) {
          setState(() {
            errorMsg = response['body'].toString();
          });
        } else {
          Future.delayed(const Duration(seconds: 3), () {
            userProvider.logout();
          });
        }
      });

    }
  }

  bool enablePasswordSubmit() => !(currentPassword.trim() != ''
      && newPassword.trim() != '' && passwordMatch.trim() != ''
      && acceptableLength && passwordMatch == newPassword);

  @override
  Widget build(final BuildContext context) {
    overlayProvider = context.watch<OverlayProvider>();
    userProvider = context.watch<UserProvider>();

    return ListView(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Semantics(
                header: true,
                child: const Text(
                    'Password Reset',
                    textAlign: TextAlign.left,
                    style: headerStyle
                )
            )
        ),
        TextFormField(
          obscureText: !viewPassword,
          autocorrect: false,
          key: const Key('old_password'),
          enableSuggestions: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (final value) {
            if (value == null || value.trim().isEmpty) {
              return 'Password is required';
            }
            return null;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Current Password',
            suffixIcon: IconButton(
              key: const Key('toggle_old_password'),
              onPressed: () {
                setState(() {
                  viewPassword = !viewPassword;
                });
              },
              icon: Icon(
                viewPassword ? Icons.visibility_off : Icons.visibility
              )
            )
          ),
          onChanged: (final value) {
            setState(() {
              currentPassword = value;
              _isButtonDisabled = enablePasswordSubmit();
            });
          },
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          obscureText: !viewNewPassword,
          autocorrect: false,
          key: const Key('new_password'),
          enableSuggestions: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (final value) {
            if (value == null || value.trim().isEmpty) {
              return 'Password is required';
            }

            if (value.length < minPasswordLength) {
              // ignore: avoid_escaping_inner_quotes
              return 'Password doesn\'t meet requirements';
            }

            return null;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'New Password',
            suffixIcon: IconButton(
              key: const Key('toggle_new_password'),
              onPressed: () {
                setState(() {
                  viewNewPassword = !viewNewPassword;
                });
              },
              icon: Icon(
                viewNewPassword ? Icons.visibility_off : Icons.visibility
              )
            )
          ),
          onChanged: (final value) {
            setState(() {
              newPassword = value;
              _isButtonDisabled = enablePasswordSubmit();
              acceptableLength = value.length >= minPasswordLength;
            });
          },
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Text('Password must:',
              style: TextStyle(fontWeight: FontWeight.bold)
            ),
            const SizedBox(width: 10),
            Text(
              'Be at least $minPasswordLength characters',
              style: TextStyle(
              color: acceptableLength
                ? colorScheme.primary
                : colorScheme.error
              )
            )
          ],
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          obscureText: !viewPasswordMatch,
          autocorrect: false,
          key: const Key('match_password'),
          enableSuggestions: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (final value) {
            if (value == null || value.trim().isEmpty) {
              return 'Password is required';
            }
            if (newPassword != value) {
              return "Passwords don't match";
            }
            return null;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Confirm New Password',
            suffixIcon: IconButton(
              key: const Key('toggle_match_password'),
              onPressed: () {
                setState(() {
                  viewPasswordMatch = !viewPasswordMatch;
                });
              },
              icon: Icon(
                viewPasswordMatch ? Icons.visibility_off : Icons.visibility
              )
            )
          ),
          onChanged: (final value) {
            setState(() {
              passwordMatch = value;
              _isButtonDisabled = enablePasswordSubmit();
            });
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMsg.isNotEmpty)
              Text(errorMsg, style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: _isButtonDisabled ? null : () => submitRequest(),
              child: const Text('Update Password and Logout'),
            )
          ],
        ),
      ],
    );
  }
}