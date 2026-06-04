import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attachment_model.dart';

class AttachmentViewer extends StatelessWidget {
  final List<AttachmentModel> attachments;

  const AttachmentViewer({super.key, required this.attachments});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Text('No attachments');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((attachment) {
        return ActionChip(
          avatar: _getIconForType(attachment.type),
          label: Text(attachment.name),
          onPressed: () => _openUrl(attachment.url),
        );
      }).toList(),
    );
  }

  Widget _getIconForType(String type) {
    IconData iconData;
    Color color;

    switch (type.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image;
        color = Colors.blue;
        break;
      case 'xlsx':
      case 'xls':
      case 'csv':
        iconData = Icons.table_chart;
        color = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(iconData, size: 18, color: color);
  }
}

void showAttachmentDialog(BuildContext context, List<AttachmentModel> attachments) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Attachments'),
      content: SizedBox(
        width: 400,
        child: AttachmentViewer(attachments: attachments),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
