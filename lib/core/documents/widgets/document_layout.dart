import 'package:flutter/material.dart';
import 'package:ledgixerp/core/documents/document_header.dart';
import 'package:ledgixerp/core/documents/document_status.dart';
import 'package:ledgixerp/core/documents/widgets/document_totals.dart';
import 'package:ledgixerp/core/documents/widgets/document_notes.dart';

class DocumentLayout extends StatelessWidget {
  final DocumentHeader header;
  final Widget linesWidget;
  final List<Widget>? extraActions;

  const DocumentLayout({
    super.key,
    required this.header,
    required this.linesWidget,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${header.type.label}: ${header.documentNumber}'),
        actions: extraActions,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(context),
            const SizedBox(height: 32),
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            linesWidget,
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: DocumentNotes(notes: header.notes),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 1,
                  child: DocumentTotals(
                    subtotal: header.subtotal,
                    taxTotal: header.taxTotal,
                    discountTotal: header.discountTotal,
                    totalAmount: header.totalAmount,
                    currency: header.currency,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoItem('Bill To / Customer', header.entityName),
            const SizedBox(height: 16),
            _infoItem('Document Date', _formatDate(header.documentDate)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusBadge(header.status),
            const SizedBox(height: 16),
            _infoItem('Currency', header.currency, crossAxisAlignment: CrossAxisAlignment.end),
          ],
        ),
      ],
    );
  }

  Widget _infoItem(String label, String value, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statusBadge(DocumentStatus status) {
    Color color = Colors.grey;
    switch (status) {
      case DocumentStatus.draft: color = Colors.grey; break;
      case DocumentStatus.pendingApproval: color = Colors.orange; break;
      case DocumentStatus.approved: color = Colors.green; break;
      case DocumentStatus.posted: color = Colors.blue; break;
      case DocumentStatus.cancelled: color = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
