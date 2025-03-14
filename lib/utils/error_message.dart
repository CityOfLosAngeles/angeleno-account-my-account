import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({this.message = 'An error occurred', super.key});

  @override
  Widget build(final BuildContext context) => Text(
      message,
      style: TextStyle(color: const ColorScheme.light().error),
    );
}