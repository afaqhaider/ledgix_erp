import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/quotations/services/quotation_service.dart';
import 'package:ledgixerp/features/quotations/services/quotation_pdf_service.dart';
import 'package:ledgixerp/features/quotations/presentation/screens/add_quotation_screen.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:google_fonts/google_fonts.dart';

class QuotationsScreen extends StatefulWidget {
  final AppUser user;
  const QuotationsScreen({super.key, required this.user});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final _quotationService = QuotationService();
  final _companyService = CompanyService();
  final _approvalService = ApprovalService();
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.user.companyId!).listen((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageInvoices,
    );

    return Column(
      children: [
        _buildHeader(theme, canManage),
        Expanded(
          child: StreamBuilder<List<QuotationModel>>(
            stream: _quotationService.getQuotations(widget.user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final quotations = snapshot.data ?? [];

              if (quotations.isEmpty) {
                return _buildEmptyState(theme);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 52,
                        horizontalMargin: 24,
                        columnSpacing: 32,
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                        columns: [
                          _buildColumn('Quotation #'),
                          _buildColumn('Customer'),
                          _buildColumn('Date'),
                          _buildColumn('Total', numeric: true),
                          _buildColumn('Status'),
                          _buildColumn('Approval'),
                          _buildColumn('Actions'),
                        ],
                        rows: quotations.map((quo) {
                          final isConverted = quo.status == QuotationStatus.converted;
                          final isApproved = quo.approvalStatus == 'approved';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  quo.quotationNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  quo.customerName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.date(quo.quotationDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.currency(
                                    quo.totalAmount,
                                    symbol: _company?.baseCurrency,
                                  ),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(quo)),
                              DataCell(_buildApprovalBadge(quo)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.print_outlined, size: 18),
                                      tooltip: 'Print/Download PDF',
                                      onPressed: () => _printQuotation(quo),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (canManage &&
                                        !isConverted &&
                                        (isApproved ||
                                            widget.user.role.name == 'Admin' ||
                                            widget.user.role.name == 'Owner'))
                                      IconButton(
                                        icon: const Icon(Icons.receipt_long, size: 18),
                                        tooltip: 'Convert to Invoice',
                                        color: theme.colorScheme.primary,
                                        onPressed: () => _convertToInvoice(quo),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool canManage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Quotations',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Generate and manage professional quotes for clients',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (canManage)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddQuotationScreen(user: widget.user),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Quotation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataColumn _buildColumn(String label, {bool numeric = false}) {
    return DataColumn(
      numeric: numeric,
      label: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(QuotationModel quo) {
    final color = _getStatusColor(quo.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        quo.status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildApprovalBadge(QuotationModel quo) {
    if (quo.approvalStatus == null) {
      return TextButton(
        onPressed: () => _submitForApproval(quo),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Submit', style: TextStyle(fontSize: 12)),
      );
    }

    final color = _getApprovalStatusColor(quo.approvalStatus!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        quo.approvalStatus!.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.request_quote_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No quotations found',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft: return Colors.grey;
      case QuotationStatus.sent: return Colors.blue;
      case QuotationStatus.accepted: return Colors.green;
      case QuotationStatus.rejected: return Colors.red;
      case QuotationStatus.expired: return Colors.orange;
      case QuotationStatus.converted: return Colors.purple;
    }
  }

  Color _getApprovalStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _submitForApproval(QuotationModel quo) async {
    try {
      await _approvalService.submitForApproval(
        user: widget.user,
        companyId: widget.user.companyId!,
        sourceType: 'quotation',
        sourceId: quo.id,
        sourceNumber: quo.quotationNumber,
        amount: quo.totalAmount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing approval/submission...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printQuotation(QuotationModel quo) async {
    try {
      final company = await _companyService.getCompany(widget.user.companyId!).first;
      if (company == null) throw 'Company not found';
      final pdfBytes = await QuotationPdfService.generateQuotation(quo, company);
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: 'Quotation_${quo.quotationNumber}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _convertToInvoice(QuotationModel quo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: Text('Do you want to convert Quotation ${quo.quotationNumber} to a Sales Invoice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Convert')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _quotationService.convertToInvoice(quo, widget.user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation converted to Invoice successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error converting to invoice: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }
}
