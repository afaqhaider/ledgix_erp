import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class JournalEntryDetailScreen extends StatefulWidget {
  final JournalEntryModel entry;
  final AppUser user;

  const JournalEntryDetailScreen({
    super.key,
    required this.entry,
    required this.user,
  });

  @override
  State<JournalEntryDetailScreen> createState() => _JournalEntryDetailScreenState();
}

class _JournalEntryDetailScreenState extends State<JournalEntryDetailScreen> {
  final _companyService = CompanyService();
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.user.companyId!).first.then((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final totalDebit = entry.lines.fold(0.0, (sum, line) => sum + line.debit);
    final totalCredit = entry.lines.fold(0.0, (sum, line) => sum + line.credit);

    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entry ${entry.reference}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              // Future print functionality
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: const EdgeInsets.all(20),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_company?.companyLogoUrl != null)
                            Image.network(_company!.companyLogoUrl!, height: 50)
                          else
                            Icon(Icons.account_balance,
                                size: 50, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            _company?.companyLegalName ?? 'Company Name',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Journal Entry Voucher',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ERPStatusBadge.fromStatus(entry.status.name),
                          const SizedBox(height: 12),
                          _buildInfoField('Reference', entry.reference),
                          _buildInfoField('Date', AppFormatters.date(entry.date)),
                          if (entry.jobNumber != null)
                            _buildInfoField('Job', '${entry.jobNumber} - ${entry.jobName}'),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 48),
                  
                  Text(
                    'Description',
                    style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // Table of lines
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: Border(bottom: BorderSide(color: theme.dividerColor, width: 2)),
                        ),
                        children: [
                          _buildHeaderCell('Account / Memo'),
                          _buildHeaderCell('Debit', textAlign: TextAlign.right),
                          _buildHeaderCell('Credit', textAlign: TextAlign.right),
                        ],
                      ),
                      ...entry.lines.map((line) => TableRow(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: theme.dividerColor)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${line.accountCode} - ${line.accountName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (line.memo != null && line.memo!.isNotEmpty)
                                  Text(
                                    line.memo!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (line.jobNumber != null)
                                  Text(
                                    'Job: ${line.jobNumber}',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              line.debit > 0 ? AppFormatters.currency(line.debit) : '',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              line.credit > 0 ? AppFormatters.currency(line.credit) : '',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      )),
                      // Totals row
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'TOTAL',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              AppFormatters.currency(totalDebit),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              AppFormatters.currency(totalCredit),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 64),
                  
                  // Footer / Signatures
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSignatureLine('Prepared By'),
                      _buildSignatureLine('Verified By'),
                      _buildSignatureLine('Approved By'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign textAlign = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text.toUpperCase(),
        textAlign: textAlign,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSignatureLine(String label) {
    return Column(
      children: [
        Container(
          width: 150,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
