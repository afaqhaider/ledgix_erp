import 'package:flutter/material.dart';

class ERPStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ERPStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory ERPStatusBadge.fromStatus(String status) {
    Color color;
    String cleanStatus = status.toLowerCase();
    
    switch (cleanStatus) {
      case 'posted':
      case 'active':
      case 'paid':
      case 'approved':
        color = Colors.green;
        break;
      case 'draft':
      case 'pending':
        color = Colors.grey;
        break;
      case 'partiallypaid':
      case 'sent':
        color = Colors.blue;
        break;
      case 'voided':
      case 'cancelled':
      case 'rejected':
      case 'overdue':
        color = Colors.red;
        break;
      default:
        color = Colors.blueGrey;
    }

    return ERPStatusBadge(
      label: status.toUpperCase(),
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
