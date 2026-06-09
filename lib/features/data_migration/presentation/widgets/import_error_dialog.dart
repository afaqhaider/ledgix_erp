import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImportErrorDialog extends StatelessWidget {
  final String title;
  final String friendlyMessage;
  final String technicalDetails;

  const ImportErrorDialog({
    super.key,
    this.title = 'Import Failed',
    required this.friendlyMessage,
    required this.technicalDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              friendlyMessage,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text(
                'Show Details',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    technicalDetails,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: technicalDetails));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error details copied to clipboard'),
              ),
            );
          },
          child: const Text('Copy Error Details'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
