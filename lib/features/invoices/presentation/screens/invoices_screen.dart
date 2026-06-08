import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/add_invoice_screen.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoicesScreen extends StatefulWidget {
  final AppUser user;
  const InvoicesScreen({super.key, required this.user});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _invoiceService = InvoiceService();
  final _companyService = CompanyService();
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
          child: StreamBuilder<List<InvoiceModel>>(
            stream: _invoiceService.getInvoices(widget.user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final invoices = snapshot.data ?? [];

              if (invoices.isEmpty) {
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
                        columnSpacing: 40,
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                        columns: [
                          _buildColumn('Invoice #'),
                          _buildColumn('Customer'),
                          _buildColumn('Date'),
                          _buildColumn('Total', numeric: true),
                          _buildColumn('Status'),
                          _buildColumn('Actions'),
                        ],
                        rows: invoices.map((invoice) {
                          final canEdit = canManage && !invoice.isPosted;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  invoice.invoiceNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  invoice.customerName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.date(invoice.invoiceDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.currency(
                                    invoice.totalAmount,
                                    symbol: _company?.baseCurrency,
                                  ),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(invoice)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                InvoiceDetailScreen(
                                                  invoice: invoice,
                                                  user: widget.user,
                                                ),
                                          ),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (canEdit)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        tooltip: 'Edit',
                                        onPressed: _showEditUnavailable,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if (canManage && !invoice.isPosted)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _confirmDelete(invoice),
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
                  'Sales Invoices',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage and track your customer billings',
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
                showErpSidePane(
                  context: context,
                  builder: AddInvoiceScreen(user: widget.user, isPane: true),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Invoice'),
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

  Widget _buildStatusBadge(InvoiceModel invoice) {
    final color = invoice.isPosted
        ? Colors.green
        : _getStatusColor(invoice.status);
    final text = invoice.isPosted
        ? 'POSTED'
        : invoice.status.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
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
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No invoices found',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _invoiceService.deleteInvoice(widget.user.companyId!, invoice.id);
        if (mounted) {
          showErpSuccess(
            context: context,
            title: 'Deleted',
            message: 'Invoice deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          showErpError(
            context: context,
            error: e,
          );
        }
      }
    }
  }

  void _showEditUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit screen for saved invoices is not wired yet.'),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pendingApproval:
        return Colors.orangeAccent;
      case InvoiceStatus.approved:
        return Colors.lightGreen;
      case InvoiceStatus.posted:
        return Colors.green;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.partiallyPaid:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.rejected:
        return Colors.redAccent;
      case InvoiceStatus.voided:
        return Colors.blueGrey;
      case InvoiceStatus.reversed:
        return Colors.deepPurpleAccent;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }
}
