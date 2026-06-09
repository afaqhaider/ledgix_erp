import 'package:flutter/material.dart';

class DocumentNotes extends StatelessWidget {
  final String notes;
  final String label;

  const DocumentNotes({
    super.key,
    required this.notes,
    this.label = 'Notes & Terms',
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            notes,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
