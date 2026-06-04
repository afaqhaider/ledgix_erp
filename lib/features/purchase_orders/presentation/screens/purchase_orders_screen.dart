import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';
import 'package:ledgixerp/features/purchase_orders/services/purchase_order_service.dart';
import 'package:ledgixerp/features/purchase_orders/services/po_pdf_service.dart';
import 'package:ledgixerp/features/purchase_orders/presentation/screens/add_purchase_order_screen.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

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
      final request = ApprovalRequestModel(
        id: '',
        companyId: widget.user.companyId!,
        sourceType: 'purchaseOrder',
        sourceId: po.id,
        sourceNumber: po.poNumber,
        requestedByUserId: widget.user.uid,
        requestedByUserName: widget.user.fullName,
        requestedAt: DateTime.now(),
      );

      await _approvalService.submitForApproval(
        request,
        requesterRole: widget.user.role,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing approval/submission...')),
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
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageSuppliers,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showErpSidePane(
                    context: context,
                    builder: AddPurchaseOrderScreen(
                      user: widget.user,
                      isPane: true,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New PO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<PurchaseOrderModel>>(
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                horizontalMargin: 24,
                columnSpacing: 32,
                columns: const [
                  DataColumn(
                    label: Text(
                      'PO #',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Supplier',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Approval',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: pos.map((po) {
                  return DataRow(
                    cells: [
                      DataCell(Text(po.poNumber)),
                      DataCell(Text(po.supplierName)),
                      DataCell(
                        Text(AppFormatters.date(po.poDate)),
                      ),
                      DataCell(
                        Text(AppFormatters.currency(po.totalAmount, symbol: _company?.baseCurrency)),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              po.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            po.status.name.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(po.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        po.approvalStatus == null
                            ? TextButton(
                                onPressed: () => _submitForApproval(po),
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 12),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getApprovalStatusColor(
                                    po.approvalStatus!,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  po.approvalStatus!.toUpperCase(),
                                  style: TextStyle(
                                    color: _getApprovalStatusColor(
                                      po.approvalStatus!,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 20),
                              tooltip: 'Print/Download PDF',
                              onPressed: () => _printPO(po),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
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
