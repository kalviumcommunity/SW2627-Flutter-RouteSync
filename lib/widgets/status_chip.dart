import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final (background, foreground) = switch (normalized) {
      'DELIVERED' ||
      'RESOLVED' => (const Color(0xFFE5F5EC), const Color(0xFF18794E)),
      'FAILED' ||
      'CANCELLED' ||
      'REJECTED' => (const Color(0xFFFCE8E6), const Color(0xFFB3261E)),
      'IN_TRANSIT' ||
      'OUT_FOR_DELIVERY' ||
      'HIGH' ||
      'URGENT' => (const Color(0xFFE5F1F8), const Color(0xFF176B87)),
      'OPEN' ||
      'MEDIUM' ||
      'ASSIGNED' => (const Color(0xFFFFF3D6), const Color(0xFF8A5A00)),
      _ => (const Color(0xFFEDEFF2), const Color(0xFF545D68)),
    };
    final label = status
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
