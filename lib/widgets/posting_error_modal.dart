import 'package:flutter/material.dart';

class PostingErrorModal extends StatelessWidget {
  final String title;
  final String message;
  final dynamic error;

  const PostingErrorModal({
    super.key,
    required this.title,
    required this.message,
    this.error,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    dynamic error,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          PostingErrorModal(title: title, message: message, error: error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16)),
            if (error != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  'Technical Details',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      error.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
