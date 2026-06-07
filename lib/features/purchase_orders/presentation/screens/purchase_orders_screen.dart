import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';
import 'package:ledgixerp/features/purchase_orders/services/purchase_order_service.dart';
import 'package:ledgixerp/features/purchase_orders/services/po_pdf_service.dart';
import 'package:ledgixerp/features/purchase_orders/presentation/screens/add_purchase_order_screen.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

import 'package:google_fonts/google_fonts.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  final AppUser user;
  const PurchaseOrdersScreen({super.key, required this.user});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  final _poService = PurchaseOrderService();
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

  Future<void> _submitForApproval(PurchaseOrderModel po) async {
    try {
      await _approvalService.submitForApproval(
        user: widget.user,
        companyId: widget.user.companyId!,
        sourceType: 'purchase_order',
        sourceId: po.id,
        sourceNumber: po.poNumber,
        amount: po.totalAmount,
      );

      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Success',
          message: 'Purchase Order submitted for approval successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageSuppliers,
    );

    return Column(
      children: [
        _buildHeader(theme, canManage),
        Expanded(
          child: StreamBuilder<List<PurchaseOrderModel>>(
            stream: _poService.getPurchaseOrders(widget.user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final pos = snapshot.data ?? [];

              if (pos.isEmpty) {
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
                          _buildColumn('PO #'),
                          _buildColumn('Supplier'),
                          _buildColumn('Date'),
                          _buildColumn('Total', numeric: true),
                          _buildColumn('Status'),
                          _buildColumn('Approval'),
                          _buildColumn('Actions'),
                        ],
                        rows: pos.map((po) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  po.poNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  po.supplierName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.date(po.poDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.currency(
                                    po.totalAmount,
                                    symbol: _company?.baseCurrency,
                                  ),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(po.status)),
                              DataCell(_buildApprovalBadge(po)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.print_outlined,
                                        size: 18,
                                      ),
                                      tooltip: 'Print/Download PDF',
                                      onPressed: () => _printPO(po),
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
                  'Purchase Orders',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage and track your procurement orders',
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
                  builder: AddPurchaseOrderScreen(
                    user: widget.user,
                    isPane: true,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New PO'),
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

  Widget _buildStatusBadge(POStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildApprovalBadge(PurchaseOrderModel po) {
    if (po.approvalStatus == null) {
      return TextButton(
        onPressed: () => _submitForApproval(po),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Submit', style: TextStyle(fontSize: 12)),
      );
    }

    final color = _getApprovalStatusColor(po.approvalStatus!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        po.approvalStatus!.toUpperCase(),
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
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No purchase orders found',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getApprovalStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(POStatus status) {
    switch (status) {
      case POStatus.draft:
        return Colors.grey;
      case POStatus.sent:
        return Colors.blue;
      case POStatus.partiallyReceived:
        return Colors.orange;
      case POStatus.received:
        return Colors.green;
      case POStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _printPO(PurchaseOrderModel po) async {
    try {
      final company = await _companyService
          .getCompany(widget.user.companyId!)
          .first;
      if (company == null) throw 'Company not found';

      final pdfBytes = await POPdfService.generatePO(po, company);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'PO_${po.poNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
