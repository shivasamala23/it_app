import 'package:flutter/material.dart';

class StageBadge extends StatelessWidget {
  final String stage;

  const StageBadge({Key? key, required this.stage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (stage) {
      case 'draft':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = 'Draft';
        break;
      case 'new':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'New';
        break;
      case 'in_progress':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'In Progress';
        break;
      case 'resolved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Resolved';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Cancelled';
        break;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = stage;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
