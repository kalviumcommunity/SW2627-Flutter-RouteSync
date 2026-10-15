import 'package:flutter/material.dart';

class DeliveryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;
  const DeliveryActionButton({super.key, required this.label, required this.icon, required this.onPressed, this.busy = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon),
          label: Text(label),
        ),
      );
}