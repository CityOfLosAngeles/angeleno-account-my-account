import 'package:flutter/material.dart';

class NavigationButton extends StatelessWidget {
  final Icon icon;
  final Text text;
  final VoidCallback onPressed;
  final bool isActive;

  const NavigationButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    required this.isActive,
  });

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: FilledButton.tonal(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            isActive ? null : Colors.transparent,
          ),
          shadowColor: WidgetStateProperty.all(
            isActive ? null : Colors.transparent,
          ),
        ),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 8.0),
              text,
            ],
          ),
        ),
      )
    ),
  );
}
