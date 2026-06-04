import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attachment_model.dart';
import '../services/attachment_service.dart';

class AttachmentSection extends StatefulWidget {
  final String companyId;
  final String folder;
  final List<AttachmentModel> initialAttachments;
  final Function(List<AttachmentModel>) onAttachmentsChanged;

  const AttachmentSection({
    super.key,
    required this.companyId,
    required this.folder,
    this.initialAttachments = const [],
    required this.onAttachmentsChanged,
  });

  @override
  State<AttachmentSection> createState() => _AttachmentSectionState();
}

class _AttachmentSectionState extends State<AttachmentSection> {
  final _attachmentService = AttachmentService();
  late List<AttachmentModel> _attachments;
  final Map<String, double> _uploadProgress = {};

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.initialAttachments);
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null) return;

    for (var file in result.files) {
      // 2) Check if file with same name already exists
      if (_attachments.any((a) => a.name == file.name)) {
        debugPrint('File ${file.name} already exists. Skipping.');
        continue;
      }

      setState(() {
        _uploadProgress[file.name] = 0.0;
      });

      try {
        final attachment = await _attachmentService.uploadFile(
          companyId: widget.companyId,
          folder: widget.folder,
          file: file,
          onProgress: (progress) {
            // 3) Show individual progress
            setState(() {
              _uploadProgress[file.name] = progress;
            });
          },
        );

        if (attachment != null) {
          setState(() {
            _attachments.add(attachment);
          });
          widget.onAttachmentsChanged(_attachments);
        }
      } finally {
        setState(() {
          _uploadProgress.remove(file.name);
        });
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    final attachment = _attachments[index];

    // 1) Delete from Firebase Storage
    await _attachmentService.deleteAttachment(attachment.url);

    setState(() {
      _attachments.removeAt(index);
    });
    widget.onAttachmentsChanged(_attachments);
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  'Click to upload or drag and drop files here',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '(Any file type supported)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
        if (_attachments.isNotEmpty || _uploadProgress.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final attachment = entry.value;
                // 5) Make chips tappable
                return InputChip(
                  avatar: _getIconForType(attachment.type),
                  label: Text(attachment.name),
                  onPressed: () => _openFile(attachment.url),
                  onDeleted: () => _removeAttachment(index),
                  deleteIconColor: Colors.red,
                );
              }),
              ..._uploadProgress.entries.map((entry) {
                return Chip(
                  avatar: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      value: entry.value,
                      strokeWidth: 2,
                    ),
                  ),
                  label: Text(entry.key),
                );
              }),
            ],
          ),
        ],
      ],
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
